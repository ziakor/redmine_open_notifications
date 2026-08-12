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
end
