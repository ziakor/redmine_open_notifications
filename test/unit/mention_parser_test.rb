# frozen_string_literal: true

require_relative '../test_helper'
require_relative '../../app/services/mention_parser'

class MentionParserTest < ActiveSupport::TestCase
  test "extract_logins extracts single mention" do
    text = "Hello @jsmith, please review this PR."
    assert_equal ['jsmith'], MentionParser.extract_logins(text)
  end

  test "extract_logins extracts multiple mentions and deduplicates" do
    text = "cc @alice.dupont and @bob_martin, also @alice.dupont again"
    assert_equal ['alice.dupont', 'bob_martin'], MentionParser.extract_logins(text)
  end

  test "extract_logins handles empty or nil input safely" do
    assert_equal [], MentionParser.extract_logins(nil)
    assert_equal [], MentionParser.extract_logins("")
    assert_equal [], MentionParser.extract_logins("   ")
  end

  test "extract_logins ignores plain text without @ sign" do
    text = "Just a regular comment with jsmith mentioned without at symbol"
    assert_equal [], MentionParser.extract_logins(text)
  end
end
