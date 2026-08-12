class CreateNotificationRules < ActiveRecord::Migration[6.1]
  def change
    create_table :notification_rules do |t|
      t.integer :project_id
      t.string :name, null: false
      t.text :events
      t.text :conditions
      t.string :channel_type
      t.string :webhook_url
      t.string :channel_identifier
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :notification_rules, :project_id
  end
end
