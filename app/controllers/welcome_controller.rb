class WelcomeController < ApplicationController
  def index
    columns
  end

  def timeline
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

    def columns
      return @columns unless @columns.nil?

      columns = []

      if (filter_members.count > 0)
        columns.push(
          title: "Current",
          stories: Story.includes(:assignee, :pair_assignee)
            .not_epic
            .assigned_to(filter_members)
            .where.not(status_guid: Story::ST_DONE)
            .order(changed_at: :desc).take(100)
        )
        columns.push(
          title: "Done",
          stories: Story.includes(:assignee, :pair_assignee)
            .not_epic
            .where(status_guid: Story::ST_DONE)
            .assigned_to(filter_members)
            .order(resolved_at: :desc).take(100)
        )
      else
        columns.push(
          title: "Current",
          stories: Story.includes(:assignee, :pair_assignee)
            .not_epic
            .where.not(status_guid: Story::ST_DONE)
            .unassigned_to(members.map(&:id))
            .order(changed_at: :desc).take(100)
        )
        columns.push(
          title: "Done",
          stories: Story.includes(:assignee, :pair_assignee)
            .not_epic
            .where(status_guid: Story::ST_DONE)
            .order(resolved_at: :desc).take(100)
        )
      end

      @columns = columns
    end

    def cards
      return @cards unless @cards.nil?

      today = Time.now.beginning_of_day
      starting =  today - 3.weeks

      add_to_cells = ->(cells, time, params) {
        if time && time >= starting
          d = ((time - starting) / 1.days).floor
          cells[d] = (cells[d] || []).push(params)
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

      if (filter_members.count > 0)
        stories = Story
          .not_epic
          .not_todo
          .assigned_to(filter_members)
          .where('(status_guid != ? and changed_at >= ?) or (status_guid = ? and resolved_at >= ?)',
            Story::ST_DONE, starting, Story::ST_DONE, starting)
          .order(posted_at: :asc)
      else
        stories = Story
          .not_epic
          .not_todo
          .assigned_to(members.map(&:id))
          .where('(status_guid != ? and changed_at >= ?) or (status_guid = ? and resolved_at >= ?)',
            Story::ST_DONE, starting, Story::ST_DONE, starting)
          .order(posted_at: :asc)
      end

      @cards = stories.map do |story|
        cells = {}

        add_to_cells.call(cells, story.resolved_at, status: :resolved, names: story.assignee_names, color: 'green-400')
        add_to_cells.call(cells, story.changed_at, status: :updated, names: story.assignee_names, color: 'yellow-400')
        add_to_cells.call(cells, story.posted_at, status: :posted, names: story.reporter.name, color: 'blue-300')
        story.change_logs.each do |change_log|
          add_to_cells.call(cells, change_log.changed_at,
            status: :changed, names: change_log.author.name, color: 'yellow-300')
        end

        {
          key: story.key,
          summary: story.clean_summary,
          cells: cells,
          order: [story.resolved_at.to_i || 0, story.posted_at.to_i]
        }
      end.sort_by { |card| card[:order] }
    end
end
