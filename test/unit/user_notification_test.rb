# frozen_string_literal: true

require_relative '../test_helper'

class UserNotificationTest < ActiveSupport::TestCase
  test "unread scope filters read notifications" do
    n1 = UserNotification.create!(user_id: 1, author_id: 2, project_id: 1, issue_id: 1, event_type: 'issue_created', title: 'Test 1')
    n2 = UserNotification.create!(user_id: 1, author_id: 2, project_id: 1, issue_id: 1, event_type: 'issue_updated', title: 'Test 2', read_at: Time.current)

    assert_includes UserNotification.unread, n1
    refute_includes UserNotification.unread, n2
  end
end
