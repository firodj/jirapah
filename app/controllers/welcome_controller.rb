class WelcomeController < ApplicationController
  def index
    @stories = Story.includes(:reporter, :assignee, :pair_assignee, :qa_tester, :creator).order(changed_at: :desc).take(10)
  end
end
