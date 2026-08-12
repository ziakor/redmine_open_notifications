# frozen_string_literal: true

require 'logger'
require 'minitest/autorun'
require 'active_support'
require 'active_support/test_case'
require_relative '../../app/services/webhook_delivery_service'

# Struct mocks for testing WebhookDeliveryService without requiring full DB
StructProject = Struct.new(:id, :name)
StructIssue = Struct.new(:id, :subject, :description, :project, :priority)
StructPriority = Struct.new(:name)

class WebhookDeliveryServiceTest < ActiveSupport::TestCase
  setup do
    @project = StructProject.new(1, 'Test Project')
    @priority = StructPriority.new('Urgent')
    @issue = StructIssue.new(123, 'Critical server crash', 'System down', @project, @priority)
    @service = WebhookDeliveryService.new(@issue, nil, 'issue_created', nil)
  end

  test "body_summary extracts issue description summary" do
    assert_equal "System down", @service.send(:body_summary)
  end

  test "title_summary formats issue id and subject" do
    assert_equal "Ticket #123 - Critical server crash", @service.send(:title_summary)
  end
end
