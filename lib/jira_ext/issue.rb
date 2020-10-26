require_relative './changelog.rb'

JIRA::Resource::Issue.class_eval {
  has_many :changelogs
  has_one :creator,       class: JIRA::Resource::User,
                          nested_under: 'fields'
  #has_one :pair_assignee, class: JIRA::Resource::User,
  #                        nested_under: 'fields',
  #                        attribute_key: 'customfield_11700'
  #has_one :qa_tester,     class: JIRA::Resource::User,
  #                        nested_under: 'fields',
  #                        attribute_key: 'customfield_11806'
  has_one :resolution,    nested_under: 'fields'

  def epic_link
    @attrs['fields'][ENV['CUSTOM_EPIC_LINK']] if @attrs && @attrs['fields']
  end

  def story_points
    @attrs['fields'][ENV['CUSTOM_STORY_POINTS']] if @attrs && @attrs['fields']
  end

  def sprints
    @attrs['fields'][ENV['CUSTOM_SPRINTS']] if @attrs && @attrs['fields']
  end

  def squad_name
    @attrs['fields'][ENV['CUSTOM_SQUAD_NAME']] if @attrs && @attrs['fields']
  end
}