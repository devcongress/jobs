class PagesController < ApplicationController
  def index
    @jobs = Job.where(:archived => false).order('created_at DESC')    
  end

  def help
  end

  def about
  end

  def privacy
  end
end
