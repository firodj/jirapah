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

    sprints =
      Rails.cache.fetch("Board/#{board.id}/active-sprints", expires_in: 30.minutes) do
        board.sprints.select { |x| x.state == 'active' }
      end

    stories = {}
    subtasks = {}

    sprints.each { |sprint|
      issuetypes = %w(Story Task Sub-task)
      jql = "sprint = #{sprint.id}"
      jql += " AND issuetype IN (#{issuetypes.join(', ')})"
      jql += " ORDER BY updated ASC, id ASC"

      svc.chunk_jql(jql) do |issues|
        issues.each { |isu|
          if %w(Story Task).include? isu.issuetype.name then
            if stories.key?(isu.key) then
              stories[isu.key][:sprints].push(sprint.name)
            else
              stories[isu.key] = {
                type: isu.issuetype.name,
                key: isu.key,
                title: isu.summary,
                story_points: isu.story_points,
                status: isu.status.name,
                subtasks: isu.subtasks.map { |x| x["key"] },
                sprints: [sprint.name],
              }
            end
          else
            if subtasks.key?(isu.key) then
              subtasks[isu.key][:sprints].push(sprint.name)
            else
              subtasks[isu.key] = {
                type: isu.issuetype.name,
                key: isu.key,
                parent_key: isu.parent.key,
                title: isu.summary,
                story_points: nil,
                status: isu.status.name,
                sprints: [sprint.name],
              }
            end
          end
        }
      end
    }

    status_to_points = -> (s, p) {
      n = nil
      case s
      when "Invalid"
      when "To Do"
        n = 0
      when "In Progress"
        n = 1
      when "In Review"
        n = 2
      when "Ready for Staging"
        n = 3
      when "Test in Staging"
        n = 3
      when "Staging Verified"
        n = 4
      when "Product Verified"
        n = 5
      when "Done"
        n = 6
      else
        raise "Unhandled status #{s}"
      end

      sp = Array.new(7) { |x| nil }
      sp[n] = p unless n.nil?
      return sp
    }

    puts %w(key sub-key sprints title type status points sub-points to-do in-progress in-review testing staging-verified product-verified done).to_csv
    stories.each { |key, story|
      next if story[:status] == "Invalid"
      rest_subtasks = story[:subtasks].map { |subkey| subtasks[subkey] }.reject { |x| x[:status] == "Invalid" }

      if rest_subtasks.count > 0
        a = [story[:key], nil, story[:sprints].join(", "), story[:title], story[:type], story[:status], story[:story_points], 0]
        puts a.to_csv
        story_points = (story[:story_points] || 0) / rest_subtasks.count.to_f
        rest_subtasks.each { |subtask|
          a = [nil, subtask[:key], subtask[:sprints].join(", "), subtask[:title], subtask[:type], subtask[:status], 0, story_points ] + status_to_points.call(subtask[:status], story_points)
          puts a.to_csv
        }
      else
        a = [story[:key], nil, story[:sprints].join(", "), story[:title], story[:type], story[:status], story[:story_points], story[:story_points]] + status_to_points.call(story[:status], story[:story_points])
        puts a.to_csv
      end
    }

    # binding.pry
  end

end
