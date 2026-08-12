# frozen_string_literal: true

module RedmineOpenNotifications
  module Patches
    module UserPatch
      extend ActiveSupport::Concern

      included do
        has_many :user_notifications, dependent: :destroy
        has_one :user_notification_preference, dependent: :destroy
      end
    end
  end
end

unless User.included_modules.include?(RedmineOpenNotifications::Patches::UserPatch)
  User.include(RedmineOpenNotifications::Patches::UserPatch)
end
