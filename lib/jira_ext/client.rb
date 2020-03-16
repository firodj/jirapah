require_relative './changelog.rb'

JIRA::Client.class_eval {
  def ChangeLog # :nodoc:
    JIRA::Resource::ChangelogFactory.new(self)
  end
}
