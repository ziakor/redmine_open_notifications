class NotificationDigestJob < ApplicationJob
  queue_as :low_priority

  def perform
    UserNotificationPreference.where(digest_enabled: true).find_each do |pref|
      user = pref.user
      next unless user

      unread_notifications = user.user_notifications.unread.where('created_at >= ?', 24.hours.ago).includes(:issue, :journal, :author)
      next if unread_notifications.empty?

      # Group notifications by issue for clean readability with direct links to exact comment anchors (#note-X)
      grouped_by_issue = unread_notifications.group_by(&:issue)
      summary_items = []

      grouped_by_issue.each do |issue, notifs|
        next unless issue
        summary_items << "<strong>Ticket ##{issue.id} : #{issue.subject} (#{issue.project.name})</strong>"
        notifs.each do |n|
          anchor_url = n.journal_id ? "/issues/#{issue.id}#note-#{n.journal_id}" : "/issues/#{issue.id}"
          author_name = n.author&.name || 'Utilisateur'
          summary_items << "  • <a href='#{anchor_url}' style='color: #0366d6; text-decoration: underline;'>Commentaire de #{author_name}</a> : <em>\"#{n.body.to_s.truncate(80)}\"</em>"
        end
      end

      first_notif = unread_notifications.first
      UserNotification.create!(
        user: user,
        author: user,
        project_id: first_notif.project_id,
        issue_id: first_notif.issue_id,
        event_type: 'digest_summary',
        title: "📰 Résumé quotidien : #{unread_notifications.count} alerte(s) en attente",
        body: summary_items.join("<br>")
      )

      Rails.logger.info("Daily digest created for User ##{user.id} with #{unread_notifications.count} notifications.")
    end
  end
end
