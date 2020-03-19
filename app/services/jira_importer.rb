class JiraImporter
  PAGING = 100.freeze
  BEGIN_DATE = '2020-01-01T00:00:00.000+0700'.freeze
  FIXME = false.freeze

  def initialize
  end

  def chunk(params)
    prev_issue = nil
    start_at = 0
    loop do
      params[:start_at] = start_at
      params[:limit] = PAGING + 1

      issues = search(params)
      break unless issues.count

      raise 'Paging disorder' if prev_issue.present? and prev_issue.id != issues[0].id

      yield issues[0..PAGING-1]

      break if issues.count <= PAGING

      prev_issue = issues[-1]
      start_at += PAGING
    end
  end

  def search(params)
    start_at = params[:start_at]
    resolved = params[:resolved] || false
    limit = params[:limit] || PAGING

    updated_at = jira_tz(params[:updated_at]) if params[:updated_at]
    begin_date = jira_tz(BEGIN_DATE)

    project_keys = [*params[:project_keys]]
    raise ArgumentError, 'project_keys is required' if project_keys.empty?

    labels = [*params[:labels]]

    jql = "project IN (#{project_keys.join(', ')})"
    jql += " AND labels IN (#{labels.join(', ')})" unless labels.empty?

    jql += " AND resolution != Unresolved" if resolved
    jql += " AND resolution = Unresolved" unless resolved

    jql += " AND created >= '#{begin_date}'" unless updated_at
    jql += " AND updated >= '#{updated_at}'" if updated_at
    jql += " ORDER BY updated ASC, id ASC"

    puts "JQL: " + Rainbow(jql).green
    puts "     start_at: " + Rainbow(start_at).blue + ", max_results: " + Rainbow(limit).blue
    client.Issue.jql(jql, start_at: start_at, max_results: limit)
  end

  def client
    @client ||= JIRA::Client.new(client_options)
  end

  def jira_tz(date)
    time = date
    time = Time.parse(date) if date.is_a? String
    time = date.to_time if date.is_a? DateTime

    time.in_time_zone(myself.timeZone).strftime("%Y-%m-%d %H:%M")
  end

  def myself
    @myself ||= client.User.myself
  end

  def process(issues)
    issues.each do |issue|
      story = Story.find_or_initialize_by(guid: issue.id)

      if story.changed_at != issue.updated or FIXME
        story.guid = issue.id
        story.key = issue.key
        story.summary = issue.summary
        story.epic_link = issue.customfield_10008
        story.story_point = issue.customfield_10005
        story.changed_at = issue.updated
        story.posted_at = issue.created
        story.creator = assign_member(issue.creator)
        story.reporter = assign_member(issue.reporter)
        story.assignee = assign_member(issue.assignee)
        story.pair_assignee = assign_member(issue.pair_assignee) # customfield_11700
        story.qa_tester = assign_member(issue.qa_tester) # customfield_11806
        story.project_guid = issue.project.key
        story.labels = issue.labels
        story.resolved_at = issue.resolutiondate

        if issue.resolution
          story.resolution = issue.resolution.name
          story.resolution_guid = issue.resolution.id
        else
          story.resolution = nil
          story.resolution_guid = nil
        end

        if issue.status
          story.status = issue.status.name
          story.status_guid = issue.status.id
        else
          story.status = nil
          story.status_guid = nil
        end

        if issue.issuetype
          story.kind = issue.issuetype.name
          story.kind_guid = issue.issuetype.id
        else
          story.kind = nil
          story.kind_guid = nil
        end

        story.save!

        process_changelogs(issue) unless FIXME
      end

      process_comments(issue) unless FIXME
    end
  end

  def process_comments(issue)
    story = Story.find_by_guid!(issue.id)

    issue.comments.each do |jira_comment|
      comment = Comment.find_or_initialize_by(guid: jira_comment.id)
      if comment.changed_at != jira_comment.updated
        comment.guid = jira_comment.id
        comment.author = assign_member(jira_comment.author)
        comment.editor = assign_member(jira_comment.editor)
        comment.changed_at = jira_comment.updated
        comment.posted_at = jira_comment.created
        comment.story = story
        comment.save!
      end
    end
  end

  def process_changelogs(issue)
    story = Story.find_by_guid!(issue.id)

    issue.changelogs.all.each do |changelog|
      ChangeLog.find_or_create_by(guid: changelog.id) do |change_log|
        change_log.author = assign_member(changelog.author)
        change_log.changed_at = changelog.created
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
          if item['to'].blank? && item['toString'].blank?
            next "remove [#{item['field']}](#{item['fieldId']}) from [#{item['fromString']}](#{item['from']})"
          elsif item['from'].blank? && item['fromString'].blank?
            next "set [#{item['field']}](#{item['fieldId']}) to [#{item['toString']}](#{item['to']})"
          end
          next "update [#{item['field']}](#{item['fieldId']}) from [#{item['fromString']}](#{item['from']}) to [#{item['toString']}](#{item['to']})"
        end
      end
      if item['field']
        next "change field [#{item['field']}]"
      end
      item.to_s
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
