# frozen_string_literal: true

class AddNotificationScopeToUserNotificationPreferences < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:user_notification_preferences, :notification_scope)
      add_column :user_notification_preferences, :notification_scope, :string, default: 'redmine_default'
    end
  end
end
