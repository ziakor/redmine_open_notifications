class UserNotification < ActiveRecord::Base
  belongs_to :user
  belongs_to :author, class_name: 'User'
  belongs_to :project, optional: true
  belongs_to :issue, optional: true
  belongs_to :journal, optional: true

  scope :unread, -> { where(read_at: nil) }
  scope :active, -> { where('snoozed_until IS NULL OR snoozed_until <= ?', Time.current) }
  scope :mentions, -> { where(event_type: 'user_mentioned') }

  def note_indice
    return nil unless issue_id && journal_id

    position = Journal.where(journalized_id: issue_id, journalized_type: 'Issue')
                      .reorder(:created_on, :id)
                      .pluck(:id)
                      .index(journal_id)
    position && position + 1
  end

  # Where clicking this notification should take the user.
  def target_url
    return nil unless issue_id

    indice = note_indice
    indice ? "/issues/#{issue_id}#note-#{indice}" : "/issues/#{issue_id}"
  end
end
