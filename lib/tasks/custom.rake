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
    raise StandardError.new "missing JIRA_PROJECT_KEY" if ENV['JIRA_PROJECT_KEY'].blank?
    raise StandardError.new "missing BOARD_NAME" if ENV['BOARD_NAME'].blank?

    svc = JiraImporter.new
    board =
      Rails.cache.fetch("Board/#{ENV['JIRA_PROJECT_KEY']}/#{ENV['BOARD_NAME']}", expires_in: 30.minutes) do
        svc.client.Board.all.find { |x|
          if x.name.include?(ENV['BOARD_NAME']) then
            prj = Rails.cache.fetch("Board/#{x.id}/project", expires_in: 30.minutes) do
              x.project
            end
            prj['key'] == ENV['JIRA_PROJECT_KEY']
          else
            false
          end
        }
      end

    sprints =
      Rails.cache.fetch("Board/#{board.id}/active-sprints", expires_in: 30.minutes) do
        board.sprints.select { |x| x.state == 'active' }
      end

    stories = {}
    subtasks = {}
    totals = {}
    epics = {}

    sprints.each { |sprint|
      issuetypes = %w(Story Task Sub-task)
      jql = "sprint = #{sprint.id}"
      jql += " AND issuetype IN (#{issuetypes.join(', ')})"
      jql += " ORDER BY updated ASC, id ASC"
      totals[sprint.name] = Array.new(7) { |x| 0 }

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
                epic: isu.epic_link,
                assignee: isu.assignee.blank? ? nil : isu.assignee.displayName,
              }
              if isu.epic_link && !epics.key?(isu.epic_link)
                epics[isu.epic_link] = false
              end
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
                epic: isu.epic_link,
                assignee: isu.assignee.blank? ? nil : isu.assignee.displayName,
              }
              if isu.epic_link && !epics.key?(isu.epic_link)
                epics[isu.epic_link] = False
              end
            end
          end
        }
      end
    }

    epics.each_key { |key|
      epics[key] =
        Rails.cache.fetch("Epic/#{key}", expires_in: 30.minutes) do
          svc.client.Issue.find(key)
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

    points_totals = -> (sprints, sp) {
      sprints.each { |sprint_name|
        totals[sprint_name].each_with_index { |val,index|
          totals[sprint_name][index] += sp[index] || 0
        }
      }
    }

    puts %w(key sub-key epic sprints assignee title type status points sub-points to-do in-progress in-review testing staging-verified product-verified done).to_csv
    stories.each { |key, story|
      next if story[:status] == "Invalid"
      rest_subtasks = story[:subtasks].map { |subkey| subtasks[subkey] }.reject { |x| x[:status] == "Invalid" }

      if rest_subtasks.count > 0
        epic_name = story[:epic]
        if epics[story[:epic]]
          epic_name += " - " + epics[story[:epic]].summary
        end
        a = [story[:key], nil, epic_name, story[:sprints].join(", "), story[:assignee], story[:title], story[:type], story[:status], story[:story_points], 0]
        puts a.to_csv
        story_points = (story[:story_points] || 0) / rest_subtasks.count.to_f
        rest_subtasks.each { |subtask|
          pts = status_to_points.call(subtask[:status], story_points)
          a = [nil, subtask[:key], nil, subtask[:sprints].join(", "), story[:assignee], subtask[:title], subtask[:type], subtask[:status], 0, story_points ] + pts
          puts a.to_csv
          points_totals.call(subtask[:sprints], pts)
        }
      else
        epic_name = story[:epic]
        if epics[story[:epic]]
          epic_name += " - " + epics[story[:epic]].summary
        end
        pts = status_to_points.call(story[:status], story[:story_points])
        a = [story[:key], nil, epic_name, story[:sprints].join(", "), story[:assignee], story[:title], story[:type], story[:status], story[:story_points], story[:story_points]] + pts
        puts a.to_csv
        points_totals.call(story[:sprints], pts)
      end
    }

    puts [].to_csv

    rows = [%w(sprint points to-do in-progress in-review testing staging-verified product-verified done)]
    totals.each { |sprint_name, totals|

      tots = totals.inject(0){|sum,x| sum + x }
      a = [nil, nil, nil, sprint_name, nil, 'Total', nil, tots, nil] + totals
      rows.push( [sprint_name, tots] + totals )
      puts a.to_csv
    }

    puts [].to_csv

    x = rows.count
    y = rows[0].count

    (1..y).each { |index_y|
      cols = []
      (1..x).each { |index_x|
        cols.push( rows[index_x-1][index_y-1] )
      }
      puts cols.to_csv
    }

    # binding.pry
  end

end
