namespace :custom do
  desc "Testing"
  task jira_test: :environment do
    svc = JiraImporter.new
    isu1 = svc.client.Issue.find('GLB-5464')
    isu2 =  svc.client.Issue.find('GLB-5509')
    svc.process([isu1, isu2])
    binding.pry
  end

  desc "Get last JIRA withih days ago"
  task :jira_latest, [:ago] => :environment do |task, args|
    if args.ago.blank?
      puts "Please provide the days: " + Rainbow("`ago`").red + " or " + Rainbow("'begin'").yellow
      exit 1
    end

    if args.ago == 'begin'
      updated_at = JiraImporter::BEGIN_DATE
    else
      updated_at = Time.now.beginning_of_day - args.ago.to_i.days
    end

    svc = JiraImporter.new

    svc.chunk(project_keys: "GLB", resolved: false, updated_at: updated_at) do |issues|
      svc.process(issues)
    end

    svc.chunk(project_keys: "GLB", resolved: true, updated_at: updated_at) do |issues|
      svc.process(issues)
    end
  end
end
