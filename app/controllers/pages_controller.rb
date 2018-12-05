class PagesController < ApplicationController
  def index
    @jobs = Job.all_active
  end

  def help
  end

  def about
  end

  def privacy
  end
end
