class MentionParser
  MENTION_REGEX = /@([a-zA-Z0-9_\.-]+)/

  def self.extract_logins(text)
    return [] if text.blank?
    text.scan(MENTION_REGEX).flatten.uniq
  end
end
