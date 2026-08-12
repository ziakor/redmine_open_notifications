class UserNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :author, class_name: 'User'
  belongs_to :project, optional: true
  belongs_to :issue, optional: true
  belongs_to :journal, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :active, -> { where('snoozed_until IS NULL OR snoozed_until <= ?', Time.current) }
  scope :mentions, -> { where(event_type: 'user_mentioned') }
end
