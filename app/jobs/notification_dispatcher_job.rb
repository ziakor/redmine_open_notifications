class NotificationDispatcherJob < ApplicationJob
  queue_as :default

  def perform(event_type, issue_id, journal_id, author_id)
    issue = Issue.find_by(id: issue_id)
    return unless issue

    author = User.find_by(id: author_id)
    journal = Journal.find_by(id: journal_id)
    text_content = journal ? journal.notes.to_s : issue.description.to_s

    # 1. ALWAYS Deliver Outbound Webhooks for issue events
    begin
      WebhookDeliveryService.new(issue, journal, event_type, author).deliver_all
    rescue => e
      Rails.logger.error("Webhook Delivery Exception: #{e.message}")
    end

    # 2. Extract @mentions
    mentioned_logins = MentionParser.extract_logins(text_content)
    mentioned_users = User.where(login: mentioned_logins)
    mentioned_users = mentioned_users.where.not(id: author_id) if author_id

    # 3. Collect Recipients (Watchers + Assignee + Project Members for new issues + Mentioned)
    watchers = issue.watcher_users
    assignee = issue.assigned_to.is_a?(User) ? issue.assigned_to : nil
    issue_author = issue.author

    # If new issue, notify project members
    project_members = (event_type == 'issue_created') ? issue.project.users.to_a : []

    all_recipients = (watchers.to_a + [assignee, issue_author] + project_members + mentioned_users.to_a).compact.uniq
    
    settings = Setting.plugin_redmine_open_notifications rescue {}
    if settings['suppress_self_notifications'] == '1' && author
      all_recipients.delete(author)
    end

    # 4. Create UserNotifications & Broadcast to ActionCable
    all_recipients.each do |user|
      pref = UserNotificationPreference.find_by(user_id: user.id)
      type = mentioned_users.include?(user) ? 'user_mentioned' : event_type

      # Skip if user disabled this event type in their personal preferences
      next if pref && !pref.event_enabled?(type)

      # Skip if in quiet hours (save for digest)
      next if pref&.quiet_hours? && pref&.digest_enabled

      title = if type == 'user_mentioned'
                "#{author&.name || 'Un utilisateur'} vous a mentionné sur le ticket ##{issue.id}"
              elsif type == 'issue_created'
                "#{author&.name || 'Un utilisateur'} a créé le ticket ##{issue.id} dans #{issue.project.name}"
              else
                "Ticket ##{issue.id} mis à jour dans #{issue.project.name}"
              end

      notification = UserNotification.create!(
        user: user,
        author: author || user,
        project: issue.project,
        issue: issue,
        journal: journal,
        event_type: type,
        title: title,
        body: text_content.truncate(150)
      )

      # Broadcast real-time to user ActionCable channel safely
      begin
        if defined?(ActionCable) && ActionCable.server.respond_to?(:pubsub) && ActionCable.server.pubsub
          ActionCable.server.broadcast("user_#{user.id}_notifications", {
            unread_count: user.user_notifications.unread.active.count,
            notification: {
              id: notification.id,
              title: notification.title,
              body: notification.body,
              issue_id: issue.id,
              created_at: notification.created_at
            }
          })
        end
      rescue => e
        Rails.logger.debug("ActionCable broadcast skipped: #{e.message}")
      end
    end
  end
end
