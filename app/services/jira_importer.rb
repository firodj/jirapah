class JiraImporter
  PAGING = 10.freeze

  def initialize
  end

  def search(params)
    start_at = params[:start_at]

    project_keys = [*params[:project_keys]]
    raise ArgumentError, 'project_keys is required' if project_keys.empty?

    labels = [*params[:labels]]

    jql = "project IN (#{project_keys.join(', ')})"
    jql += " AND labels IN (#{labels.join(', ')})" unless labels.empty?
    jql += " AND resolution = Unresolved"
    jql += " ORDER BY updated ASC, id ASC"

    client.Issue.jql(jql, start_at: start_at, max_results: PAGING + 1)
  end

  def client
    @client ||= JIRA::Client.new(client_options)
  end

  def process(issues)
    issues.each do |issue|
      story = Story.find_or_initialize_by(guid: issue.id)
      if story.updated_at != issue.updated
        story.guid = issue.id
        story.key = issue.key
        story.summary = issue.summary
        story.epic_link = issue.customfield_10008
        story.story_point = issue.customfield_10005
        story.updated_at = issue.updated
        story.created_at = issue.created
        story.creator = assign_member(issue.creator)
        story.reporter = assign_member(issue.reporter)
        story.assignee = assign_member(issue.assignee)
        story.pair_assignee = assign_member(issue.pair_assignee) # customfield_11700
        story.qa_tester = assign_member(issue.qa_tester) # customfield_11806
        story.save!

        process_changelogs(issue)
      end
    end
  end

  def process_changelogs(issue)
    story = Story.find_by_guid!(issue.id)

    issue.changelogs.all.each do |changelog|
      ChangeLog.find_or_create_by(guid: changelog.id) do |change_log|
        change_log.author = assign_member(changelog.author)
        change_log.created_at = changelog.created
        change_log.story = story
        change_log.description = parse_changelog_items(changelog.items)
      end
    end
  end

  def assign_member(user)
    return unless user.present?
    raise ArgumentError, 'user is invalid' unless user.is_a? JIRA::Resource::User

    Member.find_or_create_by(guid: user.accountId) do |member|
      member.name = user.displayName
    end
  end

  def parse_changelog_items(items)
    items.map do |item|
      # binding.pry
      if item['fieldId']
        unless %w[summary description].include? item['fieldId']
          if item['to'].nil?
            next "remove #{item['field']} from #{item['fromString']}"
          elsif item['from'].nil?
            next "set #{item['field']} to #{item['toString']}"
          end
          next "update #{item['field']} from #{item['fromString']} to #{item['toString']}"
        end
      end
      if item['field']
        next "change field #{item['field']}"
      end
      "json for #{item.to_s}"
    end.join(", ")
  end

  def client_options
    {
      username: ENV['JIRA_USER'],
      password: ENV['JIRA_KEY'],
      site: ENV['JIRA_HOST'],
      auth_type: :basic,
      use_ssl: true,
      context_path: ''
    }
  end
end
