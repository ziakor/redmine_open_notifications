# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-12

### Added
- **Real-Time Notification Bell**: Top-right account menu integration (`🔔`) with unread badge count and floating dropdown popup.
- **W3C WebPush API**: Browser desktop push notification toasts with permission request modal and test triggers.
- **Smart `@user` Mention Parser**: Extracts login mentions from issue descriptions and journal comments.
- **Personal Quiet Hours (Do Not Disturb)**: Custom start/end times with Monday–Friday work day selector.
- **Granular Event Filtering**: Per-user event preference toggles (Mentions, New Issues, Updates, Notes).
- **Structured Daily Digest**: Automated summary notification grouping events by issue with direct links to exact comment anchors (`#note-X`).
- **Linear-Style Admin Settings**: Modern control panel with dynamic Outbound Multi-Webhook URL management (`+ Add Webhook`, `✕` remove button).
- **Unit & Integration Test Suite**: 100% clean test coverage for mention parser, quiet hours logic, webhook delivery, and controllers.
