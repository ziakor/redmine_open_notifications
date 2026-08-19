# frozen_string_literal: true

require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
require 'active_support/core_ext/object/blank'

class ApplicationJob
  def self.queue_as(*); end
end unless defined?(ApplicationJob)
require_relative '../../app/jobs/notification_dispatcher_job'

class NotificationDispatcherJobTest < ActiveSupport::TestCase
  UserMock = Struct.new(:id, :login, :active_status, :pref) do
    def active?
      active_status != false
    end
  end

  ProjectMock = Struct.new(:id, :name, :users)

  IssueMock = Struct.new(:id, :project, :author, :assigned_to, :watcher_users, :notified_users_list, :visible_users_list) do
    def notified_users
      notified_users_list || []
    end

    def visible?(user)
      visible_users_list.nil? || visible_users_list.include?(user)
    end
  end

  JournalMock = Struct.new(:id, :notes, :notified_users_list) do
    def notified_users
      notified_users_list || []
    end
  end

  setup do
    @job = NotificationDispatcherJob.new
    @user1 = UserMock.new(1, 'alice', true, {})
    @user2 = UserMock.new(2, 'bob', true, {})
    @user3 = UserMock.new(3, 'charlie', true, {})
    @project = ProjectMock.new(1, 'Test Project', [@user1, @user2, @user3])
  end

  test "collect_recipients in redmine_default mode honors Redmine core notified_users" do
    issue = IssueMock.new(10, @project, @user1, @user2, [@user1], [@user2], [@user1, @user2, @user3])
    # Redmine notified_users says only user2 (Bob) should be notified based on degree/watchers
    recipients = @job.send(:collect_recipients, issue, nil, 'issue_created', @user1, [])

    # Self-notification for user1 is suppressed by default, so only user2 is in recipients
    assert_equal [@user2], recipients
  end

  test "collect_recipients includes @mentions even when not in base notified_users" do
    issue = IssueMock.new(10, @project, @user1, @user2, [], [@user2], [@user1, @user2, @user3])
    mentioned_users = [@user3]

    recipients = @job.send(:collect_recipients, issue, nil, 'issue_updated', @user1, mentioned_users)

    assert_includes recipients, @user2
    assert_includes recipients, @user3
  end

  test "collect_recipients suppresses author when self-notification suppression is active" do
    issue = IssueMock.new(10, @project, @user1, @user1, [@user1], [@user1], [@user1])
    recipients = @job.send(:collect_recipients, issue, nil, 'issue_created', @user1, [])

    refute_includes recipients, @user1
  end

  test "collect_recipients filters out users who cannot view the issue" do
    hidden_issue = IssueMock.new(10, @project, @user1, @user2, [@user1, @user2], [@user1, @user2], [@user1]) # user2 cannot view
    recipients = @job.send(:collect_recipients, hidden_issue, nil, 'issue_created', nil, [])

    assert_includes recipients, @user1
    refute_includes recipients, @user2
  end
end
