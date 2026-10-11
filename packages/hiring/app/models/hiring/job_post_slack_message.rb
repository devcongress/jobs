module Hiring
  # How a job looks in #jobs: the live post, or the closed version once it's
  # filled, expired, archived or withdrawn (posted status, see SlackJobPostSyncJob).
  class JobPostSlackMessage
    CLOSED_LABELS = {"filled" => "Filled", "expired" => "Expired", "archived" => "No longer available", "withdrawn" => "No longer available"}.freeze

    def initialize(job_post, closed_as: nil)
      @job = job_post
      @closed_as = closed_as
    end

    def text
      if @closed_as
        "#{CLOSED_LABELS.fetch(@closed_as)}: #{Slack.escape(@job.title)} at #{Slack.escape(@job.poster_name)}"
      else
        "New #{@job.kind_noun} at #{Slack.escape(@job.poster_name)}: #{Slack.escape(@job.title)}"
      end
    end

    def blocks
      @closed_as ? closed_blocks : live_blocks
    end

    private

    def live_blocks
      [
        section("*<#{url}|#{Slack.escape(@job.title)}>* · #{Slack.escape(@job.poster_name)}\n#{Slack.escape(details)}"),
        ({type: "section", text: {type: "plain_text", text: excerpt}} if excerpt.present?),
        {type: "actions", elements: [{type: "button", text: {type: "plain_text", text: "View & apply"}, url:, style: "primary"}]}
      ].compact
    end

    def closed_blocks
      [section("~#{Slack.escape(@job.title)}~ · #{Slack.escape(@job.poster_name)}\n*#{CLOSED_LABELS.fetch(@closed_as)}*")]
    end

    def section(text) = {type: "section", text: {type: "mrkdwn", text:}}

    def details
      [@job.type_label, @job.seniority&.humanize, @job.location.presence, @job.pay, @job.timing].compact.join(" · ")
    end

    # The description is Markdown. Drop the syntax and keep about two lines.
    def excerpt
      @job.description.to_s.gsub(/[#*_`>\[\]]/, "").squish.truncate(200)
    end

    def url = Slack.url(Rails.application.routes.url_helpers.public_job_path(@job))
  end
end
