# frozen_string_literal: true

require_relative 'lib/redmine_open_notifications/patches/user_patch'
require_relative 'lib/redmine_open_notifications/hooks'

Redmine::Plugin.register :redmine_open_notifications do
  name 'Redmine Open Notifications'
  author 'Dimitri Hauet'
  description 'Real-time WebSockets, WebPush, @mentions, and multi-channel chat notifications for Redmine.'
  version '1.2.0'
  url 'https://github.com/ziakor/redmine_open_notifications'
  requires_redmine version_or_higher: '5.0.0'

  settings default: {
    'webhook_urls' => [],
    'enabled_events' => ['issue_created', 'issue_updated', 'note_added', 'user_mentioned'],
    'suppress_self_notifications' => '1',
    'enable_webpush' => '1'
  }, partial: 'settings/redmine_open_notifications_settings'

  project_module :open_notifications do
    permission :view_user_notifications, { user_notifications: [:index] }, read: true
    permission :manage_notification_rules, { notification_rules: [:index, :edit, :update] }, require: :member
  end

  # Position the notification bell icon (🔔 only) in the account menu on the TOP RIGHT next to My Account
  menu :account_menu, :notifications, { controller: 'user_notifications', action: 'index' },
       caption: '🔔',
       html: { id: 'notifications-menu-icon' },
       before: :my_account,
       if: Proc.new { User.current.logged? }
end

unless User.included_modules.include?(RedmineOpenNotifications::Patches::UserPatch)
  User.include(RedmineOpenNotifications::Patches::UserPatch)
end
