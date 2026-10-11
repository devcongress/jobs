require "test_helper"

class StructuredData::JobPostingTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @company = create_company!(name: "Acme Labs") }

  test "remote jobs say so and where applicants must be" do
    data = build(create_job!(company: @company, remote_ok: true, country: "Kenya"))

    assert_equal "TELECOMMUTE", data["jobLocationType"]
    assert_equal({"@type" => "Country", "name" => "Kenya"}, data["applicantLocationRequirements"])
  end

  test "on-site jobs have a place and no remote fields" do
    data = build(create_job!(company: @company, city: "Lagos", country: "Nigeria"))

    assert_equal({"@type" => "PostalAddress", "addressLocality" => "Lagos", "addressCountry" => "NG"}, data.dig("jobLocation", "address"))
    assert_nil data["jobLocationType"]
    assert_nil data["applicantLocationRequirements"]
  end

  test "salary maps the pay period, and is left out when there's nothing to say" do
    single = build(create_job!(company: @company, salary_min: 40, pay_period: :hour, salary_currency: "GHS"))
    assert_equal({"@type" => "MonetaryAmount", "currency" => "GHS", "value" => {"@type" => "QuantitativeValue", "unitText" => "HOUR", "value" => 40}}, single["baseSalary"])

    assert_nil build(create_job!(company: @company))["baseSalary"]
    assert_nil build(create_job!(company: @company, salary_min: 500, pay_period: :fixed))["baseSalary"]
    assert_nil build(create_job!(company: @company, employment_type: :internship, paid: false, salary_min: 100, duration: "3 months"))["baseSalary"]
  end

  test "maps employment types" do
    assert_equal "CONTRACTOR", build(create_job!(company: @company, employment_type: :freelance))["employmentType"]
    assert_equal "INTERN", build(create_job!(company: @company, employment_type: :internship))["employmentType"]
  end

  test "jobs that aren't live and public get nothing" do
    assert_nil build(create_job!(company: @company).tap(&:mark_filled!))
    assert_nil build(create_job!(company: @company, published: false))
    assert_nil build(create_job!(company: @company, visibility: :members))
    expired = create_job!(company: @company).tap { |job| job.update!(expires_at: 1.day.ago) }
    assert_nil build(expired)
  end

  private

  def build(job)
    controller = Site::JobsController.new
    controller.request = ActionDispatch::TestRequest.create
    StructuredData::JobPosting.new(job, view: controller.view_context).to_h
  end
end
