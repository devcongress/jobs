require "test_helper"

class OgImagesTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @public = create_profile!(name: "Pat Public", handle: "pat", visibility: :everyone)
    @members = create_profile!(name: "Mo Members", handle: "momo", visibility: :members)
    @company = create_company!(name: "Acme Labs")
    @job = create_job!(company: @company)
  end

  test "public records get a cacheable 1200x630 PNG" do
    ["/og/site.png", "/og/devs/pat.png", "/og/companies/#{@company.slug}.png", "/og/jobs/#{@job.id}.png"].each do |path|
      get path, params: {v: "abc"}

      assert_response :success, path
      assert_equal "image/png", response.media_type
      assert_match "immutable", response.headers["Cache-Control"]
      image = Vips::Image.new_from_buffer(response.body, "")
      assert_equal [1200, 630], [image.width, image.height], path
    end
  end

  test "records guests can't see have no card" do
    personal = Company.personal_for!(@public.user)
    draft = create_job!(company: @company, published: false)
    members_job = create_job!(company: @company, visibility: :members)

    ["/og/devs/momo.png", "/og/devs/nobody.png", "/og/companies/#{personal.slug}.png",
      "/og/jobs/#{draft.id}.png", "/og/jobs/#{members_job.id}.png"].each do |path|
      get path
      assert_response :not_found, path
    end
  end
end
