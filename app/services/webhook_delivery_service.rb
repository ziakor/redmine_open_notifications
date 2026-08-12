require 'net/http'
require 'uri'
require 'json'

class WebhookDeliveryService
  attr_reader :issue, :journal, :event_type, :author

  def initialize(issue, journal, event_type, author)
    @issue = issue
    @journal = journal
    @event_type = event_type
    @author = author
  end

  def deliver_all
    settings = Setting.plugin_redmine_open_notifications rescue {}
    urls = Array(settings['webhook_urls']).reject(&:blank?)
    
    # Backward compatibility with legacy single keys
    urls << settings['webhook_url'] if settings['webhook_url'].present?
    urls << settings['slack_webhook_url'] if settings['slack_webhook_url'].present?
    urls << settings['custom_webhook_url'] if settings['custom_webhook_url'].present?
    urls = urls.compact.map(&:strip).uniq

    urls.each do |url|
      send_custom_webhook(url)
    end

    # Project-specific rules
    rules = NotificationRule.for_project(issue.project_id)
    rules.each do |rule|
      next unless event_allowed?(rule) && priority_allowed?(rule)
      send_custom_webhook(rule.webhook_url) if rule.webhook_url.present?
    end
  end

  private

  def event_allowed?(rule)
    rule.events.blank? || rule.events.include?(event_type)
  end

  def priority_allowed?(rule)
    return true if rule.conditions.blank? || rule.conditions[:min_priority_id].nil?
    issue.priority_id >= rule.conditions[:min_priority_id].to_i
  end

  def send_custom_webhook(webhook_url)
    return if webhook_url.blank?
    payload = {
      event: event_type,
      timestamp: Time.current.iso8601,
      issue: {
        id: issue.id,
        subject: issue.subject,
        project: { id: issue.project.id, name: issue.project.name },
        status: issue.status.name,
        priority: issue.priority.name,
        url: issue_url
      },
      journal: journal ? { id: journal.id, notes: journal.notes } : nil
    }
    post_json(webhook_url, payload)
  end

  def post_json(url_str, payload)
    uri = URI.parse(url_str)
    req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
    req.body = payload.to_json
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(req) }
  rescue => e
    Rails.logger.error("Webhook Delivery Failed (#{url_str}): #{e.message}")
  end

  def title_summary
    "Ticket ##{issue.id} - #{issue.subject}"
  end

  def body_summary
    (journal ? journal.notes : issue.description).to_s.truncate(200)
  end

  def issue_url
    "#{Setting.protocol}://#{Setting.host_name}/issues/#{issue.id}"
  end
end
