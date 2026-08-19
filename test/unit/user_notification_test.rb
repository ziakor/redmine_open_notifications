# frozen_string_literal: true

require_relative '../test_helper'

class UserNotificationTest < ActiveSupport::TestCase
  test "target_url returns issue path when no journal is present" do
    n = Struct.new(:issue_id, :journal_id) do
      def note_indice; nil; end
      def target_url
        return nil unless issue_id
        indice = note_indice
        indice ? "/issues/#{issue_id}#note-#{indice}" : "/issues/#{issue_id}"
      end
    end.new(42, nil)

    assert_equal "/issues/42", n.target_url
  end

  test "target_url returns anchor path when journal note indice is present" do
    n = Struct.new(:issue_id, :journal_id) do
      def note_indice; 3; end
      def target_url
        return nil unless issue_id
        indice = note_indice
        indice ? "/issues/#{issue_id}#note-#{indice}" : "/issues/#{issue_id}"
      end
    end.new(42, 105)

    assert_equal "/issues/42#note-3", n.target_url
  end
end
