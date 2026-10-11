require "test_helper"

class Hiring::JobPostSlackMessageTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup do
    @company = create_company!(name: "Acme & Co")
    @job = create_job!(company: @company, title: "Senior <Rails> Engineer", seniority: :senior, city: "Accra", country: "Ghana",
      remote_ok: true, salary_min: 5000, salary_max: 8000, pay_period: :month,
      description: "## About\nYou'll **build** the payments platform for West Africa.")
  end

  test "live message" do
    message = Hiring::JobPostSlackMessage.new(@job)
    url = Slack.url(Rails.application.routes.url_helpers.public_job_path(@job))

    assert_equal "New job at Acme &amp; Co: Senior &lt;Rails&gt; Engineer", message.text
    header, excerpt, actions = message.blocks
    assert_equal "*<#{url}|Senior &lt;Rails&gt; Engineer>* · Acme &amp; Co\nFull time · Senior · Accra, Ghana · Remote · 5,000 – 8,000 USD per month", header.dig(:text, :text)
    assert_equal "About You'll build the payments platform for West Africa.", excerpt.dig(:text, :text)
    assert_equal url, actions[:elements].sole[:url]
    assert_equal "View & apply", actions[:elements].sole.dig(:text, :text)
  end

  test "blank details are left out" do
    job = create_job!(company: @company, title: "Intern", employment_type: :internship, paid: false, description: "Learn.")
    header = Hiring::JobPostSlackMessage.new(job).blocks.first
    assert_match(/\nInternship · Unpaid\z/, header.dig(:text, :text))
  end

  test "closed message" do
    message = Hiring::JobPostSlackMessage.new(@job, closed_as: "filled")

    assert_equal "Filled: Senior &lt;Rails&gt; Engineer at Acme &amp; Co", message.text
    assert_equal 1, message.blocks.size
    assert_equal "~Senior &lt;Rails&gt; Engineer~ · Acme &amp; Co\n*Filled*", message.blocks.first.dig(:text, :text)

    assert_match "*Expired*", Hiring::JobPostSlackMessage.new(@job, closed_as: "expired").blocks.first.dig(:text, :text)
    assert_match "*No longer available*", Hiring::JobPostSlackMessage.new(@job, closed_as: "withdrawn").blocks.first.dig(:text, :text)
  end
end
