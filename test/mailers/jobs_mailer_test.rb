require 'test_helper'

class JobsMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  test "published" do
    client = FactoryBot.create(:client)
    job    = FactoryBot.create(:job, company: client.company)
    mail   = JobsMailer.with(job: job).published

    assert_equal "New job published: #{job.role} @ #{job.company.name}", mail.subject
    assert_equal [client.user.email], mail.to
    assert_equal ["jobs@devcongress.org"], mail.from
    assert_equal ["jobs@devcongress.org"], mail.reply_to

    mail_body = mail.body.encoded
    assert_match job.role,      mail_body
    assert_match root_url,      mail_body
    assert_match job_url(job),  mail_body
  end

  test "renewed" do
    client = FactoryBot.create(:client)
    job    = FactoryBot.create(:job, company: client.company)
    mail   = JobsMailer.with(job: job).renewed

    assert_equal "🎉#{job.title} has been renewed for another #{Job.validity_period} days", mail.subject
    assert_equal [client.user.email], mail.to
    assert_equal ['jobs@devcongress.org'], mail.from
    assert_equal ['jobs@devcongress.org'], mail.reply_to

    mail_body = mail.body.encoded
    assert_match job.role,                      mail_body
    assert_match job_url(job),                  mail_body
    assert_match "#{Job.validity_period} days", mail_body
  end
end
