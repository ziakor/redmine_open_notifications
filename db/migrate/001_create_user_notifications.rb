class CreateUserNotifications < ActiveRecord::Migration[6.1]
  def change
    create_table :user_notifications do |t|
      t.integer :user_id, null: false
      t.integer :author_id, null: false
      t.integer :project_id, null: false
      t.integer :issue_id, null: false
      t.integer :journal_id
      t.string :event_type, null: false
      t.string :title, null: false
      t.text :body
      t.datetime :read_at
      t.datetime :snoozed_until
      t.timestamps
    end
    add_index :user_notifications, [:user_id, :read_at]
    add_index :user_notifications, [:user_id, :snoozed_until]
  end
end
