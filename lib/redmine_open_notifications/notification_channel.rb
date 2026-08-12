# frozen_string_literal: true

module RedmineOpenNotifications
  if defined?(ActionCable)
    class NotificationChannel < ActionCable::Channel::Base
      def subscribed
        stream_from "user_#{current_user.id}_notifications"
      end
    end
  end
end
