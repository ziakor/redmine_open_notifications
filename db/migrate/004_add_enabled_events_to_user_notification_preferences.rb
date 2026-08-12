class AddEnabledEventsToUserNotificationPreferences < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:user_notification_preferences, :enabled_events)
      add_column :user_notification_preferences, :enabled_events, :string, default: "user_mentioned,issue_created,issue_updated,note_added"
    end
  end
end
