module WelcomeHelper
  def initials(name)
    name.gsub(/\w+\.?\s?/){ |s| s[0].upcase }
  end
end
