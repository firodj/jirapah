class WelcomeController < ApplicationController
  def index
    @columns = columns
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
      [
        {
          title: "Current",
          stories: Story.includes(:assignee, :pair_assignee) #, :qa_tester, :creator)
            .where.not(kind_guid: '10000')
            .assigned_to(filter_members)
            .where.not(status_guid: Story::ST_DONE)
            .order(changed_at: :desc).take(10)
        },
        {
          title: "Done",
          stories: Story.includes(:assignee, :pair_assignee) #, :qa_tester, :creator)
            .where.not(kind_guid: '10000')
            .assigned_to(filter_members)
            .where(status_guid: Story::ST_DONE)
            .order(resolved_at: :desc).take(10)
        }
      ]
    end
end
