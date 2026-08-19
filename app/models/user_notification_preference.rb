# frozen_string_literal: true

class UserNotificationPreference < ActiveRecord::Base
  belongs_to :user

  validates :user_id, presence: true, uniqueness: true

  def events_list
    if respond_to?(:enabled_events) && enabled_events.present?
      enabled_events.split(',').map(&:strip)
    else
      ['user_mentioned', 'issue_created', 'issue_updated', 'note_added']
    end
  end

  def event_enabled?(event_type)
    return true if event_type.to_s == 'user_mentioned'
    events_list.include?(event_type.to_s)
  end

  def quiet_hours?
    return false if quiet_hours_start.blank? || quiet_hours_end.blank?

    if work_days.present?
      active_days = work_days.split(',').map(&:strip)
      current_wday = Time.current.wday.to_s
      return false unless active_days.include?(current_wday)
    end

    now_time = Time.current.strftime("%H:%M")
    if quiet_hours_start < quiet_hours_end
      now_time >= quiet_hours_start && now_time <= quiet_hours_end
    else
      now_time >= quiet_hours_start || now_time <= quiet_hours_end
    end
  end

  def effective_notification_scope
    respond_to?(:notification_scope) && notification_scope.present? ? notification_scope : 'redmine_default'
  end

  def allows_event_for_issue?(event_type, issue, is_mentioned = false)
    return true if is_mentioned
    return true unless issue

    scope = effective_notification_scope
    case scope
    when 'mentions_only'
      false
    when 'only_involved'
      is_involved?(issue)
    when 'all_events'
      true
    else # 'redmine_default'
      u = user || (defined?(User) ? User.find_by(id: user_id) : nil)
      return true unless u
      return true if is_involved?(issue)
      if u.respond_to?(:notify_about?)
        u.notify_about?(issue)
      else
        true
      end
    end
  end

  def is_involved?(issue)
    return false unless user_id && issue
    return true if issue.respond_to?(:assigned_to_id) && issue.assigned_to_id == user_id
    return true if issue.respond_to?(:author_id) && issue.author_id == user_id
    if issue.respond_to?(:watcher_users)
      return true if issue.watcher_users.to_a.map(&:id).include?(user_id)
    elsif issue.respond_to?(:watched_by?)
      u = user || (defined?(User) ? User.find_by(id: user_id) : nil)
      return true if u && issue.watched_by?(u)
    end
    false
  end
end
