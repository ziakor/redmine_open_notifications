module RedmineOpenNotifications
  class Hooks < Redmine::Hook::ViewListener
    def view_layouts_base_html_head(context={})
      return '' unless User.current.logged?

      strings = {
        title: l(:label_notifications),
        markAllRead: l(:label_mark_all_read_short),
        viewAll: l(:label_view_all_notifications),
        loading: l(:text_notifications_loading),
        empty: l(:text_no_notifications),
        emptyUnread: l(:text_no_unread_notifications)
      }
      webpush_enabled = UserNotificationPreference.find_by(user_id: User.current.id)&.webpush_enabled? || false

      tags = []
      tags << stylesheet_link_tag('notifications', plugin: 'redmine_open_notifications')
      tags << javascript_tag("window.RedmineOpenNotifications = window.RedmineOpenNotifications || {}; window.RedmineOpenNotifications.i18n = #{strings.to_json}; window.RedmineOpenNotifications.webpushEnabled = #{webpush_enabled.to_json};")
      tags << javascript_include_tag('notifications', plugin: 'redmine_open_notifications')
      tags.join("\n").html_safe
    end

    def view_my_account(context={})
      context[:controller].send(:render_to_string, {
        partial: 'notification_preferences/my_account_link',
        locals: context
      })
    end

    def controller_issues_new_after_save(context={})
      issue = context[:issue]
      NotificationDispatcherJob.perform_now('issue_created', issue.id, nil, User.current.id) if issue
    end

    def controller_issues_edit_after_save(context={})
      issue = context[:issue]
      journal = context[:journal]
      NotificationDispatcherJob.perform_now('issue_updated', issue.id, journal&.id, User.current.id) if issue
    end
  end
end
