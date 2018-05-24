class PagesController < ApplicationController
  def index
    @jobs = Job.all
  end

  def help
  end

  def about
  end

  def privacy
  end
end
