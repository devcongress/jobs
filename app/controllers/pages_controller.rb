class PagesController < ApplicationController
  def index
    @jobs = Job.all.order('created_at DESC')
  end

  def help
  end

  def about
  end

  def privacy
  end
end
