# Email Notification Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Users can turn off network, job application and project credit emails, either from a settings page or with a one-click unsubscribe link in each email.

**Architecture:** An `email_opt_outs` table holds the categories each user has turned off; every category is on until then. Mailers send categorised emails through `categorized_mail(category, to: user, ...)`. It skips users who opted out and adds a signed unsubscribe link plus `List-Unsubscribe` headers. Two pages manage the settings: a public `/unsubscribe/:token` page in the site, and a settings page in the dashboard portal.

**Tech Stack:** Rails 8.1, Plutonium portals, Action Mailer, `ActiveSupport::MessageVerifier`, Minitest.

**User Verification:** NO. No user verification required.

**Spec:** `docs/superpowers/specs/2026-10-08-email-notifications-design.md`

---

## Conventions for every task

- **Running tests:** `bin/rails test` runs `css:build` first, which fails on Node 20 (PostCSS needs `Set#difference`, which needs Node 22 or newer). Run test files directly:
  ```bash
  bundle exec ruby -Itest -e 'ARGV.each { |f| require File.expand_path(f) }' <test files...>
  ```
  To run a single test, use `bundle exec ruby -Itest <file> -n "/pattern/"`.
- **Commits:** do not stage or commit. The user commits.
- **Style:**
  - Match the surrounding code: short "why" comments, and the `# add ... above.` section markers in models.
  - No defensive `respond_to?` checks.
  - Declare indexes inline in `create_table`.

## File map

| File | Responsibility |
|---|---|
| `db/migrate/20261008120000_create_email_opt_outs.rb` | Opt-out table |
| `app/models/email_opt_out.rb` | Categories, validation, unsubscribe tokens |
| `app/models/user.rb` | `wants_email?`, `opt_out_of_email!`, `update_email_opt_outs!` |
| `app/helpers/portal_paths_helper.rb` | `email_settings_dashboard_path` |
| `packages/dashboard_portal/config/routes.rb` | Settings route |
| `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb` | Settings page |
| `packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb` | Settings form |
| `app/views/shared/_user_topbar.html.erb` | "Email notifications" menu link |
| `config/routes.rb` | Unsubscribe routes |
| `app/controllers/site/unsubscribes_controller.rb` | Unsubscribe confirm and one-click |
| `app/views/site/unsubscribes/show.html.erb` | Unsubscribe page |
| `app/mailers/concerns/categorized_email.rb` | `categorized_mail` |
| `app/mailers/application_mailer.rb` | Includes the concern |
| `app/views/layouts/mailer.html.erb`, `mailer.text.erb` | Unsubscribe footer |
| `packages/network/app/mailers/network/follow_mailer.rb` | `network` category |
| `packages/showcase/app/mailers/showcase/contributor_mailer.rb` | `project_credits` category |
| `packages/hiring/app/mailers/hiring/job_application_mailer.rb` | `applications` category, per-user `received` |
| `packages/hiring/app/mailers/hiring/job_review_mailer.rb` | Per-user `approved` and `declined` |
| `packages/hiring/app/models/hiring/job_application.rb`, `job_post.rb` | Enqueue one email per company user |

---

### Task 1: Opt-out model and user API

**Goal:** Store opt-outs and expose `wants_email?`, `opt_out_of_email!`, `update_email_opt_outs!` and the unsubscribe tokens.

**Files:**
- Create: `db/migrate/20261008120000_create_email_opt_outs.rb`
- Create: `app/models/email_opt_out.rb`
- Modify: `app/models/user.rb`
- Test: `test/models/email_opt_out_test.rb`

**Acceptance Criteria:**
- [ ] Every category is on by default, and opting out is idempotent.
- [ ] Unknown categories are rejected.
- [ ] `update_email_opt_outs!` makes the user's opt-outs exactly the given list.
- [ ] Tokens resolve to `[user, category]`. A bad token, an unknown category or a missing user resolves to `nil`.

**Verify:** `bundle exec ruby -Itest test/models/email_opt_out_test.rb` → 4 runs, 0 failures

**Steps:**

- [ ] **Step 1: Write the failing test** `test/models/email_opt_out_test.rb`

```ruby
require "test_helper"

class EmailOptOutTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @user = create_user! }

  test "every category is on until the user opts out" do
    assert @user.wants_email?(:network)

    @user.opt_out_of_email!(:network)
    @user.opt_out_of_email!(:network)

    assert_not @user.wants_email?(:network)
    assert @user.wants_email?(:applications)
    assert_equal 1, @user.email_opt_outs.count
  end

  test "only known categories can be turned off" do
    assert_raises(ActiveRecord::RecordInvalid) { @user.opt_out_of_email!(:marketing) }
  end

  test "update_email_opt_outs! turns off exactly the given categories" do
    @user.opt_out_of_email!(:network)

    @user.update_email_opt_outs!(%w[applications project_credits])
    assert_equal %w[applications project_credits], @user.email_opt_outs.pluck(:category).sort

    @user.update_email_opt_outs!([])
    assert_empty @user.email_opt_outs
  end

  test "unsubscribe tokens resolve to their user and category" do
    assert_equal [@user, "network"], EmailOptOut.resolve(EmailOptOut.token_for(@user, :network))
    assert_nil EmailOptOut.resolve("garbage")
    assert_nil EmailOptOut.resolve(EmailOptOut.token_for(@user, :marketing))
    assert_nil EmailOptOut.resolve(EmailOptOut.token_for(User.new(id: 0), :network))
  end
end
```

- [ ] **Step 2: Run it.** It should fail with `NameError: uninitialized constant EmailOptOut`.

- [ ] **Step 3: Migration** `db/migrate/20261008120000_create_email_opt_outs.rb`

```ruby
# Categories of email a user has turned off. No row means the email is on.
class CreateEmailOptOuts < ActiveRecord::Migration[8.1]
  def change
    create_table :email_opt_outs do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :category, null: false
      t.datetime :created_at, null: false

      t.index %i[user_id category], unique: true
    end
  end
end
```

Run `bin/rails db:migrate`. `db/schema.rb` should now include `email_opt_outs`.

- [ ] **Step 4: Model** `app/models/email_opt_out.rb`

```ruby
# A category of email a user has turned off. Every category is on until the
# user opts out, from the email settings page or an unsubscribe link.
class EmailOptOut < ApplicationRecord
  CATEGORIES = {
    "network" => {label: "Network activity", description: "When someone follows you or you become connected."},
    "applications" => {label: "Job applications", description: "New applicants on your company's jobs, and updates on jobs you've applied to."},
    "project_credits" => {label: "Project credits", description: "When someone credits you on a project, or confirms a credit you gave them."}
  }.freeze

  belongs_to :user

  validates :category, inclusion: {in: CATEGORIES.keys}

  # Unsubscribe links carry the user and category in a signed token. It never
  # expires, so links in old emails keep working.
  def self.token_for(user, category)
    verifier.generate([user.id, category.to_s], purpose: :unsubscribe)
  end

  # The [user, category] a token was made for, or nil.
  def self.resolve(token)
    user_id, category = verifier.verified(token, purpose: :unsubscribe)
    user = User.find_by(id: user_id) if CATEGORIES.key?(category)
    [user, category] if user
  end

  # URL-safe, since the token goes in the link's path.
  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.key_generator.generate_key("email_opt_out"), url_safe: true)
  end
  private_class_method :verifier
end
```

- [ ] **Step 5: User API.** In `app/models/user.rb`, add the association after `has_many :companies, through: :company_users`:

```ruby
  has_many :email_opt_outs, dependent: :delete_all
```

Then add these methods after `onboarded?`, before `# add methods above.`:

```ruby
  # Categorised emails (see EmailOptOut::CATEGORIES) are on until turned off.
  def wants_email?(category)
    !email_opt_outs.exists?(category: category.to_s)
  end

  def opt_out_of_email!(category)
    email_opt_outs.create_or_find_by!(category: category.to_s)
  end

  # Turns off exactly these categories and turns the rest back on.
  def update_email_opt_outs!(categories)
    transaction do
      email_opt_outs.where.not(category: categories).delete_all
      categories.each { opt_out_of_email!(_1) }
    end
  end
```

- [ ] **Step 6: Run the test.** Expect 4 runs, 0 failures.

---

### Task 2: Email settings page

**Goal:** Signed-in users manage their categories at `/dashboard/settings/email`, which is linked from the user menu.

**Files:**
- Modify: `packages/dashboard_portal/config/routes.rb`
- Create: `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb`
- Create: `packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`
- Modify: `app/helpers/portal_paths_helper.rb`
- Modify: `app/views/shared/_user_topbar.html.erb`
- Test: `test/integration/email_settings_test.rb`

**Acceptance Criteria:**
- [ ] The page needs sign-in.
- [ ] It shows one checkbox per category, ticked when that category is on.
- [ ] Saving turns off the unticked categories and turns the ticked ones back on, then redirects back with a notice.
- [ ] The user menu links to the page.

**Verify:** `bundle exec ruby -Itest test/integration/email_settings_test.rb` → 4 runs, 0 failures

**Steps:**

- [ ] **Step 1: Write the failing test** `test/integration/email_settings_test.rb`

```ruby
require "test_helper"

class EmailSettingsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup { @user = create_profile!.user }

  test "needs sign-in" do
    get "/dashboard/settings/email"
    assert_response :redirect
  end

  test "shows every category, on by default" do
    login_user(@user)
    get "/dashboard/settings/email"

    assert_response :success
    assert_select "input[type=checkbox][name='email_settings[categories][]']", 3
    assert_select "input[type=checkbox][name='email_settings[categories][]'][checked]", 3
  end

  test "saving turns off unticked categories and back on ticked ones" do
    @user.opt_out_of_email!(:project_credits)
    login_user(@user)

    patch "/dashboard/settings/email", params: {email_settings: {categories: ["", "network", "project_credits"]}}

    assert_redirected_to "/dashboard/settings/email"
    assert_equal ["applications"], @user.email_opt_outs.pluck(:category)
  end

  test "the user menu links to the page" do
    login_user(@user)
    get "/dashboard"
    assert_select "a[href='/dashboard/settings/email']", /Email notifications/
  end
end
```

- [ ] **Step 2: Run it.** The tests should fail with 404s or routing errors.

- [ ] **Step 3: Route.** In `packages/dashboard_portal/config/routes.rb`, add this under `root to: "dashboard#index"`:

```ruby
  resource :email_settings, only: %i[show update], path: "settings/email"
```

- [ ] **Step 4: Controller** `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb`

```ruby
module DashboardPortal
  # Which categories of email the signed-in user gets.
  class EmailSettingsController < PlutoniumController
    def show
    end

    def update
      enabled = params.fetch(:email_settings, {}).permit(categories: [])[:categories].to_a
      current_user.update_email_opt_outs!(EmailOptOut::CATEGORIES.keys - enabled)
      redirect_to email_settings_path, notice: "Email settings saved."
    end
  end
end
```

- [ ] **Step 5: View** `packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`

The hidden empty value keeps the param present when every box is unticked.

```erb
<% content_for :title, "Email notifications" %>

<div class="mx-auto max-w-2xl space-y-6">
  <header>
    <h1 class="font-display text-3xl text-[var(--pu-text)]">Email notifications</h1>
    <p class="mt-1 text-[var(--pu-text-muted)]">Choose what we email <%= current_user.email %> about. Account and security emails, and updates on jobs you post, always come through.</p>
  </header>

  <%= form_with url: email_settings_path, method: :patch, class: "dc-card" do |form| %>
    <div class="pu-card-body space-y-5">
      <%= hidden_field_tag "email_settings[categories][]", "", id: nil %>
      <% EmailOptOut::CATEGORIES.each do |key, category| %>
        <label class="flex items-start gap-3">
          <%= check_box_tag "email_settings[categories][]", key, current_user.wants_email?(key), id: "email_category_#{key}", class: "mt-1 h-4 w-4 accent-primary-600" %>
          <span>
            <span class="block font-semibold text-[var(--pu-text)]"><%= category[:label] %></span>
            <span class="block text-sm text-[var(--pu-text-muted)]"><%= category[:description] %></span>
          </span>
        </label>
      <% end %>
      <%= form.submit "Save", class: "pu-btn pu-btn-primary" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 6: Path helper.** In `app/helpers/portal_paths_helper.rb`, add this after `home_dashboard_path`:

```ruby
  def email_settings_dashboard_path
    PortalPathsHelper.routes.dashboard_portal.email_settings_path
  end
```

- [ ] **Step 7: Menu link.** In `app/views/shared/_user_topbar.html.erb`, add this right after the "Change password" link block:

```erb
          section.with_link(label: "Email notifications", href: email_settings_dashboard_path) do |link|
            link.with_leading { render Phlex::TablerIcons::Mail.new(class: "mr-2 text-[var(--pu-text-subtle)] w-4 h-4") }
          end
```

- [ ] **Step 8: Run the test.** Expect 4 runs, 0 failures. Then run the portal access tests: `bundle exec ruby -Itest test/integration/portal_access_test.rb` should pass.

---

### Task 3: Unsubscribe page

**Goal:** `/unsubscribe/:token` asks before turning off one category, with no sign-in needed. A POST turns it off, and that includes mail clients' one-click POST.

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/site/unsubscribes_controller.rb`
- Create: `app/views/site/unsubscribes/show.html.erb`
- Test: `test/integration/email_unsubscribe_test.rb`

**Acceptance Criteria:**
- [ ] A GET shows a confirm page and changes nothing.
- [ ] A POST opts out of that category only. It works without sign-in or a CSRF token.
- [ ] Bad tokens get a 404.

**Verify:** `bundle exec ruby -Itest test/integration/email_unsubscribe_test.rb` → 4 runs, 0 failures

**Steps:**

- [ ] **Step 1: Write the failing test** `test/integration/email_unsubscribe_test.rb`

```ruby
require "test_helper"

class EmailUnsubscribeTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @user = create_user!
    @token = EmailOptOut.token_for(@user, :network)
  end

  test "opening the link asks before turning anything off" do
    get "/unsubscribe/#{@token}"

    assert_response :success
    assert_select "h1", /Turn off network activity emails/
    assert @user.wants_email?(:network)
  end

  test "confirming turns the category off without signing in" do
    post "/unsubscribe/#{@token}"

    assert_response :success
    assert_select "h1", /won't get network activity emails/
    assert_not @user.wants_email?(:network)
    assert @user.wants_email?(:applications)
  end

  test "mail clients can unsubscribe in one click, without a CSRF token" do
    ActionController::Base.allow_forgery_protection = true
    post "/unsubscribe/#{@token}", params: {"List-Unsubscribe" => "One-Click"}

    assert_response :success
    assert_not @user.wants_email?(:network)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "bad tokens are not found" do
    get "/unsubscribe/nope"
    assert_response :not_found

    post "/unsubscribe/nope"
    assert_response :not_found
  end
end
```

- [ ] **Step 2: Run it.** The tests should fail with routing errors.

- [ ] **Step 3: Routes.** In `config/routes.rb`, inside `scope module: :site do`, add after the `projects/:slug` line:

```ruby
    # Unsubscribe links in emails (no sign-in; the signed token names the user).
    get "unsubscribe/:token", to: "unsubscribes#show", as: :unsubscribe, format: false
    post "unsubscribe/:token", to: "unsubscribes#create", format: false
```

- [ ] **Step 4: Controller** `app/controllers/site/unsubscribes_controller.rb`

```ruby
# Unsubscribe links from categorised emails. Opening the link only asks:
# link scanners follow GETs, so turning emails off takes a POST, which is also
# what mail clients send for one-click unsubscribe (with no CSRF token).
module Site
  class UnsubscribesController < BaseController
    skip_forgery_protection only: :create
    before_action :resolve_token

    def show
    end

    def create
      @user.opt_out_of_email!(@category)
      render :show
    end

    private

    def resolve_token
      @user, @category = EmailOptOut.resolve(params[:token])
      raise ActiveRecord::RecordNotFound unless @user
    end
  end
end
```

`Site::BaseController` already turns `ActiveRecord::RecordNotFound` into the site's 404 page.

- [ ] **Step 5: View** `app/views/site/unsubscribes/show.html.erb`

```erb
<% category = EmailOptOut::CATEGORIES.fetch(@category) %>
<% content_for :title, "Email settings" %>
<% content_for :noindex, true %>

<section class="dc-container max-w-2xl py-20 sm:py-28">
  <p class="dc-eyebrow">Email settings</p>
  <% if @user.wants_email?(@category) %>
    <h1 class="dc-heading text-4xl">Turn off <%= category[:label].downcase %> emails?</h1>
    <p class="mt-4 text-[#555]">We'll stop emailing <strong><%= @user.email %></strong> about this. <%= category[:description] %></p>
    <%= button_to "Turn them off", unsubscribe_path(token: params[:token]), class: "dc-btn dc-btn-primary mt-8", form: {data: {turbo: false}} %>
  <% else %>
    <h1 class="dc-heading text-4xl">You won't get <%= category[:label].downcase %> emails.</h1>
    <p class="mt-4 text-[#555]">We've stopped emailing <strong><%= @user.email %></strong> about this. Account and security emails still come through.</p>
  <% end %>
  <p class="mt-8 text-sm text-[#555]">Change any email setting from <%= link_to "your email settings", email_settings_dashboard_path, class: "underline" %> (you'll need to sign in).</p>
</section>
```

- [ ] **Step 6: Run the test.** Expect 4 runs, 0 failures.

---

### Task 4: Categorised mail, the footer, and the developer-facing mailers

**Goal:** `categorized_mail` skips users who opted out and adds the unsubscribe headers and footer. The follow, project credit and application status emails go through it.

**Files:**
- Create: `app/mailers/concerns/categorized_email.rb`
- Modify: `app/mailers/application_mailer.rb`
- Modify: `app/views/layouts/mailer.html.erb`
- Modify: `app/views/layouts/mailer.text.erb`
- Modify: `packages/network/app/mailers/network/follow_mailer.rb`
- Modify: `packages/showcase/app/mailers/showcase/contributor_mailer.rb`
- Modify: `packages/hiring/app/mailers/hiring/job_application_mailer.rb` (`status_changed` only)
- Test: `test/mailers/categorized_email_test.rb`

**Acceptance Criteria:**
- [ ] Categorised emails carry `List-Unsubscribe` and `List-Unsubscribe-Post`, plus an unsubscribe link and a settings link in both the HTML and text parts.
- [ ] Users who opted out of a category get no email for it: follow, credit invited, credit confirmed, application status.

**Verify:** `bundle exec ruby -Itest test/mailers/categorized_email_test.rb` → 4 runs, 0 failures

**Steps:**

- [ ] **Step 1: Write the failing test** `test/mailers/categorized_email_test.rb`

```ruby
require "test_helper"

class CategorizedEmailTest < ActionMailer::TestCase
  include AccountsTestHelper

  setup do
    @follower = create_profile!(name: "Ama Owusu")
    @followee = create_profile!(name: "Kofi Boateng")
    @follow = Network::Follow.create!(follower: @follower, followee: @followee)
  end

  test "categorised emails carry an unsubscribe link and one-click headers" do
    email = Network::FollowMailer.with(follow: @follow).followed
    token = EmailOptOut.token_for(@followee.user, :network)

    assert_match "/unsubscribe/#{token}", email["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].value
    assert_match "Turn off network activity emails", email.html_part.body.to_s
    assert_match "/unsubscribe/#{token}", email.html_part.body.to_s
    assert_match "/unsubscribe/#{token}", email.text_part.body.to_s
    assert_match "/dashboard/settings/email", email.text_part.body.to_s
  end

  test "follow emails respect the network setting" do
    @followee.user.opt_out_of_email!(:network)
    assert_emails(0) { Network::FollowMailer.with(follow: @follow).followed.deliver_now }
  end

  test "credit emails respect the project credits setting" do
    project = Showcase::Project.create!(owner: @follower, title: "Trotro Times")
    credit = project.contributors.create!(profile: @followee)

    @followee.user.opt_out_of_email!(:project_credits)
    assert_emails(0) { Showcase::ContributorMailer.with(contributor: credit).invited.deliver_now }

    @follower.user.opt_out_of_email!(:project_credits)
    assert_emails(0) { Showcase::ContributorMailer.with(contributor: credit).confirmed.deliver_now }
  end

  test "application status emails respect the applications setting" do
    company = create_company!(owner: create_user!)
    job = create_job!(company:, accepts_applications: true)
    application = job.job_applications.create!(profile: @followee)
    application.status = :shortlisted

    @followee.user.opt_out_of_email!(:applications)
    assert_emails(0) { Hiring::JobApplicationMailer.with(job_application: application, message: nil).status_changed.deliver_now }
  end
end
```

- [ ] **Step 2: Run it.** All 4 tests should fail: headers are missing and emails are still delivered.

- [ ] **Step 3: Concern** `app/mailers/concerns/categorized_email.rb`

```ruby
# Emails people can turn off by category (see EmailOptOut::CATEGORIES). Each
# goes to one user and is skipped if they've opted out. Everyone else gets an
# unsubscribe link in the footer and the one-click headers mail clients use.
module CategorizedEmail
  private

  def categorized_mail(category, to:, **)
    return unless to.wants_email?(category)

    @email_category = EmailOptOut::CATEGORIES.fetch(category.to_s)
    @unsubscribe_url = unsubscribe_url(token: EmailOptOut.token_for(to, category))
    @email_settings_url = absolute_url(PortalPathsHelper.routes.dashboard_portal.email_settings_path)
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    mail(to: to.email, **)
  end
end
```

In `app/mailers/application_mailer.rb`, add `include CategorizedEmail` below `helper EmailHelper`.

- [ ] **Step 4: Footers.** In `app/views/layouts/mailer.html.erb`, insert this between the `footer_note` paragraph and the links paragraph:

```erb
                <% if @unsubscribe_url %>
                  <p style="margin:0 0 8px;">
                    <a href="<%= @unsubscribe_url %>" style="color:<%= EmailHelper::MUTED %>;">Turn off <%= @email_category[:label].downcase %> emails</a> ·
                    <a href="<%= @email_settings_url %>" style="color:<%= EmailHelper::MUTED %>;">Email settings</a>
                  </p>
                <% end %>
```

Replace `app/views/layouts/mailer.text.erb` with:

```erb
<%= yield %>

--
<% if @unsubscribe_url -%>
Turn off <%= @email_category[:label].downcase %> emails: <%= @unsubscribe_url %>
Email settings: <%= @email_settings_url %>

<% end -%>
DevCongress Connect, where the DevCongress community connects
<%= root_url %>
```

- [ ] **Step 5: Switch the mailers.**

In `packages/network/app/mailers/network/follow_mailer.rb`, change the last line of `followed` to:

```ruby
      categorized_mail :network, to: @followee.user, subject:
```

In `packages/showcase/app/mailers/showcase/contributor_mailer.rb`:

```ruby
    def invited
      @confirm_url = absolute_url(developer_portal_credit_path(@profile, @contributor))
      @owner_url = absolute_url(Rails.application.routes.url_helpers.developer_page_path(handle: @owner.handle))
      categorized_mail :project_credits, to: @profile.user, subject: "#{@owner.name} credited you on #{@project.title}"
    end

    def confirmed
      @project_url = absolute_url(developer_portal_project_path(@owner, @project))
      categorized_mail :project_credits, to: @owner.user, subject: "#{@profile.name} confirmed they worked on #{@project.title}"
    end
```

In `packages/hiring/app/mailers/hiring/job_application_mailer.rb`, change the last line of `status_changed` to:

```ruby
      categorized_mail :applications, to: @profile.user, subject: status_subject
```

- [ ] **Step 6: Run the tests.**
  - The new test should report 4 runs, 0 failures.
  - These existing tests should still pass: `test/mailers/job_application_mailer_test.rb test/integration/network_test.rb test/integration/showcase_test.rb`.

---

### Task 5: One email per company user

**Goal:** "New applicant" emails go to each verified company user separately, and each one respects that user's `applications` setting. The essential "job approved" and "job declined" emails also go out one per user, without an unsubscribe link.

**Files:**
- Modify: `packages/hiring/app/mailers/hiring/job_application_mailer.rb` (`received`)
- Modify: `packages/hiring/app/mailers/hiring/job_review_mailer.rb`
- Modify: `packages/hiring/app/models/hiring/job_application.rb`
- Modify: `packages/hiring/app/models/hiring/job_post.rb`
- Modify: `test/mailers/job_application_mailer_test.rb`
- Modify: `test/models/hiring/job_review_test.rb`
- Modify: `test/mailers/previews/hiring_mailer_preview.rb`

**Acceptance Criteria:**
- [ ] Applying enqueues one `received` email per verified company user, each with `recipient:`.
- [ ] A company user who opted out of `applications` gets no `received` email.
- [ ] `approve!` and `decline!` enqueue one email per verified company user.
- [ ] Those emails have no `List-Unsubscribe` header.

**Verify:** `bundle exec ruby -Itest -e 'ARGV.each { |f| require File.expand_path(f) }' test/mailers/job_application_mailer_test.rb test/models/hiring/job_review_test.rb` → 0 failures

**Steps:**

- [ ] **Step 1: Update the tests.** In `test/mailers/job_application_mailer_test.rb`, replace the test `"applying emails the company"` with:

```ruby
  test "applying emails each verified company user" do
    teammate = create_user!
    @company.company_users.create!(user: teammate, role: :recruiter)

    application = nil
    assert_enqueued_emails 2 do
      application = @job.job_applications.create!(profile: @profile, cover_note: "Keen to help!")
    end
    assert_enqueued_email_with Hiring::JobApplicationMailer, :received, params: {job_application: application, recipient: teammate}

    email = Hiring::JobApplicationMailer.with(job_application: application, recipient: @recruiter).received
    assert_equal [@recruiter.email], email.to
    assert_equal "New applicant for Rails Engineer: Kwame Mensah", email.subject
    assert_match "Keen to help!", email.text_part.body.to_s
    assert_match "/company/acme-labs/hiring/job_applications/#{application.id}", email.html_part.body.to_s
    assert_match "/@kwame", email.html_part.body.to_s
    assert_match "/unsubscribe/", email["List-Unsubscribe"].value
  end

  test "company users who turned off application emails aren't told about applicants" do
    application = @job.job_applications.create!(profile: @profile)
    @recruiter.opt_out_of_email!(:applications)

    assert_emails(0) { Hiring::JobApplicationMailer.with(job_application: application, recipient: @recruiter).received.deliver_now }
  end
```

In `test/models/hiring/job_review_test.rb`:
- Change `params: {job_post: job}` on the `:approved` assertion to `params: {job_post: job, recipient: @owner}`.
- Change `params: {job_post: job, reason: "Add a salary range"}` to `params: {job_post: job, recipient: @owner, reason: "Add a salary range"}`.
- In `"review emails go to the right people"`, replace everything from `job.approve!` to the end of the test with:

```ruby
    job.approve!
    @owner.opt_out_of_email!(:applications)
    email = Hiring::JobReviewMailer.with(job_post: job, recipient: @owner).approved
    assert_equal [@owner.email], email.to
    assert_match "/jobs/#{job.to_param}", email.text_part.body.to_s
    assert_nil email["List-Unsubscribe"]

    email = Hiring::JobReviewMailer.with(job_post: job, recipient: @owner, reason: "Needs a salary").declined
    assert_equal [@owner.email], email.to
    assert_match "Needs a salary", email.text_part.body.to_s
```

- [ ] **Step 2: Run them.** They should fail on the `recipient:` params and the enqueued counts.

- [ ] **Step 3: Mailers.** In `job_application_mailer.rb`, replace `received` with:

```ruby
    # Sent to each company user separately, so each can turn it off.
    def received
      @application_url = absolute_url(company_portal_application_path(@company, @application))
      @profile_url = absolute_url(Rails.application.routes.url_helpers.developer_page_path(handle: @profile.handle))
      categorized_mail :applications, to: params[:recipient], subject: "New applicant for #{@job.title}: #{@profile.name}"
    end
```

In `job_review_mailer.rb`:
- In `approved`, change the `mail` line to `mail to: params[:recipient].email, subject: "Your #{@job.kind_noun} is live: #{@job.title}"`.
- In `declined`, change it to `mail to: params[:recipient].email, subject: "Changes needed before #{@job.title} goes live"`.
- Delete the private `company_emails` method and the `private` keyword above it.
- Update the class comment to: `# Emails for the first-job review: admins are asked to review, and each company user hears back when its job is approved or declined.`

- [ ] **Step 4: Models.** In `job_application.rb`, replace

```ruby
  after_create_commit { Hiring::JobApplicationMailer.with(job_application: self).received.deliver_later }
```

with

```ruby
  after_create_commit :notify_company
```

and add this private method next to `notify_applicant`:

```ruby
  def notify_company
    job_post.company.users.verified.find_each do |recipient|
      Hiring::JobApplicationMailer.with(job_application: self, recipient:).received.deliver_later
    end
  end
```

In `job_post.rb`:
- In `approve!`, replace `Hiring::JobReviewMailer.with(job_post: self).approved.deliver_later` with `notify_company(:approved)`.
- In `decline!`, replace `Hiring::JobReviewMailer.with(job_post: self, reason:).declined.deliver_later` with `notify_company(:declined, reason:)`.
- Add this under `private` (line 220):

```ruby
  def notify_company(email, **params)
    company.users.verified.find_each do |recipient|
      Hiring::JobReviewMailer.with(job_post: self, recipient:, **params).public_send(email).deliver_later
    end
  end
```

- [ ] **Step 5: Previews.** In `test/mailers/previews/hiring_mailer_preview.rb`:

```ruby
  def job_approved = Hiring::JobReviewMailer.with(job_post: job, recipient: job.company.users.first!).approved

  def job_declined
    Hiring::JobReviewMailer.with(job_post: job, recipient: job.company.users.first!, reason: "Please add a salary range and say which city the hybrid days are in.").declined
  end

  def application_received
    Hiring::JobApplicationMailer.with(job_application: application, recipient: application.job_post.company.users.first!).received
  end
```

- [ ] **Step 6: Run the tests.** The Verify command should show 0 failures. Then run `test/integration/hiring_test.rb test/integration/individual_posting_test.rb test/integration/applicant_management_test.rb`, which should also show 0 failures.

---

### Task 6: Full suite and a manual check

**Goal:** The whole suite passes, and the pages and emails look right in development.

**Files:** none (verification only)

**Acceptance Criteria:**
- [ ] The full test suite passes.
- [ ] `standardrb` is clean on the changed files, if the project uses it (`bin/standardrb` or `bundle exec standardrb`).
- [ ] The settings page, the unsubscribe page and the mailer previews render.

**Verify:** `bundle exec ruby -Itest -e 'ARGV.each { |f| require File.expand_path(f) }' $(find test -name "*_test.rb")` → 0 failures, 0 errors

**Steps:**

- [ ] **Step 1:** Run the full suite with the Verify command, and fix any test that still assumes one shared email to the whole company.
- [ ] **Step 2:** Run the linter on the changed files.
- [ ] **Step 3:** With `bin/dev` running, open:
  - `/dashboard/settings/email` (signed in)
  - `/rails/mailers/network_mailer/new_follower`, to check the footer's unsubscribe link
  - that unsubscribe link, to check both the confirm and done states
