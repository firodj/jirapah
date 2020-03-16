class JiraImporter
  PAGING = 10.freeze

  def initialize
  end

  def search(params)
    start_at = params[:start_at]

    project_keys = [*params[:project_keys]]
    raise ArgumentError, 'project_keys is required' if project_keys.empty?

    labels = [*params[:labels]]
    raise ArgumentError, 'labels is required' if labels.empty?

    jql = "project IN (#{project_keys.join(', ')}) AND labels IN (#{labels.join(', ')})"
    jql += " AND resolution = Unresolved"
    jql += " ORDER BY Rank ASC"

    client.Issue.jql(jql, start_at: start_at, max_results: PAGING + 1)
  end

  def client
    @client ||= JIRA::Client.new(client_options)
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
