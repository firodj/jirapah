namespace :custom do
  desc "TODO"
  task do_it: :environment do
    options = {
      username: ENV['JIRA_USER'],
      password: ENV['JIRA_KEY'],
      site: ENV['JIRA_HOST'],
      auth_type: :basic,
      use_ssl: true,
      context_path: ''
    }

    client = JIRA::Client.new(options)
    projects = client.Project.all
  end
end
