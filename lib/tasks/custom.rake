namespace :custom do
  desc "Testing"
  task jira_test: :environment do
    svc = JiraImporter.new
    isu1 = svc.client.Issue.find("#{ENV['JIRA_PROJECT_KEY']}-17048", {:expand => [:transitions]})
    # svc.process([isu1, isu2])
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

    svc.chunk(project_keys: ENV['JIRA_PROJECT_KEY'], resolved: false, updated_at: updated_at) do |issues|
      svc.process(issues)
    end

    svc.chunk(project_keys: ENV['JIRA_PROJECT_KEY'], resolved: true, updated_at: updated_at) do |issues|
      svc.process(issues)
    end
  end

  desc "Get fields"
  task fields: :environment do
    svc = JiraImporter.new
    svc.field_map.each { |k,v|
      puts "#{k}\t#{v}"
    }
  end

  desc "Daily report"
  task daily: :environment do
    svc = JiraImporter.new
    board =
      Rails.cache.fetch("Board/#{ENV['SQUAD_NAME']}", expires_in: 30.minutes) do
        svc.client.Board.all.find { |x| x.name.include? ENV['SQUAD_NAME'] }
      end

    sprint =
      Rails.cache.fetch("Board/#{board.id}/active-sprint", expires_in: 30.minutes) do
        board.sprints.find { |x| x.state == 'active' }
      end

    issuetypes = %w(Story Task Sub-task)
    jql = "sprint = #{sprint.id}"
    jql += " AND issuetype IN (#{issuetypes.join(', ')})"
    jql += " ORDER BY updated ASC, id ASC"


    svc.chunk_jql(jql) do |issues|
      issues.each { |isu|
        row = [ isu.issuetype.name, isu.parent.present? ? isu.parent.key : nil, isu.key, isu.summary, isu.story_points, isu.status.name]
        puts row.to_csv
      }
    end

    binding.pry
  end

end
