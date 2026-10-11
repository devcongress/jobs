# Slack Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-extended-cc:subagent-driven-development (recommended) or superpowers-extended-cc:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cross-post jobs to DevCongress Slack `#jobs` and keep them in sync, let people sign in with or connect Slack, and send notifications as Slack DMs with per-channel settings.

**Architecture:** A thin `Slack::Client` over `Net::HTTP`, behind a `Slack` module that holds config, with a fake client for tests. Jobs sync to `#jobs` from an `after_commit` callback and an hourly sweep. Sign in with Slack is a small OmniAuth OAuth2 strategy for Slack's OpenID Connect endpoints, plugged into the existing rodauth-omniauth setup. `email_opt_outs` becomes `notification_opt_outs` with a `channel` column, and each categorised email gets a matching `SlackDm` class.

**Tech Stack:** Rails 8.1, SQLite, Solid Queue, Rodauth + rodauth-omniauth, omniauth-oauth2, Plutonium portals, Stimulus, Minitest.

**Spec:** `docs/superpowers/specs/2026-10-08-slack-integration-design.md`

**User Verification:** NO. No user verification required. (The user adds the Slack env vars later. Everything is tested against a fake client.)

**Deviations from the spec (decided while planning):**
- Sign in with Slack uses a ~30-line `OmniAuth::Strategies::SlackOpenid` built on the `omniauth-oauth2` gem that's already bundled, instead of adding `omniauth_openid_connect` (which would pull in `openid_connect`, `json-jwt`, `faraday` and more).
- The opt-out rename (spec phase 3) comes first in phase 2, because connecting Slack writes email opt-outs.
- rodauth-omniauth doesn't attach an identity to the signed-in account on its own (it looks accounts up by email). The callback hook loads the session account first, so "Connect Slack" links to whoever is signed in.
- The dismissible dashboard card uses a new `dismiss` Stimulus controller. `dismissable` already exists and closes `<details>` dropdowns.

**Conventions:**
- Run tests with `bin/rails test <path>`. Lint with `bundle exec standardrb <paths>`.
- Never `git add -A`. Stage the files each task lists.
- No Claude attribution in commits.
- Log with block syntax: `Rails.logger.warn { "..." }`.
- No `respond_to?` defensive checks.

---

## File map

**Phase 1 (`#jobs`)**
- Create `app/models/slack.rb`: config (`client`, `jobs_channel`, `team_id`, `invite_url`, `workspace_url`), `configured?`, `posts_jobs?`, `url(path)`, `escape(text)`
- Create `app/models/slack/client.rb`: `Slack::Client`, `Slack::Error`, `Slack::RateLimited`, `Slack::NETWORK_ERRORS`
- Create `test/support/slack.rb`: `Slack::FakeClient`, `SlackTestHelper`
- Create `db/migrate/20261008150000_add_slack_message_to_hiring_job_posts.rb`
- Create `packages/hiring/app/models/hiring/job_post_slack_message.rb`: Block Kit rendering
- Create `packages/hiring/app/jobs/hiring/slack_job_post_sync_job.rb`, `packages/hiring/app/jobs/hiring/slack_job_sweep_job.rb`
- Modify `packages/hiring/app/models/hiring/job_post.rb`: `after_commit` sync
- Modify `config/recurring.yml`, `app/views/site/jobs/show.html.erb`
- Tests: `test/models/slack_client_test.rb`, `test/models/hiring/job_post_slack_message_test.rb`, `test/jobs/hiring/slack_job_post_sync_job_test.rb`, `test/jobs/hiring/slack_job_sweep_job_test.rb`, `test/integration/slack_jobs_test.rb`

**Phase 2 (sign-in, connect, settings, prompts)**
- Rename `app/models/email_opt_out.rb` to `app/models/notification_opt_out.rb`. Migration `db/migrate/20261008150100_rename_email_opt_outs_to_notification_opt_outs.rb`
- Modify `app/models/user.rb`, `app/mailers/concerns/categorized_email.rb`, `app/controllers/site/unsubscribes_controller.rb`, `app/views/site/unsubscribes/show.html.erb`, `app/helpers/portal_paths_helper.rb`, `app/views/shared/_user_topbar.html.erb`, `app/views/layouts/mailer.{html,text}.erb`
- Create `lib/omniauth/strategies/slack_openid.rb`. Modify `config/application.rb` (autoload ignore), `app/rodauth/user_rodauth_plugin.rb`, `app/views/rodauth/user/_social_sign_in.html.erb`
- Replace `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb` with `notification_settings_controller.rb`. Create `slack_connections_controller.rb`. Views under `packages/dashboard_portal/app/views/dashboard_portal/notification_settings/`. Modify `packages/dashboard_portal/config/routes.rb`
- Create `app/views/shared/_slack_card.html.erb`, `app/javascript/controllers/dismiss_controller.js`. Modify `app/javascript/controllers/index.js`, the dashboard index, the footer, and the developer show page
- Modify `.env.test.local`, `.env.template`, `.env.production.template`, `.kamal/secrets`, `config/deploy.yml`, `README.md`

**Phase 3 (DMs)**
- Create `app/models/slack_dm.rb`, `app/jobs/slack_dm_job.rb`
- Create `packages/network/app/models/network/followed_dm.rb`, `packages/hiring/app/models/hiring/application_received_dm.rb`, `packages/hiring/app/models/hiring/application_status_changed_dm.rb`, `packages/showcase/app/models/showcase/credit_invited_dm.rb`, `packages/showcase/app/models/showcase/credit_confirmed_dm.rb`
- Modify the call sites in `network/follow.rb`, `hiring/job_application.rb`, `showcase/project_contributor.rb`. `JobApplication#status_update_subject` moves out of the mailer

---

## Phase 1: `#jobs` cross-posting

### Task 1: Slack config, API client and test fake

**Goal:** A `Slack` module that knows whether Slack is configured, a client for the three API methods, and a fake for tests.

**Files:**
- Create: `app/models/slack.rb`
- Create: `app/models/slack/client.rb`
- Create: `test/support/slack.rb`
- Test: `test/models/slack_client_test.rb`

**Acceptance Criteria:**
- [ ] `Slack.configured?` is false with no `SLACK_BOT_TOKEN` and true once a client is set
- [ ] `Slack.posts_jobs?` needs both a client and a jobs channel
- [ ] `Slack::Client` form-encodes params (blocks as JSON), sends the bearer token, and returns the parsed body
- [ ] `ok: false` raises `Slack::Error` with `#code`. HTTP 429 raises `Slack::RateLimited` with `#retry_after`
- [ ] `Slack.escape` escapes `&`, `<` and `>`. `Slack.url` builds absolute URLs from the mailer host

**Verify:** `bin/rails test test/models/slack_client_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the test support (fake client and helper)**

`test/support/slack.rb`:

```ruby
module Slack
  # Records API calls instead of making them. fail_next makes the next call to
  # a method raise the given Slack error code.
  class FakeClient
    Call = Struct.new(:method, :params)

    attr_reader :calls

    def initialize
      @calls = []
      @failures = {}
      @sequence = 0
    end

    def fail_next(method, code)
      @failures[method] = code
    end

    def post_message(**params)
      record(:post_message, params)
      {"ok" => true, "ts" => "1700000000.#{format("%06d", @sequence += 1)}", "channel" => params[:channel]}
    end

    def update_message(**params)
      record(:update_message, params)
      {"ok" => true, "ts" => params[:ts]}
    end

    def permalink(channel:, ts:)
      record(:permalink, {channel:, ts:})
      "https://devcongress-community.slack.com/archives/#{channel}/p#{ts.delete(".")}"
    end

    def calls_to(method) = calls.select { _1.method == method }

    private

    def record(method, params)
      code = @failures.delete(method)
      raise Slack::Error.new(code) if code

      @calls << Call.new(method, params)
    end
  end
end

# Swaps in the fake client and a #jobs channel for the test.
module SlackTestHelper
  def self.included(base)
    base.setup do
      @slack = Slack::FakeClient.new
      Slack.client = @slack
      Slack.jobs_channel = "C0JOBS"
    end
    base.teardown do
      Slack.client = nil
      Slack.jobs_channel = nil
    end
  end
end
```

- [ ] **Step 2: Write the failing client test**

`test/models/slack_client_test.rb`:

```ruby
require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body, :headers) do
    def [](name) = headers[name]
  end

  # A client whose HTTP call returns a canned response and remembers the request.
  def client_returning(code: "200", body: {ok: true}, headers: {})
    Class.new(Slack::Client) do
      attr_reader :request

      define_method(:http_post) do |uri, form, headers_sent|
        @request = {uri:, form:, headers: headers_sent}
        Response.new(code, body.to_json, headers)
      end
    end.new("xoxb-test")
  end

  test "posts form-encoded params with the bot token" do
    client = client_returning(body: {ok: true, ts: "1.2"})
    result = client.post_message(channel: "C1", text: "Hi", blocks: [{type: "divider"}])

    assert_equal "1.2", result["ts"]
    assert_equal "https://slack.com/api/chat.postMessage", client.request[:uri].to_s
    assert_equal "Bearer xoxb-test", client.request[:headers]["Authorization"]
    form = URI.decode_www_form(client.request[:form]).to_h
    assert_equal "C1", form["channel"]
    assert_equal [{"type" => "divider"}], JSON.parse(form["blocks"])
    assert_equal "false", form["unfurl_links"]
  end

  test "update and permalink call their methods" do
    client = client_returning(body: {ok: true, permalink: "https://x.slack.com/p1"})
    assert_equal "https://x.slack.com/p1", client.permalink(channel: "C1", ts: "1.2")
    assert_equal "1.2", URI.decode_www_form(client.request[:form]).to_h["message_ts"]

    client.update_message(channel: "C1", ts: "1.2", text: "Edited")
    assert_equal "https://slack.com/api/chat.update", client.request[:uri].to_s
  end

  test "Slack errors raise with their code" do
    error = assert_raises(Slack::Error) { client_returning(body: {ok: false, error: "channel_not_found"}).post_message(channel: "C1", text: "x") }
    assert_equal "channel_not_found", error.code
  end

  test "rate limits raise with the wait" do
    client = client_returning(code: "429", body: {ok: false, error: "ratelimited"}, headers: {"Retry-After" => "30"})
    error = assert_raises(Slack::RateLimited) { client.post_message(channel: "C1", text: "x") }
    assert_equal 30, error.retry_after
  end

  test "configuration" do
    Slack.client = nil
    Slack.jobs_channel = nil
    assert_not Slack.configured?
    assert_not Slack.posts_jobs?

    Slack.client = Slack::FakeClient.new
    assert Slack.configured?
    assert_not Slack.posts_jobs?

    Slack.jobs_channel = "C0JOBS"
    assert Slack.posts_jobs?
  ensure
    Slack.client = nil
    Slack.jobs_channel = nil
  end

  test "escape and url" do
    assert_equal "R&amp;D &lt;Lead&gt;", Slack.escape("R&D <Lead>")
    assert_equal "http://example.com/jobs/1", Slack.url("/jobs/1")
  end
end
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bin/rails test test/models/slack_client_test.rb`
Expected: FAIL/ERROR with `uninitialized constant Slack`

- [ ] **Step 4: Write `app/models/slack.rb`**

```ruby
# The DevCongress Slack workspace. Each piece switches itself on when its env
# vars are set: SLACK_BOT_TOKEN for #jobs posts and DMs, SLACK_JOBS_CHANNEL_ID
# for #jobs, SLACK_CLIENT_ID/SECRET and SLACK_TEAM_ID for sign-in (see
# UserRodauthPlugin), SLACK_INVITE_URL and SLACK_WORKSPACE_URL for links.
module Slack
  class << self
    attr_writer :client, :jobs_channel

    def client
      @client ||= (Client.new(ENV["SLACK_BOT_TOKEN"]) if ENV["SLACK_BOT_TOKEN"].present?)
    end

    def jobs_channel
      @jobs_channel ||= ENV["SLACK_JOBS_CHANNEL_ID"].presence
    end

    def team_id = ENV["SLACK_TEAM_ID"].presence

    def invite_url = ENV["SLACK_INVITE_URL"].presence

    def workspace_url = ENV["SLACK_WORKSPACE_URL"].presence

    def configured? = client.present?

    def posts_jobs? = configured? && jobs_channel.present?

    # Turns an app path (including portal engine paths) into a full URL.
    def url(path)
      Rails.application.routes.url_helpers.root_url(**ActionMailer::Base.default_url_options).chomp("/") + path
    end

    # Slack mrkdwn treats &, < and > as control characters.
    def escape(text)
      text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end
  end
end
```

- [ ] **Step 5: Write `app/models/slack/client.rb`**

```ruby
module Slack
  class Error < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
      super("Slack API error: #{code}")
    end
  end

  class RateLimited < Error
    attr_reader :retry_after

    def initialize(retry_after)
      @retry_after = retry_after
      super("ratelimited")
    end
  end

  # Connection failures worth retrying.
  NETWORK_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError].freeze

  # The few Web API methods we use, called with the bot token.
  class Client
    BASE_URL = "https://slack.com/api/"

    def initialize(token)
      @token = token
    end

    def post_message(channel:, text:, blocks: nil)
      call("chat.postMessage", channel:, text:, blocks:, unfurl_links: false)
    end

    def update_message(channel:, ts:, text:, blocks: nil)
      call("chat.update", channel:, ts:, text:, blocks:)
    end

    def permalink(channel:, ts:)
      call("chat.getPermalink", channel:, message_ts: ts).fetch("permalink")
    end

    private

    def call(method, **params)
      params[:blocks] = params[:blocks].to_json if params[:blocks]
      response = http_post(URI("#{BASE_URL}#{method}"), URI.encode_www_form(params.compact),
        "Authorization" => "Bearer #{@token}", "Content-Type" => "application/x-www-form-urlencoded")
      raise RateLimited.new(response["Retry-After"].to_i) if response.code == "429"

      body = JSON.parse(response.body)
      raise Error.new(body["error"]) unless body["ok"]

      body
    end

    def http_post(uri, form, headers)
      Net::HTTP.post(uri, form, headers)
    end
  end
end
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `bin/rails test test/models/slack_client_test.rb`
Expected: 6 runs, 0 failures

- [ ] **Step 7: Lint and commit**

```bash
bundle exec standardrb app/models/slack.rb app/models/slack/client.rb test/support/slack.rb test/models/slack_client_test.rb
git add app/models/slack.rb app/models/slack/client.rb test/support/slack.rb test/models/slack_client_test.rb
git commit -m "feat(slack): add Slack config and API client"
```

---

### Task 2: Job post Slack columns and message rendering

**Goal:** Store the `#jobs` message on each job, and render live and closed job messages as Block Kit.

**Files:**
- Create: `db/migrate/20261008150000_add_slack_message_to_hiring_job_posts.rb`
- Create: `packages/hiring/app/models/hiring/job_post_slack_message.rb`
- Modify: `db/schema.rb` (via migrate), and the `packages/hiring/app/models/hiring/job_post.rb` annotation (via annotate)
- Test: `test/models/hiring/job_post_slack_message_test.rb`

**Acceptance Criteria:**
- [ ] `hiring_job_posts` has `slack_message_ts`, `slack_posted_status` and `slack_message_url` (strings, nullable)
- [ ] The live message links the title to the public job URL and lists type, seniority, location, pay and timing when present, then an excerpt and a "View & apply" button
- [ ] The closed message strikes through the title, shows "Filled", "Expired" or "No longer available", and has no button
- [ ] User text is escaped

**Verify:** `bin/rails test test/models/hiring/job_post_slack_message_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the migration and run it**

```ruby
# Where a job's #jobs message lives, and which status it last showed.
class AddSlackMessageToHiringJobPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :hiring_job_posts, :slack_message_ts, :string
    add_column :hiring_job_posts, :slack_message_url, :string
    add_column :hiring_job_posts, :slack_posted_status, :string
  end
end
```

Run: `bin/rails db:migrate && RAILS_ENV=test bin/rails db:prepare`
Expected: `db/schema.rb` gains the three columns. If the annotate task runs on migrate, the `job_post.rb` header updates too.

- [ ] **Step 2: Write the failing test**

`test/models/hiring/job_post_slack_message_test.rb`:

```ruby
require "test_helper"

class Hiring::JobPostSlackMessageTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup do
    @company = create_company!(name: "Acme & Co")
    @job = create_job!(company: @company, title: "Senior <Rails> Engineer", seniority: :senior, city: "Accra", country: "GH",
      remote_ok: true, salary_min: 5000, salary_max: 8000, pay_period: :month,
      description: "## About\nYou'll **build** the payments platform for West Africa.")
  end

  test "live message" do
    message = Hiring::JobPostSlackMessage.new(@job)
    url = "http://example.com/jobs/#{@job.to_param}"

    assert_equal "New job at Acme & Co: Senior <Rails> Engineer", message.text
    header, excerpt, actions = message.blocks
    assert_equal "*<#{url}|Senior &lt;Rails&gt; Engineer>* · Acme &amp; Co\nFull time · Senior · Accra, GH · Remote · 5,000 – 8,000 USD per month", header.dig(:text, :text)
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

    assert_equal "Filled: Senior <Rails> Engineer at Acme & Co", message.text
    assert_equal 1, message.blocks.size
    assert_equal "~Senior &lt;Rails&gt; Engineer~ · Acme &amp; Co\n*Filled*", message.blocks.first.dig(:text, :text)

    assert_match "*Expired*", Hiring::JobPostSlackMessage.new(@job, closed_as: "expired").blocks.first.dig(:text, :text)
    assert_match "*No longer available*", Hiring::JobPostSlackMessage.new(@job, closed_as: "withdrawn").blocks.first.dig(:text, :text)
  end
end
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `bin/rails test test/models/hiring/job_post_slack_message_test.rb`
Expected: ERROR `uninitialized constant Hiring::JobPostSlackMessage`

- [ ] **Step 4: Write the renderer**

`packages/hiring/app/models/hiring/job_post_slack_message.rb`:

```ruby
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
        "#{CLOSED_LABELS.fetch(@closed_as)}: #{@job.title} at #{@job.poster_name}"
      else
        "New #{@job.kind_noun} at #{@job.poster_name}: #{@job.title}"
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
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bin/rails test test/models/hiring/job_post_slack_message_test.rb`
Expected: 3 runs, 0 failures. If the pay string or location format differs (e.g. `Accra, GH` vs a country name), adjust the **expected string** to match `JobPost#location`/`#pay` output. Don't change those methods.

- [ ] **Step 6: Lint and commit**

```bash
bundle exec standardrb packages/hiring/app/models/hiring/job_post_slack_message.rb test/models/hiring/job_post_slack_message_test.rb db/migrate/20261008150000_add_slack_message_to_hiring_job_posts.rb
git add db/migrate/20261008150000_add_slack_message_to_hiring_job_posts.rb db/schema.rb packages/hiring/app/models/hiring/job_post.rb packages/hiring/app/models/hiring/job_post_slack_message.rb test/models/hiring/job_post_slack_message_test.rb
git commit -m "feat(hiring): render jobs as Slack messages"
```

---

### Task 3: Sync jobs to `#jobs`

**Goal:** Post, update, close and repost a job's `#jobs` message as the job changes.

**Files:**
- Create: `packages/hiring/app/jobs/hiring/slack_job_post_sync_job.rb`
- Modify: `packages/hiring/app/models/hiring/job_post.rb` (constant and callback)
- Test: `test/jobs/hiring/slack_job_post_sync_job_test.rb`

**Acceptance Criteria:**
- [ ] Active with no message: posts, then stores ts, permalink and `active`
- [ ] Active with an active message: updates in place
- [ ] Active with a closed message (renewed or reopened): posts a new message and leaves the old one alone
- [ ] Filled, expired or archived with an active message: updates to closed and stores the status
- [ ] Draft or pending review with an active message: updates to closed as `withdrawn`
- [ ] `message_not_found` on update: clears the message, and reposts if active
- [ ] Other Slack errors are logged and discarded. Network errors retry. Rate limits retry after `Retry-After`
- [ ] Saving a job enqueues a sync only when Slack posts jobs and a relevant field changed

**Verify:** `bin/rails test test/jobs/hiring/slack_job_post_sync_job_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing test**

`test/jobs/hiring/slack_job_post_sync_job_test.rb`:

```ruby
require "test_helper"

class Hiring::SlackJobPostSyncJobTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  setup do
    @company = create_company!(name: "Acme")
    @job = create_job!(company: @company)
    clear_enqueued_jobs
  end

  def sync = Hiring::SlackJobPostSyncJob.perform_now(@job.reload)

  test "an active job is posted and remembered" do
    sync

    post = @slack.calls_to(:post_message).sole
    assert_equal "C0JOBS", post.params[:channel]
    @job.reload
    assert_equal "active", @job.slack_posted_status
    assert_equal "1700000000.000001", @job.slack_message_ts
    assert_equal "https://devcongress-community.slack.com/archives/C0JOBS/p1700000000000001", @job.slack_message_url
  end

  test "edits to a live job update the message" do
    sync
    @job.update!(title: "Lead Engineer")
    sync

    update = @slack.calls_to(:update_message).sole
    assert_equal "1700000000.000001", update.params[:ts]
    assert_match "Lead Engineer", update.params[:text]
    assert_equal 1, @slack.calls_to(:post_message).size
  end

  test "filling, expiring and archiving close the message" do
    sync
    @job.mark_filled!
    sync
    assert_match "Filled", @slack.calls_to(:update_message).last.params[:text]
    assert_equal "filled", @job.reload.slack_posted_status

    other = create_job!(company: @company, title: "Other")
    Hiring::SlackJobPostSyncJob.perform_now(other)
    other.update_columns(expires_at: 1.minute.ago)
    Hiring::SlackJobPostSyncJob.perform_now(other.reload)
    assert_equal "expired", other.reload.slack_posted_status
  end

  test "a declined job is withdrawn" do
    sync
    @job.decline!("Needs a salary")
    sync
    assert_match "No longer available", @slack.calls_to(:update_message).last.params[:blocks].first.dig(:text, :text)
    assert_equal "withdrawn", @job.reload.slack_posted_status
  end

  test "reopening reposts and keeps the old message closed" do
    sync
    @job.mark_filled!
    sync
    @job.reopen!
    sync

    assert_equal 2, @slack.calls_to(:post_message).size
    assert_equal "1700000000.000002", @job.reload.slack_message_ts
    assert_equal "active", @job.slack_posted_status
  end

  test "drafts and closed jobs without a message are left alone" do
    draft = create_job!(company: @company, published: false)
    Hiring::SlackJobPostSyncJob.perform_now(draft)
    @job.mark_filled!
    sync
    assert_empty @slack.calls
  end

  test "a message deleted in Slack is reposted" do
    sync
    @slack.fail_next(:update_message, "message_not_found")
    @job.update!(title: "Lead Engineer")
    sync

    assert_equal 2, @slack.calls_to(:post_message).size
    assert_equal "1700000000.000002", @job.reload.slack_message_ts
  end

  test "a deleted message for a closed job is forgotten" do
    sync
    @slack.fail_next(:update_message, "message_not_found")
    @job.mark_filled!
    sync

    assert_nil @job.reload.slack_message_ts
    assert_nil @job.slack_posted_status
  end

  test "config errors are discarded" do
    @slack.fail_next(:post_message, "channel_not_found")
    assert_nothing_raised { sync }
    assert_nil @job.reload.slack_message_ts
  end

  test "saving a job enqueues a sync when relevant fields change" do
    assert_enqueued_with(job: Hiring::SlackJobPostSyncJob, args: [@job]) { @job.update!(title: "New title") }
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostSyncJob) { @job.update!(apply_url: "https://acme.example/jobs") }
  end

  test "nothing is enqueued when Slack isn't set up" do
    Slack.client = nil
    assert_no_enqueued_jobs(only: Hiring::SlackJobPostSyncJob) { @job.update!(title: "New title") }
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bin/rails test test/jobs/hiring/slack_job_post_sync_job_test.rb`
Expected: ERROR `uninitialized constant Hiring::SlackJobPostSyncJob`

- [ ] **Step 3: Write the job**

`packages/hiring/app/jobs/hiring/slack_job_post_sync_job.rb`:

```ruby
module Hiring
  # Makes a job's #jobs message match the job. It renders from the job's
  # current state, so running it twice is harmless. slack_posted_status
  # records what the message shows now.
  class SlackJobPostSyncJob < ApplicationJob
    queue_as :default
    limits_concurrency to: 1, key: ->(job_post) { job_post }

    # Config problems (bad token, bot not in the channel...) won't fix
    # themselves.
    discard_on Slack::Error do |job, error|
      Rails.logger.error { "#jobs sync for job post #{job.arguments.first.id} failed: #{error.code}" }
    end
    rescue_from(Slack::RateLimited) { |error| retry_job(wait: error.retry_after.seconds) }
    retry_on(*Slack::NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)

    def perform(job_post)
      @job = job_post
      status = job_post.status.to_s

      if status == "active"
        (job_post.slack_posted_status == "active") ? update_message : post_message
      elsif job_post.slack_posted_status == "active"
        close_message(%w[draft pending_review].include?(status) ? "withdrawn" : status)
      end
    end

    private

    def post_message
      message = JobPostSlackMessage.new(@job)
      ts = client.post_message(channel:, text: message.text, blocks: message.blocks).fetch("ts")
      @job.update_columns(slack_message_ts: ts, slack_message_url: client.permalink(channel:, ts:), slack_posted_status: "active")
    end

    def update_message
      edit(JobPostSlackMessage.new(@job))
    end

    def close_message(closed_as)
      edit(JobPostSlackMessage.new(@job, closed_as:)) && @job.update_columns(slack_posted_status: closed_as)
    end

    # Updates the message in place. If it was deleted in Slack, forget it,
    # and post a fresh one when the job is live.
    def edit(message)
      client.update_message(channel:, ts: @job.slack_message_ts, text: message.text, blocks: message.blocks)
    rescue Slack::Error => error
      raise unless error.code == "message_not_found"

      @job.update_columns(slack_message_ts: nil, slack_message_url: nil, slack_posted_status: nil)
      post_message if @job.active?
      false
    end

    def client = Slack.client

    def channel = Slack.jobs_channel
  end
end
```

Note: in `close_message`, `edit` returns the API body (truthy) on success and `false` after `message_not_found`, so the posted status is only written when the update landed.

- [ ] **Step 4: Add the callback to `Hiring::JobPost`**

In `packages/hiring/app/models/hiring/job_post.rb`, after `VALIDITY_PERIOD`:

```ruby
  # Changes to these show in the #jobs message (see Hiring::SlackJobPostSyncJob).
  SLACK_FIELDS = %w[
    published_at approved_at expires_at filled_at archived_at title description employment_type seniority
    salary_min salary_max salary_currency pay_period paid city country remote_ok duration starts_on
  ].freeze
```

After the `normalizes` line, add:

```ruby
  after_commit :sync_to_slack, on: %i[create update], if: -> { Slack.posts_jobs? && saved_changes.keys.intersect?(SLACK_FIELDS) }
```

In the private section, add:

```ruby
  def sync_to_slack
    Hiring::SlackJobPostSyncJob.perform_later(self)
  end
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bin/rails test test/jobs/hiring/slack_job_post_sync_job_test.rb`
Expected: 11 runs, 0 failures

- [ ] **Step 6: Run the hiring tests for regressions**

Run: `bin/rails test test/models/hiring test/integration/hiring_test.rb`
Expected: all pass (Slack isn't configured in those tests, so the callback does nothing)

- [ ] **Step 7: Lint and commit**

```bash
bundle exec standardrb packages/hiring/app/jobs/hiring/slack_job_post_sync_job.rb packages/hiring/app/models/hiring/job_post.rb test/jobs/hiring/slack_job_post_sync_job_test.rb
git add packages/hiring/app/jobs/hiring/slack_job_post_sync_job.rb packages/hiring/app/models/hiring/job_post.rb test/jobs/hiring/slack_job_post_sync_job_test.rb
git commit -m "feat(hiring): cross-post jobs to Slack #jobs and keep them in sync"
```

---

### Task 4: Expiry sweep and "Discuss in #jobs"

**Goal:** Close messages for jobs that expired, and link job pages to their Slack thread.

**Files:**
- Create: `packages/hiring/app/jobs/hiring/slack_job_sweep_job.rb`
- Modify: `config/recurring.yml`
- Modify: `app/views/site/jobs/show.html.erb` (aside, after the Apply section)
- Test: `test/jobs/hiring/slack_job_sweep_job_test.rb`, `test/integration/slack_jobs_test.rb`

**Acceptance Criteria:**
- [ ] The sweep enqueues a sync for each job whose message is `active` but whose `expires_at` has passed, and no others
- [ ] The sweep runs hourly in production
- [ ] A job page with a Slack message shows "Discuss in #jobs" linking to the permalink
- [ ] Signed-out visitors see "Join the DevCongress Slack" when `SLACK_INVITE_URL` is set

**Verify:** `bin/rails test test/jobs/hiring/slack_job_sweep_job_test.rb test/integration/slack_jobs_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing tests**

`test/jobs/hiring/slack_job_sweep_job_test.rb`:

```ruby
require "test_helper"

class Hiring::SlackJobSweepJobTest < ActiveJob::TestCase
  include AccountsTestHelper

  test "expired jobs still showing as live in Slack are synced" do
    company = create_company!
    expired = create_job!(company:, title: "Expired")
    expired.update_columns(expires_at: 1.hour.ago, slack_message_ts: "1.1", slack_posted_status: "active")
    live = create_job!(company:, title: "Live")
    live.update_columns(slack_message_ts: "1.2", slack_posted_status: "active")
    closed = create_job!(company:, title: "Already closed")
    closed.update_columns(expires_at: 1.hour.ago, slack_message_ts: "1.3", slack_posted_status: "expired")

    Hiring::SlackJobSweepJob.perform_now

    assert_enqueued_jobs 1, only: Hiring::SlackJobPostSyncJob
    assert_enqueued_with job: Hiring::SlackJobPostSyncJob, args: [expired]
  end
end
```

`test/integration/slack_jobs_test.rb`:

```ruby
require "test_helper"

class SlackJobsTest < ActionDispatch::IntegrationTest
  include AccountsTestHelper

  setup do
    @job = create_job!(company: create_company!)
  end

  test "a job posted to Slack links to its thread" do
    @job.update_columns(slack_message_ts: "1.1", slack_message_url: "https://devcongress-community.slack.com/archives/C0JOBS/p11")
    get "/jobs/#{@job.to_param}"
    assert_select "a[href='https://devcongress-community.slack.com/archives/C0JOBS/p11']", /Discuss in #jobs/
  end

  test "no Slack link without a message" do
    get "/jobs/#{@job.to_param}"
    assert_select "a", text: /Discuss in #jobs/, count: 0
  end

  test "signed-out visitors are invited to join Slack" do
    ENV["SLACK_INVITE_URL"] = "https://join.slack.com/t/devcongress/shared_invite/abc"
    get "/jobs/#{@job.to_param}"
    assert_select "a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /Join the DevCongress Slack/
  ensure
    ENV.delete("SLACK_INVITE_URL")
  end
end
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bin/rails test test/jobs/hiring/slack_job_sweep_job_test.rb test/integration/slack_jobs_test.rb`
Expected: the sweep test errors (constant missing). The link tests fail (no link).

- [ ] **Step 3: Write the sweep job**

`packages/hiring/app/jobs/hiring/slack_job_sweep_job.rb`:

```ruby
module Hiring
  # Jobs expire by time, so nothing saves them when they do. This closes their
  # #jobs messages (scheduled in config/recurring.yml).
  class SlackJobSweepJob < ApplicationJob
    queue_as :default

    def perform
      JobPost.where(slack_posted_status: "active").where(expires_at: ..Time.current).find_each do |job_post|
        SlackJobPostSyncJob.perform_later(job_post)
      end
    end
  end
end
```

- [ ] **Step 4: Schedule it**

In `config/recurring.yml`, under `production:`, add:

```yaml
  slack_job_sweep:
    class: Hiring::SlackJobSweepJob
    queue: default
    schedule: every hour at minute 20
    description: "Close #jobs Slack messages for jobs that have expired"
```

- [ ] **Step 5: Add the links to the job page**

In `app/views/site/jobs/show.html.erb`, right after the closing `</section>` of the Apply box (before `<section class="dc-box p-5">` that holds "About the poster"), insert:

```erb
      <% if job.slack_message_url.present? || (Slack.invite_url && !current_user) %>
        <section class="dc-box space-y-2 p-5">
          <% if job.slack_message_url.present? %>
            <%= link_to job.slack_message_url, target: "_blank", rel: "noopener", class: "flex items-center gap-2 text-sm font-semibold hover:text-[#e8117f]" do %>
              <%= render Phlex::TablerIcons::BrandSlack.new(class: "h-5 w-5") %> Discuss in #jobs
            <% end %>
          <% end %>
          <% if Slack.invite_url && !current_user %>
            <%= link_to "Join the DevCongress Slack", Slack.invite_url, target: "_blank", rel: "noopener", class: "block text-sm text-[#e8117f] hover:underline" %>
          <% end %>
        </section>
      <% end %>
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `bin/rails test test/jobs/hiring/slack_job_sweep_job_test.rb test/integration/slack_jobs_test.rb test/integration/public_site_test.rb`
Expected: all pass

- [ ] **Step 7: Lint and commit**

```bash
bundle exec standardrb packages/hiring/app/jobs/hiring/slack_job_sweep_job.rb test/jobs/hiring/slack_job_sweep_job_test.rb test/integration/slack_jobs_test.rb
git add packages/hiring/app/jobs/hiring/slack_job_sweep_job.rb config/recurring.yml app/views/site/jobs/show.html.erb test/jobs/hiring/slack_job_sweep_job_test.rb test/integration/slack_jobs_test.rb
git commit -m "feat(hiring): close expired jobs in Slack and link job pages to #jobs"
```

---

## Phase 2: Sign in and connect, settings, prompts

### Task 5: Notification opt-outs with a channel

**Goal:** Rename `EmailOptOut` to `NotificationOptOut` and add a `channel` (`email` or `slack`) to opt-outs and unsubscribe tokens.

**Files:**
- Create: `db/migrate/20261008150100_rename_email_opt_outs_to_notification_opt_outs.rb`
- Delete: `app/models/email_opt_out.rb`. Create: `app/models/notification_opt_out.rb`
- Modify: `app/models/user.rb`, `app/mailers/concerns/categorized_email.rb`, `app/controllers/site/unsubscribes_controller.rb`, `app/views/site/unsubscribes/show.html.erb`, `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb`, `packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`
- Delete: `test/models/email_opt_out_test.rb`. Create: `test/models/notification_opt_out_test.rb`
- Modify tests: `test/integration/email_settings_test.rb`, `test/integration/email_unsubscribe_test.rb`, `test/mailers/categorized_email_test.rb`, `test/models/hiring/job_review_test.rb`, and any other hit from `grep -rn "opt_out_of_email\|wants_email\|EmailOptOut\|email_opt_outs" app packages test`

**Acceptance Criteria:**
- [ ] The table is `notification_opt_outs` with `channel` (not null, default `email`) and a unique `[user_id, channel, category]` index. Existing rows become `email`
- [ ] `User#wants_notification?(category, via:)`, `#opt_out!(category, via:)` and `#update_opt_outs!(categories, via:)` replace the email-only methods
- [ ] Tokens carry `[user_id, channel, category]`. Old `[user_id, category]` tokens resolve as `email`
- [ ] The unsubscribe page says "emails" or "Slack DMs" to match the token's channel
- [ ] All existing email opt-out behaviour still passes

**Verify:** `bin/rails test test/models/notification_opt_out_test.rb test/integration/email_settings_test.rb test/integration/email_unsubscribe_test.rb test/mailers test/models/hiring` → all pass

**Steps:**

- [ ] **Step 1: Write the migration and run it**

```ruby
# Opt-outs now apply per channel: email, or Slack DMs.
class RenameEmailOptOutsToNotificationOptOuts < ActiveRecord::Migration[8.1]
  def change
    rename_table :email_opt_outs, :notification_opt_outs
    add_column :notification_opt_outs, :channel, :string, null: false, default: "email"
    remove_index :notification_opt_outs, %i[user_id category], unique: true
    add_index :notification_opt_outs, %i[user_id channel category], unique: true
  end
end
```

Run: `bin/rails db:migrate && RAILS_ENV=test bin/rails db:prepare`

- [ ] **Step 2: Write the failing model test**

`git rm test/models/email_opt_out_test.rb`, then create `test/models/notification_opt_out_test.rb`:

```ruby
require "test_helper"

class NotificationOptOutTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @user = create_user! }

  test "every category is on in every channel until the user opts out" do
    assert @user.wants_notification?(:network, via: :email)

    @user.opt_out!(:network, via: :email)
    @user.opt_out!(:network, via: :email)

    assert_not @user.wants_notification?(:network, via: :email)
    assert @user.wants_notification?(:network, via: :slack)
    assert @user.wants_notification?(:applications, via: :email)
    assert_equal 1, @user.notification_opt_outs.count
  end

  test "only known categories and channels" do
    assert_raises(ActiveRecord::RecordInvalid) { @user.opt_out!(:marketing, via: :email) }
    assert_raises(ActiveRecord::RecordInvalid) { @user.opt_out!(:network, via: :sms) }
  end

  test "update_opt_outs! turns off exactly the given categories in one channel" do
    @user.opt_out!(:network, via: :email)
    @user.opt_out!(:network, via: :slack)

    @user.update_opt_outs!(%w[applications project_credits], via: :email)
    assert_equal %w[applications project_credits], @user.notification_opt_outs.where(channel: "email").pluck(:category).sort
    assert_equal %w[network], @user.notification_opt_outs.where(channel: "slack").pluck(:category)

    @user.update_opt_outs!([], via: :email)
    assert_not @user.notification_opt_outs.exists?(channel: "email")
  end

  test "tokens resolve to their user, channel and category" do
    assert_equal [@user, "email", "network"], NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :email))
    assert_equal [@user, "slack", "network"], NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :slack))
    assert_nil NotificationOptOut.resolve("garbage")
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :marketing, via: :email))
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :sms))
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(User.new(id: 0), :network, via: :email))
  end

  test "tokens from emails sent before channels existed still work" do
    old_token = NotificationOptOut.send(:verifier).generate([@user.id, "network"], purpose: :unsubscribe)
    assert_equal [@user, "email", "network"], NotificationOptOut.resolve(old_token)
  end
end
```

- [ ] **Step 3: Run it to verify it fails**

Run: `bin/rails test test/models/notification_opt_out_test.rb`
Expected: ERROR `uninitialized constant NotificationOptOut`

- [ ] **Step 4: Write the model**

`git rm app/models/email_opt_out.rb`, then create `app/models/notification_opt_out.rb`:

```ruby
# A category of notification a user has turned off in one channel: email, or
# Slack DMs. Every category is on until the user opts out, from the
# notification settings page or an unsubscribe link. (Connecting Slack turns
# email off for every category, see User#slack_connected!.)
class NotificationOptOut < ApplicationRecord
  CATEGORIES = {
    "network" => {label: "Network activity", description: "When someone follows you or you become connected."},
    "applications" => {label: "Job applications", description: "New applicants on your company's jobs, and updates on jobs you've applied to."},
    "project_credits" => {label: "Project credits", description: "When someone credits you on a project, or confirms a credit you gave them."}
  }.freeze
  CHANNELS = {"email" => "emails", "slack" => "Slack DMs"}.freeze

  belongs_to :user

  validates :category, inclusion: {in: CATEGORIES.keys}
  validates :channel, inclusion: {in: CHANNELS.keys}

  # Unsubscribe links carry the user, channel and category in a signed token.
  # It never expires, so links in old emails keep working.
  def self.token_for(user, category, via:)
    verifier.generate([user.id, via.to_s, category.to_s], purpose: :unsubscribe)
  end

  # The [user, channel, category] a token was made for, or nil. Tokens made
  # before channels existed are [user_id, category] and mean email.
  def self.resolve(token)
    payload = verifier.verified(token, purpose: :unsubscribe)
    return unless payload

    user_id, channel, category = (payload.size == 2) ? [payload.first, "email", payload.last] : payload
    user = User.find_by(id: user_id) if CATEGORIES.key?(category) && CHANNELS.key?(channel)
    [user, channel, category] if user
  end

  # URL-safe, since the token goes in the link's path. The key name predates
  # the rename and must stay so old links verify.
  def self.verifier
    @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.key_generator.generate_key("email_opt_out"), url_safe: true)
  end
  private_class_method :verifier
end
```

- [ ] **Step 5: Update `User`**

In `app/models/user.rb`, replace `has_many :email_opt_outs, dependent: :delete_all` with:

```ruby
  has_many :notification_opt_outs, dependent: :delete_all
```

Replace the three methods `wants_email?`, `opt_out_of_email!` and `update_email_opt_outs!` (and their comments) with:

```ruby
  # Categorised notifications (see NotificationOptOut::CATEGORIES) are on in
  # each channel until turned off.
  def wants_notification?(category, via:)
    !notification_opt_outs.exists?(channel: via.to_s, category: category.to_s)
  end

  def opt_out!(category, via:)
    notification_opt_outs.create_or_find_by!(channel: via.to_s, category: category.to_s)
  end

  # Turns off exactly these categories in one channel and turns the rest back on.
  def update_opt_outs!(categories, via:)
    transaction do
      notification_opt_outs.where(channel: via.to_s).where.not(category: categories).delete_all
      categories.each { opt_out!(_1, via:) }
    end
    notification_opt_outs.reset
  end
```

- [ ] **Step 6: Update the callers**

`app/mailers/concerns/categorized_email.rb`:

```ruby
# Emails people can turn off by category (see NotificationOptOut::CATEGORIES).
# Each goes to one user and is skipped if they've opted out of it by email.
# Everyone else gets an unsubscribe link in the footer and the one-click
# headers mail clients use.
module CategorizedEmail
  private

  def categorized_mail(category, to:, **)
    return unless to.wants_notification?(category, via: :email)

    @email_category = NotificationOptOut::CATEGORIES.fetch(category.to_s)
    @unsubscribe_url = unsubscribe_url(token: NotificationOptOut.token_for(to, category, via: :email))
    @email_settings_url = absolute_url(PortalPathsHelper.routes.dashboard_portal.email_settings_path)
    headers["List-Unsubscribe"] = "<#{@unsubscribe_url}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"
    mail(to: to.email, **)
  end
end
```

(The settings path is renamed in Task 8.)

`app/controllers/site/unsubscribes_controller.rb`: change `create` and `resolve_token`:

```ruby
    def create
      @user.opt_out!(@category, via: @channel)
      render :show
    end

    private

    def resolve_token
      @user, @channel, @category = NotificationOptOut.resolve(params[:token])
      raise ActiveRecord::RecordNotFound unless @user
    end
```

Also update its header comment to say "Unsubscribe links from categorised emails and Slack DMs."

`app/views/site/unsubscribes/show.html.erb`:

```erb
<% category = NotificationOptOut::CATEGORIES.fetch(@category) %>
<% things = "#{category[:label].downcase} #{NotificationOptOut::CHANNELS.fetch(@channel)}" %>
<% content_for :title, "Notification settings" %>
<% content_for :noindex, true %>

<section class="dc-container max-w-2xl py-20 sm:py-28">
  <p class="dc-eyebrow">Notification settings</p>
  <% if @user.wants_notification?(@category, via: @channel) %>
    <h1 class="dc-heading text-4xl">Turn off <%= things %>?</h1>
    <p class="mt-4 text-[#555]">We'll stop <%= (@channel == "slack") ? "sending Slack DMs" : "emailing" %> <strong><%= @user.email %></strong> about this. <%= category[:description] %></p>
    <%= button_to "Turn them off", unsubscribe_path(token: params[:token]), class: "dc-btn dc-btn-primary mt-8", form: {data: {turbo: false}} %>
  <% else %>
    <h1 class="dc-heading text-4xl">You won't get <%= things %>.</h1>
    <p class="mt-4 text-[#555]">We've stopped <%= (@channel == "slack") ? "sending Slack DMs to" : "emailing" %> <strong><%= @user.email %></strong> about this. Account and security emails still come through.</p>
  <% end %>
  <p class="mt-8 text-sm text-[#555]">Change any notification setting from <%= link_to "your notification settings", email_settings_dashboard_path, class: "underline" %> (you'll need to sign in).</p>
</section>
```

`packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb` `update`:

```ruby
      current_user.update_opt_outs!(NotificationOptOut::CATEGORIES.keys - enabled, via: :email)
```

`packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`: replace `EmailOptOut::CATEGORIES` with `NotificationOptOut::CATEGORIES` and `current_user.wants_email?(key)` with `current_user.wants_notification?(key, via: :email)`.

- [ ] **Step 7: Update the existing tests**

Run `grep -rn "opt_out_of_email\|wants_email\|EmailOptOut\|email_opt_outs" app packages test lib config` and fix every hit:
- `user.opt_out_of_email!(:x)` → `user.opt_out!(:x, via: :email)`
- `user.wants_email?(:x)` → `user.wants_notification?(:x, via: :email)`
- `EmailOptOut.token_for(user, :x)` → `NotificationOptOut.token_for(user, :x, via: :email)`
- `@user.email_opt_outs.pluck(:category)` → `@user.notification_opt_outs.where(channel: "email").pluck(:category)`

Add to `test/integration/email_unsubscribe_test.rb`:

```ruby
  test "Slack DM links turn off the Slack channel only" do
    token = NotificationOptOut.token_for(@user, :network, via: :slack)
    get "/unsubscribe/#{token}"
    assert_select "h1", /Turn off network activity Slack DMs/

    post "/unsubscribe/#{token}"
    assert_not @user.wants_notification?(:network, via: :slack)
    assert @user.wants_notification?(:network, via: :email)
  end
```

- [ ] **Step 8: Run the tests**

Run: `bin/rails test test/models test/integration/email_settings_test.rb test/integration/email_unsubscribe_test.rb test/mailers`
Expected: all pass. The grep from Step 7 returns only the migration.

- [ ] **Step 9: Lint and commit**

```bash
bundle exec standardrb app/models/notification_opt_out.rb app/models/user.rb app/mailers/concerns/categorized_email.rb app/controllers/site/unsubscribes_controller.rb test/models/notification_opt_out_test.rb test/integration/email_unsubscribe_test.rb
git add -u app packages test db/schema.rb
git add db/migrate/20261008150100_rename_email_opt_outs_to_notification_opt_outs.rb app/models/notification_opt_out.rb test/models/notification_opt_out_test.rb
git commit -m "refactor(notifications): opt-outs per channel, ready for Slack DMs"
```

---

### Task 6: Sign in with Slack

**Goal:** "Continue with Slack" signs people in or up, locked to the DevCongress workspace and to verified emails.

**Files:**
- Create: `lib/omniauth/strategies/slack_openid.rb`
- Modify: `config/application.rb:19` (autoload ignore)
- Modify: `app/rodauth/user_rodauth_plugin.rb`
- Modify: `app/views/rodauth/user/_social_sign_in.html.erb`
- Modify: `.env.test.local`, `.env.template`, `.env.production.template`, `.kamal/secrets`, `config/deploy.yml`, `README.md`
- Test: `test/integration/social_sign_in_test.rb`

**Acceptance Criteria:**
- [ ] With `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` and `SLACK_TEAM_ID` set, the login and sign-up pages show "Continue with Slack" (POST `/users/auth/slack`)
- [ ] A callback from another workspace is refused with "That isn't the DevCongress Slack workspace." and links nothing
- [ ] An unverified Slack email is refused
- [ ] Signing up with Slack creates a verified account and an identity `slack/<user id>`, with name and avatar in `info`
- [ ] All six Slack env vars are documented and passed through deploy config

**Verify:** `bin/rails test test/integration/social_sign_in_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Add test credentials**

Append to `.env.test.local`:

```
SLACK_CLIENT_ID=test-slack-id
SLACK_CLIENT_SECRET=test-slack-secret
SLACK_TEAM_ID=T0DEVCON
SLACK_WORKSPACE_URL=https://devcongress-community.slack.com
```

- [ ] **Step 2: Write the failing tests**

In `test/integration/social_sign_in_test.rb`, add `OmniAuth.config.mock_auth.delete(:slack)` to `teardown`. Change the `mock` helper to accept a uid of any type (it already does). Add:

```ruby
  test "login and sign-up pages offer Slack" do
    get "/users/login"
    assert_select "form[action='/users/auth/slack'] button", text: /Continue with Slack/
  end

  test "signing up with Slack creates a verified account" do
    mock_slack(uid: "U123", email: "ama@example.com", info: {name: "Ama Mensah", image: "https://avatars.slack-edge.com/ama.png"})

    assert_difference -> { User.count } => 1 do
      sign_in_with(:slack)
    end

    user = User.find_by!(email: "ama@example.com")
    assert user.verified?
    identity = user.identities.sole
    assert_equal %w[slack U123], [identity.provider, identity.uid]
    assert_equal "Ama Mensah", identity.info["name"]
  end

  test "Slack sign-in from another workspace is refused" do
    mock_slack(uid: "U999", email: "someone@example.com", team: "T0OTHER")

    assert_no_difference -> { User.count } do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
    follow_redirect!
    assert_match "That isn't the DevCongress Slack workspace.", response.body
  end

  test "an unverified Slack email is refused" do
    create_user!(email: "victim@example.com")
    mock_slack(uid: "U998", email: "victim@example.com", email_verified: false)

    assert_no_difference -> { User::Identity.count } do
      sign_in_with(:slack)
    end
    assert_redirected_to "/users/login"
  end
```

Add to the private helpers:

```ruby
  def mock_slack(uid:, email:, team: "T0DEVCON", email_verified: true, info: {})
    mock(:slack, uid:, email:, info:, extra: {raw_info: {"https://slack.com/team_id" => team, "email_verified" => email_verified}})
  end
```

- [ ] **Step 3: Run them to verify they fail**

Run: `bin/rails test test/integration/social_sign_in_test.rb`
Expected: the new tests fail (no Slack button, `/users/auth/slack` 404s)

- [ ] **Step 4: Write the strategy**

`lib/omniauth/strategies/slack_openid.rb`:

```ruby
require "omniauth-oauth2"

module OmniAuth
  module Strategies
    # Sign in with Slack (OpenID Connect). The userInfo response carries the
    # Slack user id and the workspace in https://slack.com/* claims.
    class SlackOpenid < OmniAuth::Strategies::OAuth2
      option :name, "slack_openid"
      option :scope, "openid email profile"
      option :client_options, {
        site: "https://slack.com",
        authorize_url: "https://slack.com/openid/connect/authorize",
        token_url: "https://slack.com/api/openid.connect.token",
        auth_scheme: :request_body
      }
      # `team` sends people straight to the DevCongress workspace.
      option :authorize_options, %i[scope team]

      uid { raw_info.fetch("https://slack.com/user_id") }
      info { {email: raw_info["email"], name: raw_info["name"], image: raw_info["picture"]} }
      extra { {raw_info:} }

      def raw_info
        @raw_info ||= access_token.post("/api/openid.connect.userInfo").parsed
      end

      # Slack matches the redirect URI exactly, so leave off the query string.
      def callback_url = full_host + callback_path
    end
  end
end
```

In `config/application.rb`, change `config.autoload_lib(ignore: %w[assets tasks])` to:

```ruby
    config.autoload_lib(ignore: %w[assets tasks omniauth])
```

- [ ] **Step 5: Register the provider and add the checks**

In `app/rodauth/user_rodauth_plugin.rb`, add below `require "sequel/core"`:

```ruby
require Rails.root.join("lib/omniauth/strategies/slack_openid").to_s
```

Update the provider comment to also list `/users/auth/slack/callback`. After the GitHub provider block, add:

```ruby
    # Sign in with Slack, limited to the DevCongress workspace.
    if ENV["SLACK_CLIENT_ID"].present? && ENV["SLACK_CLIENT_SECRET"].present? && ENV["SLACK_TEAM_ID"].present?
      omniauth_provider :slack_openid, ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"], name: :slack, team: ENV["SLACK_TEAM_ID"]
    end
```

Replace the `before_omniauth_callback_route` block with:

```ruby
    before_omniauth_callback_route do
      if omniauth_provider.to_s == "slack" && omniauth_extra.dig("raw_info", "https://slack.com/team_id") != Slack.team_id
        set_redirect_error_flash "That isn't the DevCongress Slack workspace."
        redirect login_path
      end

      verified = case omniauth_provider.to_s
      when "google" then [true, "true"].include?(omniauth_extra.dig("raw_info", "email_verified"))
      when "github" then omniauth_email.present?
      when "slack" then [true, "true"].include?(omniauth_extra.dig("raw_info", "email_verified"))
      else false
      end

      unless verified
        set_redirect_error_flash "We couldn't confirm your email with #{omniauth_provider.to_s.titleize}. Verify it there, or sign up with email and password."
        redirect login_path
      end
    end
```

Update the comment above it to "(... Slack sends an email_verified claim, like Google.)".

- [ ] **Step 6: Add the button**

`app/views/rodauth/user/_social_sign_in.html.erb`: change the first two lines and the button body:

```erb
<%# "Continue with Google / GitHub / Slack", shown only for providers that have credentials configured. %>
<% providers = rodauth.omniauth_providers.map(&:to_s) & %w[google github slack] %>
```

```erb
        <% case provider %>
        <% when "google" %>
          <%= render Phlex::TablerIcons::BrandGoogle.new(class: "h-5 w-5") %> Continue with Google
        <% when "github" %>
          <%= render Phlex::TablerIcons::BrandGithub.new(class: "h-5 w-5") %> Continue with GitHub
        <% when "slack" %>
          <%= render Phlex::TablerIcons::BrandSlack.new(class: "h-5 w-5") %> Continue with Slack
        <% end %>
```

- [ ] **Step 7: Document and pass through the env vars**

`.env.template`: after the GitHub lines add:

```
# == Slack (optional; each piece works once its values are set)
# Sign in with Slack. Callback: <RAILS_DEFAULT_URL>/users/auth/slack/callback
# SLACK_CLIENT_ID=
# SLACK_CLIENT_SECRET=
# SLACK_TEAM_ID=
# Bot token (scope chat:write) for #jobs posts and DMs; the bot must be in #jobs.
# SLACK_BOT_TOKEN=
# SLACK_JOBS_CHANNEL_ID=
# SLACK_INVITE_URL=
# SLACK_WORKSPACE_URL=https://devcongress-community.slack.com
```

`.env.production.template`: add the same block, with the callback `https://connect.devcongress.org/users/auth/slack/callback`.

`config/deploy.yml` `env.clear`, after the GitHub line:

```yaml
    # Slack. Sign-in needs the id, secret and team; posts and DMs need the bot token.
    SLACK_CLIENT_ID: "<%= ENV["SLACK_CLIENT_ID"] %>"
    SLACK_TEAM_ID: "<%= ENV["SLACK_TEAM_ID"] %>"
    SLACK_JOBS_CHANNEL_ID: "<%= ENV["SLACK_JOBS_CHANNEL_ID"] %>"
    SLACK_INVITE_URL: "<%= ENV["SLACK_INVITE_URL"] %>"
    SLACK_WORKSPACE_URL: "<%= ENV["SLACK_WORKSPACE_URL"] %>"
```

`env.secret`: add `- SLACK_CLIENT_SECRET` and `- SLACK_BOT_TOKEN`.

`.kamal/secrets`, under "Social sign-in":

```
SLACK_CLIENT_SECRET=$SLACK_CLIENT_SECRET
SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN
```

`README.md` env table, after the GitHub row:

```markdown
| `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_TEAM_ID` | no | "Continue with Slack", limited to the DevCongress workspace. Callback: `https://connect.devcongress.org/users/auth/slack/callback` |
| `SLACK_BOT_TOKEN`, `SLACK_JOBS_CHANNEL_ID` | no | Bot token (scope `chat:write`) for `#jobs` cross-posts and notification DMs. Invite the bot to `#jobs` |
| `SLACK_INVITE_URL`, `SLACK_WORKSPACE_URL` | no | "Join Slack" links, and profile links such as `https://devcongress-community.slack.com` |
```

- [ ] **Step 8: Run the tests**

Run: `bin/rails test test/integration/social_sign_in_test.rb`
Expected: all pass, including the existing Google and GitHub tests

- [ ] **Step 9: Lint and commit**

```bash
bundle exec standardrb lib/omniauth/strategies/slack_openid.rb app/rodauth/user_rodauth_plugin.rb config/application.rb test/integration/social_sign_in_test.rb
git add lib/omniauth/strategies/slack_openid.rb config/application.rb app/rodauth/user_rodauth_plugin.rb app/views/rodauth/user/_social_sign_in.html.erb .env.test.local .env.template .env.production.template .kamal/secrets config/deploy.yml README.md test/integration/social_sign_in_test.rb
git commit -m "feat(auth): sign in with Slack"
```

---

### Task 7: Connect and disconnect Slack

**Goal:** Signed-in users attach Slack to their own account, which turns email notifications off. Disconnecting brings email back where Slack was on.

**Files:**
- Modify: `app/models/user.rb`
- Modify: `app/rodauth/user_rodauth_plugin.rb`
- Create: `packages/dashboard_portal/app/controllers/dashboard_portal/slack_connections_controller.rb`
- Modify: `packages/dashboard_portal/config/routes.rb`
- Test: `test/models/user_slack_test.rb`, `test/integration/slack_connection_test.rb`

**Acceptance Criteria:**
- [ ] When signed in, the Slack callback links the Slack identity to the current user, even if the emails differ
- [ ] A Slack account already linked to another user is refused with a flash, and nothing changes
- [ ] Creating a Slack identity (signup or connect) opts the user out of email for every category, and the flash says email can be turned back on
- [ ] `DELETE /dashboard/settings/slack` removes the identity and deletes email opt-outs for categories still on in Slack. Slack opt-outs are kept
- [ ] Disconnect is refused when Slack is the only way to sign in

**Verify:** `bin/rails test test/models/user_slack_test.rb test/integration/slack_connection_test.rb test/integration/social_sign_in_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing model test**

`test/models/user_slack_test.rb`:

```ruby
require "test_helper"

class UserSlackTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup do
    @user = create_user!
  end

  def link_slack(user = @user) = user.identities.create!(provider: "slack", uid: "U#{SecureRandom.hex(3)}", info: {"name" => "Ama Mensah"})

  test "slack_identity" do
    assert_nil @user.slack_identity
    identity = link_slack
    assert_equal identity, @user.slack_identity
  end

  test "connecting Slack turns email off for every category" do
    @user.slack_connected!
    NotificationOptOut::CATEGORIES.each_key do |category|
      assert_not @user.wants_notification?(category, via: :email)
      assert @user.wants_notification?(category, via: :slack)
    end
  end

  test "disconnecting brings email back where Slack was on" do
    link_slack
    @user.slack_connected!
    @user.opt_out!(:network, via: :slack)

    @user.disconnect_slack!

    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
    assert @user.wants_notification?(:project_credits, via: :email)
    assert_not @user.wants_notification?(:network, via: :email)
  end

  test "Slack is the only sign-in without a password or another identity" do
    passwordless = User.create!(email: "nopass@example.com", status: :verified)
    link_slack(passwordless)
    assert_not passwordless.can_sign_in_without_slack?

    passwordless.identities.create!(provider: "github", uid: "1")
    assert passwordless.can_sign_in_without_slack?
    assert @user.can_sign_in_without_slack?
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/models/user_slack_test.rb`
Expected: ERROR `undefined method 'slack_identity'`

- [ ] **Step 3: Add the user methods**

In `app/models/user.rb`, after `update_opt_outs!`:

```ruby
  def slack_identity
    identities.find_by(provider: "slack")
  end

  # Slack DMs take over from email. People can turn email back on per category.
  def slack_connected!
    NotificationOptOut::CATEGORIES.each_key { opt_out!(_1, via: :email) }
  end

  # Email comes back for every category still on in Slack, so nobody stops
  # hearing about something they wanted. Slack opt-outs stay in case they reconnect.
  def disconnect_slack!
    transaction do
      slack_identity.destroy!
      still_on = NotificationOptOut::CATEGORIES.keys.select { wants_notification?(_1, via: :slack) }
      notification_opt_outs.where(channel: "email", category: still_on).delete_all
    end
  end

  def can_sign_in_without_slack?
    password_hash.present? || identities.where.not(provider: "slack").exists?
  end
```

Run: `bin/rails test test/models/user_slack_test.rb` → 4 runs, 0 failures

- [ ] **Step 4: Write the failing integration test**

`test/integration/slack_connection_test.rb`:

```ruby
require "test_helper"

class SlackConnectionTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    OmniAuth.config.test_mode = true
    @user = create_profile!.user
  end

  teardown do
    OmniAuth.config.mock_auth.delete(:slack)
    OmniAuth.config.test_mode = false
  end

  test "connecting Slack while signed in links it to you and turns email off" do
    login_user(@user)
    mock_slack(uid: "U123", email: "different@example.com")

    assert_no_difference -> { User.count } do
      post "/users/auth/slack"
      follow_redirect!
    end

    assert_equal "U123", @user.reload.slack_identity.uid
    assert_not @user.wants_notification?(:applications, via: :email)
    follow_redirect! while response.redirect?
    assert_match "Slack connected", response.body
  end

  test "a Slack account linked to someone else can't be connected" do
    other = create_user!
    other.identities.create!(provider: "slack", uid: "U123")
    login_user(@user)
    mock_slack(uid: "U123", email: @user.email)

    post "/users/auth/slack"
    follow_redirect!

    assert_nil @user.reload.slack_identity
    assert_equal other.id, User::Identity.find_by!(provider: "slack", uid: "U123").user_id
    follow_redirect! while response.redirect?
    assert_match "connected to another DevCongress Connect account", response.body
  end

  test "disconnecting" do
    @user.identities.create!(provider: "slack", uid: "U123")
    @user.slack_connected!
    login_user(@user)

    delete "/dashboard/settings/slack"

    assert_redirected_to "/dashboard/settings/notifications"
    assert_nil @user.reload.slack_identity
    assert @user.wants_notification?(:applications, via: :email)
  end

  test "can't disconnect the only way to sign in" do
    user = User.create!(email: "slackonly@example.com", status: :verified)
    create_profile!(user:)
    user.identities.create!(provider: "slack", uid: "U555")
    login_user(user)

    delete "/dashboard/settings/slack"

    assert user.reload.slack_identity
    follow_redirect!
    assert_match "Set a password first", response.body
  end

  private

  def mock_slack(uid:, email:)
    OmniAuth.config.mock_auth[:slack] = OmniAuth::AuthHash.new(
      provider: "slack", uid:, info: {email:, name: "Ama Mensah"},
      extra: {raw_info: {"https://slack.com/team_id" => "T0DEVCON", "email_verified" => true}}
    )
  end
end
```

Note: `login_user` goes through `login_as`, which works without a password for Plutonium's Rodauth test helper. If it needs a password for `slackonly@example.com`, sign in that user with `post "/users/auth/slack"` instead (mock uid `U555`) and drop the `create!` of the identity.

The disconnect redirect target `/dashboard/settings/notifications` only exists after Task 8. Until then, assert `assert_response :redirect` and tighten the assertion in Task 8.

- [ ] **Step 5: Link to the signed-in account and handle the flash**

In `app/rodauth/user_rodauth_plugin.rb`, at the very top of the `before_omniauth_callback_route` block (before the Slack team check), add:

```ruby
      # Signed in: connect the identity to this account rather than looking
      # one up by email. An identity already on another account stays put.
      if logged_in?
        if omniauth_identity && omniauth_identity_account_id != session_value
          set_redirect_error_flash "That #{omniauth_provider.to_s.titleize} account is connected to another DevCongress Connect account."
          redirect "/dashboard/settings/notifications"
        end
        account_from_session
      end
```

In `auth_class_eval`, add (public section, before `private`):

```ruby
      def create_omniauth_identity
        super
        return unless omniauth_provider.to_s == "slack"

        User.find(account_id).slack_connected!
        @slack_connected = true
      end

      def login_notice_flash
        @slack_connected ? "Slack connected. Notifications now come as Slack DMs. You can turn email back on in notification settings." : super
      end
```

- [ ] **Step 6: Write the disconnect controller and route**

`packages/dashboard_portal/app/controllers/dashboard_portal/slack_connections_controller.rb`:

```ruby
module DashboardPortal
  # Unlinks Slack. Connecting goes through Rodauth's Slack sign-in.
  class SlackConnectionsController < PlutoniumController
    def destroy
      if current_user.can_sign_in_without_slack?
        current_user.disconnect_slack!
        redirect_to "/dashboard/settings/notifications", notice: "Slack disconnected. Notifications you had on in Slack now come by email."
      else
        redirect_to "/dashboard/settings/notifications", alert: "Set a password first so you can still sign in."
      end
    end
  end
end
```

`packages/dashboard_portal/config/routes.rb`, after the `email_settings` line:

```ruby
  resource :slack_connection, only: %i[destroy], path: "settings/slack"
```

- [ ] **Step 7: Run the tests**

Run: `bin/rails test test/models/user_slack_test.rb test/integration/slack_connection_test.rb test/integration/social_sign_in_test.rb`
Expected: all pass. The "signing up with Slack" test from Task 6 now also turns email off. Add `assert_not user.wants_notification?(:network, via: :email)` to it.

- [ ] **Step 8: Lint and commit**

```bash
bundle exec standardrb app/models/user.rb app/rodauth/user_rodauth_plugin.rb packages/dashboard_portal/app/controllers/dashboard_portal/slack_connections_controller.rb test/models/user_slack_test.rb test/integration/slack_connection_test.rb test/integration/social_sign_in_test.rb
git add app/models/user.rb app/rodauth/user_rodauth_plugin.rb packages/dashboard_portal/app/controllers/dashboard_portal/slack_connections_controller.rb packages/dashboard_portal/config/routes.rb test/models/user_slack_test.rb test/integration/slack_connection_test.rb test/integration/social_sign_in_test.rb
git commit -m "feat(slack): connect and disconnect Slack from your account"
```

---

### Task 8: Notification settings page

**Goal:** `/dashboard/settings/notifications` with a Slack card and Email and Slack columns. It replaces the email-only page.

**Files:**
- Delete: `packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb`, `packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`
- Create: `packages/dashboard_portal/app/controllers/dashboard_portal/notification_settings_controller.rb`, `packages/dashboard_portal/app/views/dashboard_portal/notification_settings/show.html.erb`, `app/views/shared/_slack_card.html.erb`
- Modify: `packages/dashboard_portal/config/routes.rb`, `app/helpers/portal_paths_helper.rb`, `app/mailers/concerns/categorized_email.rb`, `app/views/layouts/mailer.html.erb`, `app/views/layouts/mailer.text.erb`, `app/views/shared/_user_topbar.html.erb`, `app/views/site/unsubscribes/show.html.erb`, `packages/dashboard_portal/app/controllers/dashboard_portal/slack_connections_controller.rb`
- Rename test: `test/integration/email_settings_test.rb` → `test/integration/notification_settings_test.rb`. Modify `test/mailers/categorized_email_test.rb`, `test/integration/slack_connection_test.rb`

**Acceptance Criteria:**
- [ ] The page shows the Slack card (Connect + Join when unlinked, "Connected as <name>" + Disconnect when linked) and one row per category with Email and Slack checkboxes
- [ ] Slack checkboxes are disabled with "Connect Slack first" when unlinked, and saving then leaves Slack opt-outs alone
- [ ] Saving updates both channels
- [ ] `/dashboard/settings/email` redirects to the new page
- [ ] The user menu, the email footers and the unsubscribe page link to the new page as "Notification settings"

**Verify:** `bin/rails test test/integration/notification_settings_test.rb test/mailers test/integration/email_unsubscribe_test.rb test/integration/slack_connection_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing test**

`git mv test/integration/email_settings_test.rb test/integration/notification_settings_test.rb`, then replace its contents:

```ruby
require "test_helper"

class NotificationSettingsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup { @user = create_profile!.user }

  test "needs sign-in" do
    get "/dashboard/settings/notifications"
    assert_response :redirect
  end

  test "the old email settings path redirects" do
    login_user(@user)
    get "/dashboard/settings/email"
    assert_redirected_to "/dashboard/settings/notifications"
  end

  test "without Slack: email on, Slack column disabled, connect offered" do
    login_user(@user)
    get "/dashboard/settings/notifications"

    assert_response :success
    assert_select "input[type=checkbox][name='notification_settings[email][]'][checked]", 3
    assert_select "input[type=checkbox][name='notification_settings[slack][]'][disabled]", 3
    assert_select "form[action='/users/auth/slack'] button", /Connect Slack/
    assert_match "Connect Slack first", response.body
  end

  test "with Slack: connected card and both columns" do
    @user.identities.create!(provider: "slack", uid: "U1", info: {"name" => "Ama Mensah"})
    @user.slack_connected!
    login_user(@user)
    get "/dashboard/settings/notifications"

    assert_match "Connected as", response.body
    assert_match "Ama Mensah", response.body
    assert_select "form[action='/dashboard/settings/slack'] button", /Disconnect/
    assert_select "input[name='notification_settings[email][]'][checked]", 0
    assert_select "input[name='notification_settings[slack][]'][checked]", 3
  end

  test "saving updates both channels" do
    @user.identities.create!(provider: "slack", uid: "U1")
    login_user(@user)

    patch "/dashboard/settings/notifications", params: {notification_settings: {email: ["", "network"], slack: ["", "applications", "project_credits"]}}

    assert_redirected_to "/dashboard/settings/notifications"
    assert_equal %w[applications project_credits], @user.notification_opt_outs.where(channel: "email").pluck(:category).sort
    assert_equal %w[network], @user.notification_opt_outs.where(channel: "slack").pluck(:category)
  end

  test "saving without Slack leaves Slack opt-outs alone" do
    @user.opt_out!(:network, via: :slack)
    login_user(@user)

    patch "/dashboard/settings/notifications", params: {notification_settings: {email: ["", "network", "applications", "project_credits"]}}

    assert_not @user.wants_notification?(:network, via: :slack)
  end

  test "the user menu links to the page" do
    login_user(@user)
    get "/dashboard"
    assert_select "a[href='/dashboard/settings/notifications']", /Notification settings/
  end
end
```

In `test/mailers/categorized_email_test.rb`, change `"/dashboard/settings/email"` to `"/dashboard/settings/notifications"`. In `test/integration/slack_connection_test.rb`, make the disconnect test assert `assert_redirected_to "/dashboard/settings/notifications"`.

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/integration/notification_settings_test.rb`
Expected: failures/404s on `/dashboard/settings/notifications`

- [ ] **Step 3: Routes, controller and path helper**

`packages/dashboard_portal/config/routes.rb`: replace the `email_settings` line with:

```ruby
  resource :notification_settings, only: %i[show update], path: "settings/notifications"
  get "settings/email", to: redirect("/dashboard/settings/notifications")
```

`git rm packages/dashboard_portal/app/controllers/dashboard_portal/email_settings_controller.rb packages/dashboard_portal/app/views/dashboard_portal/email_settings/show.html.erb`

`packages/dashboard_portal/app/controllers/dashboard_portal/notification_settings_controller.rb`:

```ruby
module DashboardPortal
  # Which categories of notification the signed-in user gets, by email and by
  # Slack DM. Slack settings only change once Slack is connected.
  class NotificationSettingsController < PlutoniumController
    def show
    end

    def update
      settings = params.fetch(:notification_settings, {}).permit(email: [], slack: [])
      channels = current_user.slack_identity ? %w[email slack] : %w[email]
      channels.each do |channel|
        current_user.update_opt_outs!(NotificationOptOut::CATEGORIES.keys - settings[channel].to_a, via: channel)
      end
      redirect_to notification_settings_path, notice: "Notification settings saved."
    end
  end
end
```

`app/helpers/portal_paths_helper.rb`: replace `email_settings_dashboard_path` with:

```ruby
  def notification_settings_dashboard_path
    PortalPathsHelper.routes.dashboard_portal.notification_settings_path
  end
```

Then `grep -rn "email_settings" app packages` and update each hit:
- `categorized_email.rb`: `@email_settings_url = absolute_url(PortalPathsHelper.routes.dashboard_portal.notification_settings_path)`
- `_user_topbar.html.erb`: `section.with_link(label: "Notification settings", href: notification_settings_dashboard_path)`, and swap the icon to `Phlex::TablerIcons::Bell`
- `site/unsubscribes/show.html.erb`: `notification_settings_dashboard_path`
- `layouts/mailer.html.erb` and `layouts/mailer.text.erb`: change the link text "Email settings" to "Notification settings"
- `slack_connections_controller.rb`: replace the two literal `"/dashboard/settings/notifications"` with `notification_settings_path`

- [ ] **Step 4: Write the Slack card partial**

`app/views/shared/_slack_card.html.erb` (the settings page and the dashboard use it; Task 9 adds `dismissible`):

```erb
<%# Connect / connected state for DevCongress Slack. Locals: user. %>
<% identity = user.slack_identity %>
<div class="dc-card">
  <div class="pu-card-body flex flex-col gap-4 sm:flex-row sm:items-center">
    <span class="inline-flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-primary-50 text-primary-600 dark:bg-primary-900/30">
      <%= render Phlex::TablerIcons::BrandSlack.new(class: "h-6 w-6") %>
    </span>
    <div class="min-w-0 flex-1">
      <% if identity %>
        <p class="font-semibold text-[var(--pu-text)]">Connected as <%= identity.info["name"].presence || "your Slack account" %></p>
        <p class="text-sm text-[var(--pu-text-muted)]">Notifications you turn on below come as DMs from the DevCongress Connect app.</p>
      <% else %>
        <p class="font-semibold text-[var(--pu-text)]">DevCongress lives on Slack</p>
        <p class="text-sm text-[var(--pu-text-muted)]">Join the community, then connect your account to get notifications as Slack DMs.</p>
      <% end %>
    </div>
    <div class="flex shrink-0 flex-wrap gap-2">
      <% if identity %>
        <%= button_to "Disconnect", PortalPathsHelper.routes.dashboard_portal.slack_connection_path, method: :delete,
              class: "pu-btn pu-btn-sm pu-btn-outline", form: {data: {turbo_confirm: "Disconnect Slack? Notifications you had on in Slack will come by email."}} %>
      <% else %>
        <% if Slack.invite_url %>
          <%= link_to "Join Slack", Slack.invite_url, target: "_blank", rel: "noopener", class: "pu-btn pu-btn-sm pu-btn-outline" %>
        <% end %>
        <% if rodauth(:user).omniauth_providers.include?(:slack) %>
          <%= button_to "Connect Slack", rodauth(:user).omniauth_request_path(:slack), method: :post, data: {turbo: false}, class: "pu-btn pu-btn-sm pu-btn-primary" %>
        <% end %>
      <% end %>
    </div>
  </div>
</div>
```

Note: `rodauth.omniauth_providers` returns symbols (the sign-in partial calls `.map(&:to_s)`). If it returns strings here, use `.map(&:to_s).include?("slack")`.

- [ ] **Step 5: Write the settings page**

`packages/dashboard_portal/app/views/dashboard_portal/notification_settings/show.html.erb`:

```erb
<% content_for :title, "Notification settings" %>
<% slack = current_user.slack_identity.present? %>

<div class="mx-auto max-w-2xl space-y-6">
  <header>
    <h1 class="font-display text-3xl text-[var(--pu-text)]">Notification settings</h1>
    <p class="mt-1 text-[var(--pu-text-muted)]">Choose what we tell you about, and where. Account and security emails, and updates on jobs you post, always come by email to <%= current_user.email %>.</p>
  </header>

  <%= render "shared/slack_card", user: current_user %>

  <%= form_with url: notification_settings_path, method: :patch, class: "dc-card" do |form| %>
    <div class="pu-card-body space-y-5">
      <%= hidden_field_tag "notification_settings[email][]", "", id: nil %>
      <%= hidden_field_tag "notification_settings[slack][]", "", id: nil %>
      <div class="grid grid-cols-[1fr_auto_auto] items-start gap-x-6 gap-y-5">
        <span></span>
        <span class="text-xs font-semibold uppercase tracking-wide text-[var(--pu-text-subtle)]">Email</span>
        <span class="text-xs font-semibold uppercase tracking-wide text-[var(--pu-text-subtle)]">Slack</span>
        <% NotificationOptOut::CATEGORIES.each do |key, category| %>
          <span>
            <span class="block font-semibold text-[var(--pu-text)]"><%= category[:label] %></span>
            <span class="block text-sm text-[var(--pu-text-muted)]"><%= category[:description] %></span>
          </span>
          <%= check_box_tag "notification_settings[email][]", key, current_user.wants_notification?(key, via: :email),
                id: "notification_email_#{key}", class: "mt-1 h-4 w-4 accent-primary-600", "aria-label": "#{category[:label]} by email" %>
          <%= check_box_tag "notification_settings[slack][]", key, slack && current_user.wants_notification?(key, via: :slack),
                id: "notification_slack_#{key}", disabled: !slack, class: "mt-1 h-4 w-4 accent-primary-600 disabled:opacity-40", "aria-label": "#{category[:label]} on Slack" %>
        <% end %>
      </div>
      <% unless slack %>
        <p class="text-sm text-[var(--pu-text-muted)]">Connect Slack first to get these as DMs.</p>
      <% end %>
      <%= form.submit "Save", class: "pu-btn pu-btn-md pu-btn-primary" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 6: Run the tests**

Run: `bin/rails test test/integration/notification_settings_test.rb test/mailers test/integration/email_unsubscribe_test.rb test/integration/slack_connection_test.rb test/integration/portal_access_test.rb`
Expected: all pass. `grep -rn "email_settings" app packages test` returns nothing except the redirect route.

- [ ] **Step 7: Lint and commit**

```bash
bundle exec standardrb packages/dashboard_portal app/helpers/portal_paths_helper.rb app/mailers/concerns/categorized_email.rb test/integration/notification_settings_test.rb
git add -u app packages test
git add packages/dashboard_portal/app/controllers/dashboard_portal/notification_settings_controller.rb packages/dashboard_portal/app/views/dashboard_portal/notification_settings/show.html.erb app/views/shared/_slack_card.html.erb test/integration/notification_settings_test.rb
git commit -m "feat(notifications): notification settings with email and Slack columns"
```

---

### Task 9: Point people to Slack

**Goal:** A dismissible Slack card on the dashboard, Slack in the footer, and a Slack badge on linked developers' profiles.

**Files:**
- Create: `app/javascript/controllers/dismiss_controller.js`
- Modify: `app/javascript/controllers/index.js`
- Modify: `packages/dashboard_portal/app/views/dashboard_portal/dashboard/index.html.erb`
- Modify: `app/views/site/shared/_footer.html.erb`
- Modify: `app/views/site/developers/show.html.erb:11-16`
- Test: `test/integration/slack_prompts_test.rb`

**Acceptance Criteria:**
- [ ] The dashboard shows the Slack card to users without Slack, unless the `slack_prompt_dismissed` cookie is set. The card has a dismiss button wired to `dismiss#dismiss`
- [ ] `dismiss` is registered in `index.js`. It sets the cookie for a year and removes the element
- [ ] The footer lists Slack (the invite URL) when `SLACK_INVITE_URL` is set
- [ ] Profiles of linked users show a Slack icon linking to `<SLACK_WORKSPACE_URL>/team/<uid>`

**Verify:** `bin/rails test test/integration/slack_prompts_test.rb` → all pass. `yarn build` succeeds

**Steps:**

- [ ] **Step 1: Write the failing test**

`test/integration/slack_prompts_test.rb`:

```ruby
require "test_helper"

class SlackPromptsTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper

  setup do
    ENV["SLACK_INVITE_URL"] = "https://join.slack.com/t/devcongress/shared_invite/abc"
    @profile = create_profile!
    @user = @profile.user
  end

  teardown { ENV.delete("SLACK_INVITE_URL") }

  test "the dashboard invites users without Slack" do
    login_user(@user)
    get "/dashboard"
    assert_select "[data-controller='dismiss'][data-dismiss-cookie-value='slack_prompt_dismissed']" do
      assert_select "a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /Join Slack/
      assert_select "button[data-action='dismiss#dismiss']"
    end
  end

  test "the card stays hidden once dismissed or connected" do
    login_user(@user)
    cookies[:slack_prompt_dismissed] = "1"
    get "/dashboard"
    assert_select "[data-controller='dismiss']", 0

    cookies.delete(:slack_prompt_dismissed)
    @user.identities.create!(provider: "slack", uid: "U1")
    get "/dashboard"
    assert_select "[data-controller='dismiss']", 0
  end

  test "the footer links to Slack" do
    get "/"
    assert_select "footer a[href='https://join.slack.com/t/devcongress/shared_invite/abc']", /slack/i
  end

  test "linked profiles show a Slack badge" do
    @user.identities.create!(provider: "slack", uid: "U123")
    get "/@#{@profile.handle}"
    assert_select "a[href='https://devcongress-community.slack.com/team/U123']"
  end
end
```

(`SLACK_WORKSPACE_URL` comes from `.env.test.local`, added in Task 6.)

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/integration/slack_prompts_test.rb`
Expected: 4 failures

- [ ] **Step 3: Write the Stimulus controller and register it**

`app/javascript/controllers/dismiss_controller.js`:

```js
import { Controller } from "@hotwired/stimulus"

// Hides a card for good: remembers the dismissal in a cookie the server checks.
export default class extends Controller {
  static values = { cookie: String }

  dismiss() {
    document.cookie = `${this.cookieValue}=1; max-age=31536000; path=/; samesite=lax`
    this.element.remove()
  }
}
```

In `app/javascript/controllers/index.js`, after the `ClipboardController` registration:

```js
import DismissController from "./dismiss_controller"
application.register("dismiss", DismissController)
```

- [ ] **Step 4: Dashboard card**

In `packages/dashboard_portal/app/views/dashboard_portal/dashboard/index.html.erb`, right after the closing `</header>`:

```erb
  <% if current_user.slack_identity.nil? && cookies[:slack_prompt_dismissed].blank? %>
    <div class="relative" data-controller="dismiss" data-dismiss-cookie-value="slack_prompt_dismissed">
      <%= render "shared/slack_card", user: current_user %>
      <button type="button" data-action="dismiss#dismiss" aria-label="Dismiss" class="absolute right-3 top-3 text-[var(--pu-text-subtle)] hover:text-[var(--pu-text)]">
        <%= render Phlex::TablerIcons::X.new(class: "h-4 w-4") %>
      </button>
    </div>
  <% end %>
```

- [ ] **Step 5: Footer and profile badge**

`app/views/site/shared/_footer.html.erb`, change the `socials` hash so Slack comes first when configured:

```erb
<% socials = {
     "slack" => Slack.invite_url,
     "linkedin" => "https://www.linkedin.com/company/devcongress",
     "x" => "https://x.com/devcongress",
     "github" => "https://github.com/devcongress",
     "youtube" => "https://youtube.com/devcongress",
     "facebook" => "https://facebook.com/devcongress",
     "instagram" => "https://www.instagram.com/devcongress/"
   }.compact %>
```

`app/views/site/developers/show.html.erb`, change the `links` array:

```erb
<% slack_identity = profile.user.slack_identity %>
<% links = [
     [Phlex::TablerIcons::BrandGithub, profile.github_url],
     [Phlex::TablerIcons::BrandLinkedin, profile.linkedin_url],
     [Phlex::TablerIcons::BrandX, profile.x_url],
     [Phlex::TablerIcons::BrandSlack, (slack_identity && Slack.workspace_url && "#{Slack.workspace_url}/team/#{slack_identity.uid}")],
     [Phlex::TablerIcons::World, profile.website_url]
   ].select { |_, url| url.present? } %>
```

- [ ] **Step 6: Build and run the tests**

Run: `yarn build && bin/rails test test/integration/slack_prompts_test.rb test/integration/public_site_test.rb test/integration/developer_portal_test.rb`
Expected: build succeeds, all pass

- [ ] **Step 7: Commit**

```bash
git add app/javascript/controllers/dismiss_controller.js app/javascript/controllers/index.js packages/dashboard_portal/app/views/dashboard_portal/dashboard/index.html.erb app/views/site/shared/_footer.html.erb app/views/site/developers/show.html.erb test/integration/slack_prompts_test.rb
git commit -m "feat(slack): point people to the DevCongress Slack"
```

(If `app/assets/builds` is tracked, check `git status` and stage the rebuilt bundle as the repo usually does.)

---

## Phase 3: Slack DMs

### Task 10: `SlackDm` base and delivery job

**Goal:** A base class for notification DMs that delivers in the background and only to linked users who haven't turned the category off on Slack.

**Files:**
- Create: `app/models/slack_dm.rb`
- Create: `app/jobs/slack_dm_job.rb`
- Test: `test/models/slack_dm_test.rb`

**Acceptance Criteria:**
- [ ] `deliver_later` enqueues `SlackDmJob` with the class name and params, only when Slack is configured
- [ ] Delivery is skipped when the recipient has no Slack identity or has opted out on Slack. Otherwise it posts to the identity's uid
- [ ] Every DM ends with a context block: a Slack-channel unsubscribe link and a link to notification settings
- [ ] Slack errors are logged at warn and discarded. Rate limits and network errors retry

**Verify:** `bin/rails test test/models/slack_dm_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing test**

`test/models/slack_dm_test.rb`:

```ruby
require "test_helper"

class SlackDmTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  class TestDm < SlackDm
    self.category = :network

    def recipient = params[:user]

    def text = "Hello"

    def blocks = [section("*Hello*")]
  end

  setup { @user = create_user! }

  test "delivers later through the job" do
    assert_enqueued_with(job: SlackDmJob, args: ["SlackDmTest::TestDm", {user: @user}]) do
      TestDm.new(user: @user).deliver_later
    end
  end

  test "does nothing when Slack isn't set up" do
    Slack.client = nil
    assert_no_enqueued_jobs { TestDm.new(user: @user).deliver_later }
  end

  test "skips users without Slack" do
    TestDm.new(user: @user).deliver_now
    assert_empty @slack.calls
  end

  test "skips users who turned the category off on Slack" do
    @user.identities.create!(provider: "slack", uid: "U1")
    @user.opt_out!(:network, via: :slack)
    TestDm.new(user: @user).deliver_now
    assert_empty @slack.calls
  end

  test "sends to the Slack user with the settings footer" do
    @user.identities.create!(provider: "slack", uid: "U1")
    SlackDmJob.perform_now("SlackDmTest::TestDm", user: @user)

    call = @slack.calls_to(:post_message).sole
    assert_equal "U1", call.params[:channel]
    assert_equal "Hello", call.params[:text]
    footer = call.params[:blocks].last
    assert_equal "context", footer[:type]
    token = NotificationOptOut.token_for(@user, :network, via: :slack)
    assert_match "/unsubscribe/#{token}|Turn off Slack DMs for network activity", footer[:elements].sole[:text]
    assert_match "/dashboard/settings/notifications|Notification settings", footer[:elements].sole[:text]
  end

  test "people who left the workspace are skipped quietly" do
    @user.identities.create!(provider: "slack", uid: "U1")
    @slack.fail_next(:post_message, "user_not_found")
    assert_nothing_raised { SlackDmJob.perform_now("SlackDmTest::TestDm", user: @user) }
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/models/slack_dm_test.rb`
Expected: ERROR `uninitialized constant SlackDm`

- [ ] **Step 3: Write the base class**

`app/models/slack_dm.rb`:

```ruby
# The Slack DM version of a categorised email (see NotificationOptOut::CATEGORIES).
# Subclasses set the category and define recipient, text (the notification
# preview) and blocks. A DM goes only to recipients who have connected Slack
# and haven't turned the category off there. That's checked when it's sent,
# like emails.
class SlackDm
  include PortalPathsHelper

  class_attribute :category

  attr_reader :params

  def initialize(**params)
    @params = params
  end

  def deliver_later
    SlackDmJob.perform_later(self.class.name, **params) if Slack.configured?
  end

  def deliver_now
    identity = recipient.slack_identity
    return unless identity && recipient.wants_notification?(category, via: :slack)

    Slack.client.post_message(channel: identity.uid, text:, blocks: blocks + [footer])
  end

  private

  def section(mrkdwn) = {type: "section", text: {type: "mrkdwn", text: mrkdwn}}

  def button(label, path) = {type: "actions", elements: [{type: "button", text: {type: "plain_text", text: label}, url: Slack.url(path)}]}

  def escape(text) = Slack.escape(text)

  def footer
    label = NotificationOptOut::CATEGORIES.fetch(category.to_s)[:label].downcase
    unsubscribe = Slack.url(Rails.application.routes.url_helpers.unsubscribe_path(token: NotificationOptOut.token_for(recipient, category, via: :slack)))
    {type: "context", elements: [{type: "mrkdwn", text: "<#{unsubscribe}|Turn off Slack DMs for #{label}> · <#{Slack.url(notification_settings_dashboard_path)}|Notification settings>"}]}
  end
end
```

- [ ] **Step 4: Write the job**

`app/jobs/slack_dm_job.rb`:

```ruby
# Sends a SlackDm. Errors such as user_not_found or account_inactive mean the
# person left the workspace or was deactivated. Their identity stays linked
# in case they come back.
class SlackDmJob < ApplicationJob
  queue_as :default

  discard_on Slack::Error do |job, error|
    Rails.logger.warn { "#{job.arguments.first} not sent: #{error.code}" }
  end
  rescue_from(Slack::RateLimited) { |error| retry_job(wait: error.retry_after.seconds) }
  retry_on(*Slack::NETWORK_ERRORS, wait: :polynomially_longer, attempts: 5)

  def perform(class_name, **params)
    class_name.constantize.new(**params).deliver_now
  end
end
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `bin/rails test test/models/slack_dm_test.rb`
Expected: 6 runs, 0 failures

- [ ] **Step 6: Lint and commit**

```bash
bundle exec standardrb app/models/slack_dm.rb app/jobs/slack_dm_job.rb test/models/slack_dm_test.rb
git add app/models/slack_dm.rb app/jobs/slack_dm_job.rb test/models/slack_dm_test.rb
git commit -m "feat(slack): send notifications as Slack DMs"
```

---

### Task 11: DMs for each notification

**Goal:** A Slack DM goes out wherever a categorised email does: follows, applications and project credits.

**Files:**
- Create: `packages/network/app/models/network/followed_dm.rb`, `packages/hiring/app/models/hiring/application_received_dm.rb`, `packages/hiring/app/models/hiring/application_status_changed_dm.rb`, `packages/showcase/app/models/showcase/credit_invited_dm.rb`, `packages/showcase/app/models/showcase/credit_confirmed_dm.rb`
- Modify: `packages/network/app/models/network/follow.rb` (`notify_followee`)
- Modify: `packages/hiring/app/models/hiring/job_application.rb` (`notify_company`, `notify_applicant`, new `status_update_subject`)
- Modify: `packages/hiring/app/mailers/hiring/job_application_mailer.rb` (use `status_update_subject`)
- Modify: `packages/showcase/app/models/showcase/project_contributor.rb` (create callback, `confirm!`)
- Test: `test/models/notification_dms_test.rb`

**Acceptance Criteria:**
- [ ] Each DM class renders the expected text, recipient and button URL
- [ ] The status-change DM includes the company's note when there is one, and links rejected applicants to open jobs
- [ ] Each call site enqueues its DM next to its email (`SlackDmJob` with the right class)
- [ ] `JobApplicationMailer#status_changed` subjects are unchanged

**Verify:** `bin/rails test test/models/notification_dms_test.rb test/mailers test/integration/network_test.rb test/integration/showcase_test.rb test/integration/applicant_management_test.rb` → all pass

**Steps:**

- [ ] **Step 1: Write the failing test**

`test/models/notification_dms_test.rb`:

```ruby
require "test_helper"

class NotificationDmsTest < ActiveJob::TestCase
  include AccountsTestHelper
  include SlackTestHelper

  setup do
    @ama = create_profile!(name: "Ama Owusu")
    @kofi = create_profile!(name: "Kofi Boateng")
  end

  def button_url(dm) = dm.blocks.last[:elements].sole[:url]

  test "followed" do
    follow = Network::Follow.create!(follower: @ama, followee: @kofi)
    dm = Network::FollowedDm.new(follow:)

    assert_equal @kofi.user, dm.recipient
    assert_equal "Ama Owusu followed you on DevCongress Connect", dm.text
    assert_equal "http://example.com/@#{@ama.handle}", button_url(dm)

    Network::Follow.create!(follower: @kofi, followee: @ama)
    assert_equal "You're now connected with Ama Owusu", dm.text
  end

  test "application received and status changed" do
    owner = create_user!
    company = create_company!(owner:, name: "Acme")
    job = create_job!(company:, title: "Rails Engineer")
    application = job.job_applications.create!(profile: @kofi)

    received = Hiring::ApplicationReceivedDm.new(job_application: application, recipient: owner)
    assert_equal owner, received.recipient
    assert_equal "New applicant for Rails Engineer: Kofi Boateng", received.text
    assert_match "/hiring/job_applications/#{application.to_param}", button_url(received)

    application.update!(status: :shortlisted)
    changed = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: "Free Tuesday?")
    assert_equal @kofi.user, changed.recipient
    assert_equal "You're on the shortlist for Rails Engineer", changed.text
    assert(changed.blocks.any? { _1.dig(:text, :text)&.include?("> Free Tuesday?") })

    application.update!(status: :rejected)
    rejected = Hiring::ApplicationStatusChangedDm.new(job_application: application, message: nil)
    assert_equal "http://example.com/jobs", button_url(rejected)
  end

  test "project credits" do
    project = Showcase::Project.create!(owner: @ama, title: "Trotro Times")
    credit = project.contributors.create!(profile: @kofi)

    invited = Showcase::CreditInvitedDm.new(contributor: credit)
    assert_equal @kofi.user, invited.recipient
    assert_equal "Ama Owusu credited you on Trotro Times", invited.text

    confirmed = Showcase::CreditConfirmedDm.new(contributor: credit)
    assert_equal @ama.user, confirmed.recipient
    assert_equal "Kofi Boateng confirmed they worked on Trotro Times", confirmed.text
  end

  test "call sites enqueue DMs alongside emails" do
    Rails.cache.clear
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Network::FollowedDm" }) do
      Network::Follow.create!(follower: @ama, followee: @kofi)
    end

    owner = create_user!
    job = create_job!(company: create_company!(owner:))
    application = nil
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Hiring::ApplicationReceivedDm" && args.last[:recipient] == owner }) do
      application = job.job_applications.create!(profile: @kofi)
    end
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Hiring::ApplicationStatusChangedDm" }) do
      application.move_to!(:shortlisted, message: "Hi")
    end

    project = Showcase::Project.create!(owner: @ama, title: "Trotro Times")
    credit = nil
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Showcase::CreditInvitedDm" }) do
      credit = project.contributors.create!(profile: @kofi)
    end
    assert_enqueued_with(job: SlackDmJob, args: ->(args) { args.first == "Showcase::CreditConfirmedDm" }) do
      credit.confirm!
    end
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bin/rails test test/models/notification_dms_test.rb`
Expected: ERROR `uninitialized constant Network::FollowedDm`

- [ ] **Step 3: Move the status subject to the model**

In `packages/hiring/app/models/hiring/job_application.rb`, add before `private`:

```ruby
  # Headline for telling the applicant about their new status (email and Slack).
  def status_update_subject
    case status
    when "shortlisted" then "You're on the shortlist for #{job_post.title}"
    when "hired" then "#{company.display_name} wants to hire you"
    else "An update on your application to #{company.display_name}"
    end
  end
```

In `packages/hiring/app/mailers/hiring/job_application_mailer.rb`, change `status_changed` to `categorized_mail :applications, to: @profile.user, subject: @application.status_update_subject` and delete the private `status_subject` method.

- [ ] **Step 4: Write the DM classes**

`packages/network/app/models/network/followed_dm.rb`:

```ruby
module Network
  # Slack DM for Network::FollowMailer#followed.
  class FollowedDm < ::SlackDm
    self.category = :network

    def recipient = follow.followee.user

    def text
      follow.mutual? ? "You're now connected with #{follower.name}" : "#{follower.name} followed you on DevCongress Connect"
    end

    def blocks
      [
        section("*#{escape(text)}*#{"\n#{escape(follower.headline)}" if follower.headline.present?}"),
        button("View #{follower.name.split.first}'s profile", Rails.application.routes.url_helpers.developer_page_path(handle: follower.handle))
      ]
    end

    private

    def follow = params[:follow]

    def follower = follow.follower
  end
end
```

`packages/hiring/app/models/hiring/application_received_dm.rb`:

```ruby
module Hiring
  # Slack DM for JobApplicationMailer#received, one per company user.
  class ApplicationReceivedDm < ::SlackDm
    self.category = :applications

    def recipient = params[:recipient]

    def text = "New applicant for #{application.job_post.title}: #{profile.name}"

    def blocks
      [
        section("*#{escape(text)}*#{"\n#{escape(profile.headline)}" if profile.headline.present?}"),
        button("Review application", company_portal_application_path(application.job_post.company, application))
      ]
    end

    private

    def application = params[:job_application]

    def profile = application.profile
  end
end
```

`packages/hiring/app/models/hiring/application_status_changed_dm.rb`:

```ruby
module Hiring
  # Slack DM for JobApplicationMailer#status_changed.
  class ApplicationStatusChangedDm < ::SlackDm
    self.category = :applications

    def recipient = application.profile.user

    def text = application.status_update_subject

    def blocks
      [
        section("*#{escape(text)}*"),
        (section("A note from #{escape(application.company.display_name)}:\n> #{escape(params[:message])}") if params[:message].present?),
        application.rejected? ? button("Browse open jobs", Rails.application.routes.url_helpers.public_jobs_path) : button("View your application", developer_portal_application_path(application.profile, application))
      ].compact
    end

    private

    def application = params[:job_application]
  end
end
```

`packages/showcase/app/models/showcase/credit_invited_dm.rb`:

```ruby
module Showcase
  # Slack DM for ContributorMailer#invited.
  class CreditInvitedDm < ::SlackDm
    self.category = :project_credits

    def recipient = contributor.profile.user

    def text = "#{contributor.owner.name} credited you on #{contributor.project.title}"

    def blocks
      [
        section("*#{escape(text)}*\nConfirm it if you worked on it and it shows on your profile."),
        button("Confirm or decline", developer_portal_credit_path(contributor.profile, contributor))
      ]
    end

    private

    def contributor = params[:contributor]
  end
end
```

`packages/showcase/app/models/showcase/credit_confirmed_dm.rb`:

```ruby
module Showcase
  # Slack DM for ContributorMailer#confirmed.
  class CreditConfirmedDm < ::SlackDm
    self.category = :project_credits

    def recipient = contributor.owner.user

    def text = "#{contributor.profile.name} confirmed they worked on #{contributor.project.title}"

    def blocks
      [section("*#{escape(text)}*"), button("View the project", developer_portal_project_path(contributor.owner, contributor.project))]
    end

    private

    def contributor = params[:contributor]
  end
end
```

- [ ] **Step 5: Add the call sites**

`packages/network/app/models/network/follow.rb`, at the end of `notify_followee`:

```ruby
    Network::FollowMailer.with(follow: self).followed.deliver_later
    Network::FollowedDm.new(follow: self).deliver_later
```

`packages/hiring/app/models/hiring/job_application.rb`:

```ruby
  def notify_company
    job_post.company.users.verified.find_each do |recipient|
      Hiring::JobApplicationMailer.with(job_application: self, recipient:).received.deliver_later
      Hiring::ApplicationReceivedDm.new(job_application: self, recipient:).deliver_later
    end
  end

  def notify_applicant
    Hiring::JobApplicationMailer.with(job_application: self, message: status_message.presence).status_changed.deliver_later
    Hiring::ApplicationStatusChangedDm.new(job_application: self, message: status_message.presence).deliver_later
  end
```

`packages/showcase/app/models/showcase/project_contributor.rb`: replace the `after_create_commit` lambda with:

```ruby
  after_create_commit -> {
    Showcase::ContributorMailer.with(contributor: self).invited.deliver_later
    Showcase::CreditInvitedDm.new(contributor: self).deliver_later
  }
```

In `confirm!`, after the mailer line:

```ruby
    Showcase::CreditConfirmedDm.new(contributor: self).deliver_later
```

- [ ] **Step 6: Run the tests**

Run: `bin/rails test test/models/notification_dms_test.rb test/mailers test/integration/network_test.rb test/integration/showcase_test.rb test/integration/applicant_management_test.rb test/models/hiring`
Expected: all pass. If an existing test uses `assert_enqueued_jobs <n>` without `only:`, it now counts the extra DM jobs only when Slack is configured. Those tests don't configure Slack, so the counts are unchanged.

- [ ] **Step 7: Lint and commit**

```bash
bundle exec standardrb packages/network/app/models packages/hiring/app/models packages/hiring/app/mailers packages/showcase/app/models test/models/notification_dms_test.rb
git add packages/network/app/models/network/followed_dm.rb packages/network/app/models/network/follow.rb packages/hiring/app/models/hiring/application_received_dm.rb packages/hiring/app/models/hiring/application_status_changed_dm.rb packages/hiring/app/models/hiring/job_application.rb packages/hiring/app/mailers/hiring/job_application_mailer.rb packages/showcase/app/models/showcase/credit_invited_dm.rb packages/showcase/app/models/showcase/credit_confirmed_dm.rb packages/showcase/app/models/showcase/project_contributor.rb test/models/notification_dms_test.rb
git commit -m "feat(slack): DM follows, applications and project credits"
```

---

### Task 12: Full suite and spec sync

**Goal:** Everything passes together, and the spec reflects what was built.

**Files:**
- Modify: `docs/superpowers/specs/2026-10-08-slack-integration-design.md` (the deviations listed at the top of this plan)

**Acceptance Criteria:**
- [ ] `bin/rails test` passes with no failures or errors
- [ ] `bundle exec standardrb` is clean
- [ ] The spec mentions the custom OmniAuth strategy, the earlier opt-out rename, connect-while-signed-in, and the `dismiss` controller

**Verify:** `bin/rails test && bundle exec standardrb` → 0 failures, no offenses

**Steps:**

- [ ] **Step 1: Run everything**

Run: `bin/rails test`
Expected: 0 failures, 0 errors. Fix any regressions in the task that caused them.

Run: `bundle exec standardrb`
Expected: no offenses

- [ ] **Step 2: Update the spec**

In the spec's "Provider" section, replace the `omniauth_openid_connect` bullet with: "A small `OmniAuth::Strategies::SlackOpenid` (in `lib/omniauth/strategies/`) built on the bundled `omniauth-oauth2`. It uses Slack's `openid/connect/authorize`, `openid.connect.token` and `openid.connect.userInfo` endpoints, and is registered as `omniauth_provider :slack_openid, ..., name: :slack, team: SLACK_TEAM_ID`." Under "Sign-in and connect", replace the rodauth-omniauth sentence with: "The callback hook loads the signed-in account first, so the identity attaches to it (rodauth-omniauth on its own matches accounts by email)." Under "Driving people to Slack", change `dismissible_controller` to `dismiss_controller`.

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/specs/2026-10-08-slack-integration-design.md
git commit -m "docs: sync Slack spec with implementation"
```
