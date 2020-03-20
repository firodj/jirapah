class WelcomeController < ApplicationController
  def index
    columns
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
            .where.not(kind_guid: '10000')
            .assigned_to(filter_members)
            .where.not(status_guid: Story::ST_DONE)
            .order(changed_at: :desc).take(100)
        )
        columns.push(
          title: "Done",
          stories: Story.includes(:assignee, :pair_assignee)
            .where.not(kind_guid: '10000')
            .where(status_guid: Story::ST_DONE)
            .assigned_to(filter_members)
            .order(resolved_at: :desc).take(100)
        )
      else
        columns.push(
          title: "Current",
          stories: Story.includes(:assignee, :pair_assignee)
            .where.not(kind_guid: '10000')
            .where.not(status_guid: Story::ST_DONE)
            .unassigned_to(members.map(&:id))
            .order(changed_at: :desc).take(100)
        )
        columns.push(
          title: "Done",
          stories: Story.includes(:assignee, :pair_assignee)
            .where.not(kind_guid: '10000')
            .where(status_guid: Story::ST_DONE)
            .order(resolved_at: :desc).take(100)
        )
      end



      @columns = columns
    end
end
