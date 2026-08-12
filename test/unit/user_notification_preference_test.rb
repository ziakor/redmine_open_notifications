# frozen_string_literal: true

require 'logger'
require 'time'
require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
require 'active_support/core_ext/time'
require 'active_support/core_ext/object/blank'

class UserNotificationPreferenceMock
  attr_accessor :quiet_hours_start, :quiet_hours_end, :current_time_override

  def initialize(quiet_hours_start: nil, quiet_hours_end: nil, current_time_override: nil)
    @quiet_hours_start = quiet_hours_start
    @quiet_hours_end = quiet_hours_end
    @current_time_override = current_time_override
  end

  def quiet_hours?
    return false if quiet_hours_start.blank? || quiet_hours_end.blank?

    now_time = (current_time_override || Time.current).strftime("%H:%M")
    if quiet_hours_start < quiet_hours_end
      now_time >= quiet_hours_start && now_time <= quiet_hours_end
    else
      now_time >= quiet_hours_start || now_time <= quiet_hours_end
    end
  end
end

class UserNotificationPreferenceTest < ActiveSupport::TestCase
  test "quiet_hours? returns false when quiet hours are not set" do
    pref = UserNotificationPreferenceMock.new(quiet_hours_start: nil, quiet_hours_end: nil)
    refute pref.quiet_hours?
  end

  test "quiet_hours? detects daytime range" do
    pref = UserNotificationPreferenceMock.new(
      quiet_hours_start: "08:00",
      quiet_hours_end: "18:00",
      current_time_override: Time.parse("2026-08-11 12:00:00")
    )
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 20:00:00")
    refute pref.quiet_hours?
  end

  test "quiet_hours? detects overnight range across midnight" do
    pref = UserNotificationPreferenceMock.new(
      quiet_hours_start: "18:00",
      quiet_hours_end: "08:30",
      current_time_override: Time.parse("2026-08-11 22:00:00")
    )
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 04:00:00")
    assert pref.quiet_hours?

    pref.current_time_override = Time.parse("2026-08-11 14:00:00")
    refute pref.quiet_hours?
  end
end
