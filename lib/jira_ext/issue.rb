require_relative './changelog.rb'

JIRA::Resource::Issue.class_eval {
    has_many :changelogs
}