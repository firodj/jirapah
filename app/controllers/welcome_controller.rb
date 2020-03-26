class WelcomeController < ApplicationController
  def index
    epics
    columns
  end

  def timeline
    epics
    cards
  end

  private
    def members
      @members ||= Member.preferred.order(:name).all
    end

    def filter_members
      return @filter_members unless @filter_members.nil?
      filter_members = (params[:filter_members] || '').split(',').map{ |v| v.to_i }.uniq
      @filter_members = members.map(&:id) & filter_members
    end

    def epics
      @epics ||= Epic.order(:name).all
    end

    def columns
      return @columns unless @columns.nil?

      columns = []

      if params[:epic]
        epic = Epic.find(params[:epic])
        current_stories = epic.stories
        done_stories = epic.stories
      else
        current_stories = Story.not_epic
        done_stories = Story.not_epic
      end

      current_stories = current_stories #includes(:assignee, :pair_assignee)
        .where.not(status_guid: Story::ST_DONE)
        .order(changed_at: :desc).limit(100)
      done_stories = done_stories
        .where(status_guid: Story::ST_DONE)
        .order(resolved_at: :desc).limit(100)

      if (filter_members.count > 0)
        current_stories = current_stories.assigned_to(filter_members)
        done_stories = done_stories.assigned_to(filter_members)
      else
        current_stories = current_stories.unassigned_to(members.map(&:id))
      end

      columns.push(
        title: "Current",
        stories: current_stories
      )
      columns.push(
        title: "Done",
        stories: done_stories
      )

      @columns = columns
    end

    def cards
      return @cards unless @cards.nil?

      today = Time.now.beginning_of_day
      starting =  today - 3.weeks

      add_to_cells = ->(cells, time, props) {
        if time && time >= starting
          d = ((time - starting) / 1.days).floor
          cells[d] = (cells[d] || []).push(props)
        end
      }

      @lines = starting.localtime.to_date.upto(today.localtime.to_date).map do |date|
        {
          year: date.year,
          month: date.month,
          day: date.day,
          day_name: date.strftime('%a'),
          month_name: date.strftime('%b'),
          is_weekend: date.on_weekend?
        }
      end

      if params[:epic]
        epic = Epic.find(params[:epic])
        stories = epic.stories
      else
        stories = Story.not_epic.not_todo
      end

      stories = stories
        .where('(status_guid != ? and changed_at >= ?) or (status_guid = ? and resolved_at >= ?)',
          Story::ST_DONE, starting, Story::ST_DONE, starting)
        .order(posted_at: :asc)

      if (filter_members.count > 0)
        stories = stories.assigned_to(filter_members)
      else
        stories = stories.assigned_to(members.map(&:id))
      end

      epic_titles = {}
      @cards = stories.map do |story|
        cells = {}

        add_to_cells.call(cells, story.resolved_at, status: :resolved, names: story.assignee_names, color: 'green-400')
        add_to_cells.call(cells, story.changed_at, status: :updated, names: story.assignee_names, color: 'yellow-400')
        add_to_cells.call(cells, story.posted_at, status: :posted, names: story.reporter.name, color: 'blue-300')
        #story.change_logs.each do |change_log|
        #  add_to_cells.call(cells, change_log.changed_at,
        #    status: :changed, names: change_log.author.name, color: 'yellow-300')
        #end

        epic_titles[story.epic_link] = story.epic ? story.epic.clean_title : '' if epic_titles[story.epic_link].nil?

        {
          key: story.key,
          epic_title: epic_titles[story.epic_link],
          summary: story.clean_summary,
          cells: cells,
          order: [story.resolved_at.to_i || 0, story.posted_at.to_i]
        }
      end.sort_by { |card| card[:order] }
    end
end
