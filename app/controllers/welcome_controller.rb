class WelcomeController < ApplicationController
  def index
    @stories = Story.includes(:reporter, :assignee, :pair_assignee, :qa_tester, :creator)
      .where.not(kind_guid: '10000')
      .order(changed_at: :desc).take(100)

  end
end
