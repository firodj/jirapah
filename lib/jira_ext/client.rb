require_relative './changelog.rb'

JIRA::Client.class_eval {
  def Changelog # :nodoc:
    JIRA::Resource::ChangelogFactory.new(self)
  end
}
