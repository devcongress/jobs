require 'test_helper'

class JobsMailerTest < ActionMailer::TestCase
  include Rails.application.routes.url_helpers

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  setup do
    @client = FactoryBot.create(:client)
    @job    = FactoryBot.create(:job, company: @client.company)
  end

  test "published" do
    mail   = JobsMailer.with(job: @job).published

    assert_equal "🎊 [Jobs] Your new job, #{@job.title}, has been published", mail.subject
    assert_equal [@client.user.email], mail.to
    assert_equal ["jobs@devcongress.org"], mail.from
    assert_equal ["jobs@devcongress.org"], mail.reply_to

    mail_body = mail.body.encoded
    assert_match @job.title,    mail_body
    assert_match root_url,     mail_body
    assert_match job_url(@job), mail_body
  end

  test "renewed" do
    mail   = JobsMailer.with(job: @job).renewed

    assert_equal "🎉 [Jobs] #{@job.title} has been renewed for another #{Job.validity_period} days", mail.subject
    assert_equal [@client.user.email], mail.to
    assert_equal ['jobs@devcongress.org'], mail.from
    assert_equal ['jobs@devcongress.org'], mail.reply_to

    mail_body = mail.body.encoded
    assert_match @job.title,                    mail_body
    assert_match job_url(@job),                 mail_body
    assert_match "#{Job.validity_period} days", mail_body
  end

  test "expires_soon" do
    mail = JobsMailer.with(job: @job).expires_soon

    assert_equal "📯 [Jobs] #{@job.title} expires in #{Job.days_to_expiry} days", mail.subject
    assert_equal [@client.user.email],     mail.to
    assert_equal ['jobs@devcongress.org'], mail.from
    assert_equal ['jobs@devcongress.org'], mail.reply_to

    mail_body = mail.body.encoded
    assert_match @job.title,                   mail_body
    assert_match job_url(@job),                mail_body
    assert_match "#{Job.days_to_expiry} days", mail_body
  end

  test "expired" do
  end
end
