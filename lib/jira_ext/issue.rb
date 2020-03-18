require_relative './changelog.rb'

JIRA::Resource::Issue.class_eval {
  has_many :changelogs
  has_one :creator,       class: JIRA::Resource::User,
                          nested_under: 'fields'
  has_one :pair_assignee, class: JIRA::Resource::User,
                          attribute_key: 'customfield_11700'
  has_one :qa_tester,     class: JIRA::Resource::User,
                          attribute_key: 'customfield_11806'
  has_one :resolution,    nested_under: 'fields'

  def epic_link
    @attrs['fields']['customfield_10008'] if @attrs && @attrs['fields']
  end

  def story_point
    @attrs['fields']['customfield_10005'] if @attrs && @attrs['fields']
  end
}