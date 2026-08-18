# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2026-08-18

### Changed
- **Desktop notifications now request permission and respect the user's preference**: the bell dropdown polling used to fire `new Notification()` whenever the browser already had permission granted some other way, ignoring the `webpush_enabled` preference entirely. The preference is now passed to the client, permission is requested explicitly when the preference is on, and the toast is gated on that preference.
- **Renamed "WebPush" to "browser notifications" everywhere user-facing** (README, settings, preferences, en/fr locales): the feature is a foreground toast triggered by polling while a Redmine tab is open, not W3C Push API delivery to a closed browser. The previous naming implied background push that never existed.

### Removed
- `app/services/web_push_service.rb` and `assets/javascripts/service_worker.js`: dead code that was never invoked and implied a real push backend was in place.
- `webpush_subscription` from the notification preference's permitted params (never populated).

## [1.2.0] - 2026-08-15

### Added
- i18n: all user-facing strings moved from hardcoded French to `config/locales/en.yml` and `fr.yml` (80 keys, en/fr in parity). The dropdown is rendered client-side, so the layout hook passes its strings to JS. Quiet-hours day names come from Rails `date.day_names`.
- README screenshots: dropdown, history, user preferences, admin settings.

### Fixed
- Clicking the unread badge closed the dropdown instead of opening it: the outside-click handler compared the target to the bell by identity rather than `contains`.
- Snooze notice always said "2 hours", ignoring the `hours` param.

## [1.1.0] - 2026-08-15

### Added
- **Clickable dropdown notifications**: clicking an entry in the bell dropdown now marks it as read and opens the related issue, scrolled to the exact comment when the notification carries one. Dropdown entries previously rendered as inert list items with no link and no click handler, while the desktop toast and the full notification page both navigated. The dropdown was the only dead end.
- **Redmine 6.x support**: verified against Redmine 6.0.6 (Rails 7.2.2.1, Ruby 3.3): plugin boot, the four migrations, model patching, notification bell rendering and the admin settings page. Redmine 5.x (Rails 6.1) remains supported.
- **CI**: Ruby 3.3 added to the test matrix.

### Fixed
- **Digest links now point at anchors that exist**: the daily digest built comment anchors from `journal_id`, but Redmine anchors notes on their 1-based position within the issue (`Issue#visible_journals_with_index`). Digest links landed on the issue without ever scrolling to the comment. Anchor building now lives in `UserNotification#target_url` and is shared by the digest and the dropdown.
- **`NotificationRule` no longer breaks application boot on Rails 7.2**: `serialize :events, Array` used the positional argument form, which Rails 7.1 replaced with the `type:` keyword and Rails 7.2 removed outright, raising `ArgumentError: wrong number of arguments` before Puma could start. Both forms are now selected at load time based on the Active Record version.

## [1.0.0] - 2026-08-12

### Added
- **Real-Time Notification Bell**: Top-right account menu integration (`🔔`) with unread badge count and floating dropdown popup.
- **W3C WebPush API**: Browser desktop push notification toasts with permission request modal and test triggers.
- **Smart `@user` Mention Parser**: Extracts login mentions from issue descriptions and journal comments.
- **Personal Quiet Hours (Do Not Disturb)**: Custom start/end times with Monday to Friday work day selector.
- **Granular Event Filtering**: Per-user event preference toggles (Mentions, New Issues, Updates, Notes).
- **Structured Daily Digest**: Automated summary notification grouping events by issue with direct links to exact comment anchors (`#note-X`).
- **Linear-Style Admin Settings**: Modern control panel with dynamic Outbound Multi-Webhook URL management (`+ Add Webhook`, `✕` remove button).
- **Unit & Integration Test Suite**: 100% clean test coverage for mention parser, quiet hours logic, webhook delivery, and controllers.
