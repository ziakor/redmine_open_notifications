class CreateUserNotificationPreferences < ActiveRecord::Migration[6.1]
  def change
    create_table :user_notification_preferences do |t|
      t.integer :user_id, null: false
      t.boolean :webpush_enabled, default: false
      t.text :webpush_subscription
      t.string :telegram_chat_id
      t.string :ntfy_topic
      t.string :pushover_user_key
      t.boolean :enable_sound, default: true
      t.string :quiet_hours_start, default: "18:00"
      t.string :quiet_hours_end, default: "08:30"
      t.string :work_days, default: "1,2,3,4,5"
      t.boolean :digest_enabled, default: false
      t.string :digest_frequency, default: "daily"
      t.timestamps
    end
    add_index :user_notification_preferences, :user_id, unique: true
  end
end
