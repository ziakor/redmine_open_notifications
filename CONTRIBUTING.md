# Contributing to Redmine Open Notifications

Thank you for considering contributing to `redmine_open_notifications`! We welcome bug reports, feature requests, documentation improvements, and code contributions.

## Pull Request Title Standard (Conventional Commits)

This repository strictly enforces [Conventional Commits](https://www.conventionalcommits.org/) on all Pull Requests via GitHub Actions (`pr-title.yml`). 

Every Pull Request title **MUST** start with a valid type prefix:

- `feat: ...` ➔ Triggers a **MINOR** version bump & release (`v1.1.0`)
- `fix: ...` ➔ Triggers a **PATCH** version bump & release (`v1.0.1`)
- `feat!: ...` or `BREAKING CHANGE:` ➔ Triggers a **MAJOR** version bump & release (`v2.0.0`)
- `docs: ...`, `chore: ...`, `refactor: ...`, `test: ...` ➔ Runs CI checks without triggering a new version tag.

> ⚠️ **Pull Requests with invalid titles (e.g. `update code` or `my fix`) will fail CI validation and cannot be merged.**

## Development Setup

1. **Clone the repository into your Redmine `plugins/` directory**:
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/ziakor/redmine_open_notifications.git redmine_open_notifications
   ```

2. **Run database migrations**:
   ```bash
   bundle exec rake redmine:plugins:migrate RAILS_ENV=development
   ```

3. **Start Redmine server**:
   ```bash
   bundle exec rails server
   ```

## Running Tests

Before submitting a pull request, ensure all tests pass:

```bash
ruby -Iapp/services -Iapp/models -Itest test/unit/mention_parser_test.rb
ruby -Iapp/models -Itest test/unit/user_notification_preference_test.rb
ruby -Iapp/services -Itest test/unit/webhook_delivery_service_test.rb
```

## License

By contributing to this repository, you agree that your contributions will be licensed under the GNU General Public License v2.0 (GPL-2.0).
