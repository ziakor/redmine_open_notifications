class NotificationDispatcherJob < ApplicationJob
  queue_as :default

  def perform(event_type, issue_id, journal_id, author_id)
    issue = Issue.find_by(id: issue_id)
    return unless issue

    author = User.find_by(id: author_id)
    journal = Journal.find_by(id: journal_id)
    text_content = journal ? journal.notes.to_s : issue.description.to_s

    begin
      WebhookDeliveryService.new(issue, journal, event_type, author).deliver_all
    rescue => e
      Rails.logger.error("Webhook Delivery Exception: #{e.message}")
    end

    mentioned_logins = MentionParser.extract_logins(text_content)
    raw_mentioned_users = User.where(login: mentioned_logins)
    raw_mentioned_users = raw_mentioned_users.where.not(id: author_id) if author_id

    mentioned_users = raw_mentioned_users.to_a.select { |u| issue_visible_for_user?(issue, u) }
    all_recipients = collect_recipients(issue, journal, event_type, author, mentioned_users)

    all_recipients.each do |user|
      pref = UserNotificationPreference.find_by(user_id: user.id)
      is_mentioned = mentioned_users.include?(user)
      type = is_mentioned ? 'user_mentioned' : (journal && journal.notes.present? ? 'note_added' : event_type)

      next if pref && !pref.event_enabled?(type)
      next if pref && !pref.allows_event_for_issue?(type, issue, is_mentioned)
      next if pref&.quiet_hours? && pref&.digest_enabled

      title = if type == 'user_mentioned'
                "#{author&.name || 'Un utilisateur'} vous a mentionné sur le ticket ##{issue.id}"
              elsif type == 'issue_created'
                "#{author&.name || 'Un utilisateur'} a créé le ticket ##{issue.id} dans #{issue.project.name}"
              elsif type == 'note_added'
                "Nouveau commentaire sur le ticket ##{issue.id} dans #{issue.project.name}"
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

  private

  def collect_recipients(issue, journal, event_type, author, mentioned_users)
    settings = Setting.plugin_redmine_open_notifications rescue {}
    recipient_mode = settings['recipient_mode'].presence || 'redmine_default'
    always_notify_mentions = settings['always_notify_mentions'] != '0'
    suppress_self = settings['suppress_self_notifications'].nil? || settings['suppress_self_notifications'] == '1'

    recipients = []

    case recipient_mode
    when 'involved_only'
      watchers = issue.respond_to?(:watcher_users) ? issue.watcher_users.to_a : []
      assignee = issue.assigned_to.is_a?(User) ? issue.assigned_to : nil
      author_user = issue.author
      recipients = (watchers + [assignee, author_user]).compact.uniq
    when 'all_project_members'
      members = issue.project.respond_to?(:users) ? issue.project.users.to_a : []
      recipients = members.to_a
    else
      base_notified = if journal && journal.respond_to?(:notified_users)
                        journal.notified_users
                      elsif issue.respond_to?(:notified_users)
                        issue.notified_users
                      else
                        watchers = issue.respond_to?(:watcher_users) ? issue.watcher_users.to_a : []
                        (watchers + [issue.assigned_to, issue.author]).compact.uniq
                      end
      recipients = Array(base_notified).compact.uniq
    end

    if always_notify_mentions && mentioned_users.present?
      recipients = (recipients + mentioned_users).compact.uniq
    end

    recipients = recipients.select { |u| issue_visible_for_user?(issue, u) }

    if author
      no_self_pref = author.respond_to?(:pref) && author.pref.respond_to?(:[]) && (author.pref[:no_self_notified] == '1' || author.pref[:no_self_notified] == true)
      if suppress_self || no_self_pref
        recipients.delete(author)
      end
    end

    recipients
  end

  def issue_visible_for_user?(issue, user)
    return false unless user
    return false if user.respond_to?(:active?) && !user.active?
    return true if issue.nil?
    if issue.respond_to?(:visible?)
      issue.visible?(user)
    elsif user.respond_to?(:allowed_to?)
      user.allowed_to?(:view_issues, issue.project) rescue true
    else
      true
    end
  end
end
