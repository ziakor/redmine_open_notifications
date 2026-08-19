# frozen_string_literal: true

require 'logger'
require 'time'
require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
require 'active_support/core_ext/time'
require 'active_support/core_ext/object/blank'

class UserNotificationPreferenceMock
  attr_accessor :quiet_hours_start, :quiet_hours_end, :current_time_override

  def initialize(quiet_hours_start: nil, quiet_hours_end: nil, current_time_override: nil)
    @quiet_hours_start = quiet_hours_start
    @quiet_hours_end = quiet_hours_end
    @current_time_override = current_time_override
  end

  def quiet_hours?
    return false if quiet_hours_start.blank? || quiet_hours_end.blank?

    now_time = (current_time_override || Time.current).strftime("%H:%M")
    if quiet_hours_start < quiet_hours_end
      now_time >= quiet_hours_start && now_time <= quiet_hours_end
    else
      now_time >= quiet_hours_start || now_time <= quiet_hours_end
    end
  end
end

class UserNotificationPreferenceTest < ActiveSupport::TestCase
  test "quiet_hours? returns false when quiet hours are not set" do
    pref = UserNotificationPreferenceMock.new(quiet_hours_start: nil, quiet_hours_end: nil)
    refute pref.quiet_hours?
  end

  test "quiet_hours? detects daytime range" do
    pref = UserNotificationPreferenceMock.new(
      quiet_hours_start: "08:00",
      quiet_hours_end: "18:00",
      current_time_override: Time.parse("2026-08-11 12:00:00")
    )
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 20:00:00")
    refute pref.quiet_hours?
  end

  test "quiet_hours? detects overnight range across midnight" do
    pref = UserNotificationPreferenceMock.new(
      quiet_hours_start: "18:00",
      quiet_hours_end: "08:30",
      current_time_override: Time.parse("2026-08-11 22:00:00")
    )
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 04:00:00")
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 14:00:00")
    refute pref.quiet_hours?
  end

  test "allows_event_for_issue? with mentions_only scope allows mentions but blocks others" do
    pref = Struct.new(:user_id, :notification_scope) do
      include Module.new {
        def effective_notification_scope
          notification_scope.presence || 'redmine_default'
        end

        def allows_event_for_issue?(event_type, issue, is_mentioned = false)
          return true if is_mentioned
          return true unless issue

          case effective_notification_scope
          when 'mentions_only'
            false
          when 'only_involved'
            is_involved?(issue)
          when 'all_events'
            true
          else
            true
          end
        end

        def is_involved?(issue)
          return false unless user_id && issue
          return true if issue.respond_to?(:assigned_to_id) && issue.assigned_to_id == user_id
          return true if issue.respond_to?(:author_id) && issue.author_id == user_id
          if issue.respond_to?(:watcher_users)
            return true if issue.watcher_users.to_a.map(&:id).include?(user_id)
          end
          false
        end
      }
    end.new(10, 'mentions_only')

    issue = Struct.new(:id, :assigned_to_id, :author_id, :watcher_users).new(100, 10, 10, [])

    # Mentions are always permitted
    assert pref.allows_event_for_issue?('user_mentioned', issue, true)
    # Other events blocked for mentions_only
    refute pref.allows_event_for_issue?('issue_created', issue, false)
  end

  test "allows_event_for_issue? with only_involved scope allows involved users only" do
    klass = Struct.new(:user_id, :notification_scope) do
      include Module.new {
        def effective_notification_scope
          notification_scope.presence || 'redmine_default'
        end

        def allows_event_for_issue?(event_type, issue, is_mentioned = false)
          return true if is_mentioned
          return true unless issue

          case effective_notification_scope
          when 'mentions_only'
            false
          when 'only_involved'
            is_involved?(issue)
          when 'all_events'
            true
          else
            true
          end
        end

        def is_involved?(issue)
          return false unless user_id && issue
          return true if issue.respond_to?(:assigned_to_id) && issue.assigned_to_id == user_id
          return true if issue.respond_to?(:author_id) && issue.author_id == user_id
          if issue.respond_to?(:watcher_users)
            return true if issue.watcher_users.to_a.map(&:id).include?(user_id)
          end
          false
        end
      }
    end

    pref_involved = klass.new(10, 'only_involved')
    pref_uninvolved = klass.new(99, 'only_involved')

    mock_watcher = Struct.new(:id).new(50)
    issue = Struct.new(:id, :assigned_to_id, :author_id, :watcher_users).new(100, 10, 20, [mock_watcher])

    # User 10 is assignee
    assert pref_involved.allows_event_for_issue?('issue_updated', issue, false)
    # User 99 is not involved
    refute pref_uninvolved.allows_event_for_issue?('issue_updated', issue, false)
  end

  test "allows_event_for_issue? with redmine_default scope checks user.notify_about?" do
    user_mock = Struct.new(:id, :notifies) do
      def notify_about?(issue)
        notifies
      end
    end

    klass = Struct.new(:user, :notification_scope) do
      def user_id; user&.id; end
      def effective_notification_scope; notification_scope || 'redmine_default'; end
      def is_involved?(issue); false; end
      def allows_event_for_issue?(event_type, issue, is_mentioned = false)
        return true if is_mentioned
        return true unless issue
        scope = effective_notification_scope
        case scope
        when 'mentions_only' then false
        when 'only_involved' then is_involved?(issue)
        when 'all_events' then true
        else
          return true unless user
          return true if is_involved?(issue)
          user.respond_to?(:notify_about?) ? user.notify_about?(issue) : true
        end
      end
    end

    pref_allow = klass.new(user_mock.new(1, true), 'redmine_default')
    pref_block = klass.new(user_mock.new(2, false), 'redmine_default')

    issue = Struct.new(:id).new(100)

    assert pref_allow.allows_event_for_issue?('issue_created', issue, false)
    refute pref_block.allows_event_for_issue?('issue_created', issue, false)
  end
end
