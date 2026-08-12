# frozen_string_literal: true

require_relative '../test_helper'

class UserNotificationsControllerTest < Redmine::ControllerTest
  setup do
    @user = User.create!(login: 'testuser', firstname: 'Test', lastname: 'User', mail: 'testuser@example.com')
    @author = User.create!(login: 'authoruser', firstname: 'Author', lastname: 'User', mail: 'authoruser@example.com')
    @project = Project.create!(name: 'Test Project', identifier: 'test-project-controller')
    @tracker = Tracker.first || Tracker.create!(name: 'Bug')
    @status = IssueStatus.first || IssueStatus.create!(name: 'New')
    @issue = Issue.create!(project: @project, tracker: @tracker, status: @status, subject: 'Controller Test Issue', author: @author)
    
    @notification = UserNotification.create!(
      user: @user,
      author: @author,
      project: @project,
      issue: @issue,
      event_type: 'issue_created',
      title: 'New issue created'
    )
  end

  test "index renders html and json for logged in user" do
    @request.session[:user_id] = @user.id
    
    get :index
    assert_response :success

    get :index, params: { format: 'json' }
    assert_response :success
    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert_equal 1, json.length
    assert_equal 'New issue created', json.first['title']
  end

  test "read_all marks unread notifications as read" do
    @request.session[:user_id] = @user.id

    post :read_all
    assert_response :success
    assert_not_nil @notification.reload.read_at
  end

  test "snooze updates snoozed_until timestamp" do
    @request.session[:user_id] = @user.id

    post :snooze, params: { id: @notification.id, hours: 4 }
    assert_response :success
    assert_not_nil @notification.reload.snoozed_until
  end
end
