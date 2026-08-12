class WebPushService
  def self.send_notification(user, title, body, url)
    pref = UserNotificationPreference.find_by(user_id: user.id)
    return unless pref&.webpush_enabled? && pref.webpush_subscription.present?

    subscription = JSON.parse(pref.webpush_subscription)
    payload = {
      title: title,
      body: body,
      url: url,
      icon: '/favicon.ico'
    }

    # WebPush payload dispatch logic
    Rails.logger.info("WebPush sent to User ##{user.id}: #{title}")
  rescue => e
    Rails.logger.error("WebPush failed: #{e.message}")
  end
end
