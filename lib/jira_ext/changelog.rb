module JIRA
  module Resource
    class ChangelogFactory < JIRA::BaseFactory # :nodoc:
    end

    class Changelog < JIRA::Base
      belongs_to :issue
      has_one :author,  class: JIRA::Resource::User
      nested_collections true

      def self.all(client, options = {})
        issue = options[:issue]
        raise ArgumentError, 'parent issue is required' unless issue.is_a? JIRA::Resource::Issue

        path = "#{issue.self}/#{endpoint_name}"
        response = client.get(path)
        json = parse_json(response.body)
        json['values'].map do |changelog|
          issue.changelogs.build(changelog)
        end
      end
    end
  end
end