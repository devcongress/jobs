require "test_helper"

class IndividualPostingTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @poster = create_profile!(name: "Kwame Mensah", handle: "kwame", visibility: :everyone)
    Admin.create!(email: "admin@example.com", status: :verified)
  end

  test "a developer posts a gig as themselves" do
    login_user(@poster.user)

    assert_difference -> { Company.count } => 1 do
      post "/post-as-yourself"
    end
    space = Company.find_by!(personal_owner: @poster.user)
    assert_redirected_to "/company/kwame-personal/hiring/job_posts/new"
    assert_equal "Kwame Mensah (personal)", space.to_label

    # Using it again reuses the same space.
    assert_no_difference -> { Company.count } do
      post "/post-as-yourself"
    end

    post "/company/kwame-personal/hiring/job_posts", params: {hiring_job_post: {
      title: "Landing page for a bakery", description: "Menu and contact form.", employment_type: "freelance",
      pay_period: "fixed", salary_min: "500", salary_currency: "USD", duration: "2 weeks", accepts_applications: "1"
    }}
    gig = space.job_posts.find_by!(title: "Landing page for a bakery")
    assert_equal "500 USD fixed budget", gig.pay

    # Editing can't switch it to another type; the form names the type instead.
    get "/company/kwame-personal/hiring/job_posts/#{gig.id}/edit"
    assert_select "[name='hiring_job_post[employment_type]']", count: 0
    assert_includes response.body, "What you&#39;re posting: Freelance / gig"
    patch "/company/kwame-personal/hiring/job_posts/#{gig.id}", params: {hiring_job_post: {title: "Landing page for a bakery, v2", employment_type: "full_time"}}
    assert_equal ["Landing page for a bakery, v2", "freelance"], gig.reload.values_at(:title, :employment_type)

    # A first post from an individual is reviewed like a new company's.
    assert_enqueued_email_with Hiring::JobReviewMailer, :review_requested, params: {job_post: gig} do
      post "/company/kwame-personal/hiring/job_posts/#{gig.id}/record_actions/publish"
    end
    assert gig.reload.pending_review?
    gig.approve!

    get "/jobs?kind=gigs"
    assert_includes response.body, "Landing page for a bakery"
    assert_includes response.body, "Kwame Mensah"

    get "/jobs?kind=internships"
    assert_not_includes response.body, "Landing page for a bakery"

    get "/jobs/#{gig.to_param}"
    assert_includes response.body, "This is your gig"
    assert_includes response.body, "About the poster"

    # There's no company page for a person; it goes to their profile, which lists the post.
    get "/companies/kwame-personal"
    assert_redirected_to "/@kwame"
    follow_redirect!
    assert_includes response.body, "Posted by Kwame"
  end

  test "the post form shows timing and pay fields that fit the type" do
    Company.personal_for!(@poster.user)
    login_user(@poster.user)

    get "/company/kwame-personal/hiring/job_posts/new"
    assert_response :success
    assert_select "[name='hiring_job_post[duration]']", count: 0
    assert_no_match ">Timing<", response.body
    assert_select "[name='hiring_job_post[paid]']", count: 0

    # Re-rendering with the type changed (what pre_submit does) brings them in.
    post "/company/kwame-personal/hiring/job_posts", params: {pre_submit: "true", hiring_job_post: {employment_type: "internship", paid: "0"}}
    assert_select "[name='hiring_job_post[duration]']"
    assert_select "[name='hiring_job_post[paid]']"
    assert_select "[name='hiring_job_post[salary_min]']", count: 0
  end

  test "individuals need a developer profile to post" do
    user = create_user!
    create_company!(owner: user, name: "Day Job Ltd")
    login_user(user)

    assert_no_difference -> { Company.count } do
      post "/post-as-yourself"
    end
    assert_redirected_to "/setup/developer/new"
  end

  test "people can't apply to their own gig, and others can" do
    space = Company.personal_for!(@poster.user)
    gig = create_job!(company: space, title: "Logo design", employment_type: :freelance, accepts_applications: true)

    own = gig.job_applications.new(profile: @poster)
    assert_not own.valid?
    assert_includes own.errors[:base], "You can't apply to your own post"

    assert gig.job_applications.new(profile: create_profile!(name: "Efua Asante")).valid?
  end

  test "personal spaces have no team invites" do
    space = Company.personal_for!(@poster.user)
    login_user(@poster.user)

    get "/company/kwame-personal"
    assert_response :success
    assert_includes response.body, "Posting as yourself"
    assert_not_includes response.body, "Pending invitations"

    post "/company/kwame-personal/company/record_actions/invite_user", params: {interaction: {email: "friend@example.com", role: "recruiter"}}
    assert_empty space.company_user_invites

    # The same request works for a real company the user owns.
    org = create_company!(owner: @poster.user, name: "Kwame Studio")
    post "/company/#{org.slug}/company/record_actions/invite_user", params: {interaction: {email: "friend@example.com", role: "recruiter"}}
    assert_equal ["friend@example.com"], org.company_user_invites.pluck(:email)
  end
end
