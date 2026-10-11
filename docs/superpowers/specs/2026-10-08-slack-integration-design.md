# Slack integration

## Goal

DevCongress runs on Slack. Tie the jobs app into it:

1. Cross-post every live job to `#jobs` and keep the message in sync with the
   job's lifecycle.
2. Let people sign in with Slack or connect Slack to an existing account, and
   nudge everyone else to join the workspace.
3. Send notifications to linked users as Slack DMs, with a per-category
   Slack toggle next to the email one.

Built in that order. Each phase ships on its own, except that the opt-out
rename (see Phase 3) happens at the start of phase 2, because connecting
Slack writes email opt-outs.

## Slack app and configuration

One Slack app ("DevCongress Connect"), installed in the DevCongress workspace. It
is a single workspace, so there's no install/OAuth flow for the bot: the token
is copied from the app config into env.

| Env var               | Used for                                   |
|-----------------------|--------------------------------------------|
| `SLACK_BOT_TOKEN`     | `#jobs` posts and DMs (scope `chat:write`)  |
| `SLACK_JOBS_CHANNEL_ID` | The `#jobs` channel (bot must be a member) |
| `SLACK_CLIENT_ID` | Sign in with Slack (OpenID Connect) |
| `SLACK_CLIENT_SECRET` | Sign in with Slack (OpenID Connect) |
| `SLACK_TEAM_ID`       | Locks sign-in to the DevCongress workspace  |
| `SLACK_INVITE_URL`    | "Join Slack" links                         |
| `SLACK_WORKSPACE_URL` | e.g. `https://devcongress-community.slack.com`, for profile links |

Each piece is off when its env vars aren't set, like the Google and GitHub
providers today: no bot token means no posts or DMs, and no client
credentials means no "Continue with Slack" button.

### API client

`Slack::Client` (in `lib/` or `app/models/slack/`) is a thin wrapper over
`Net::HTTP` for the three endpoints we use: `chat.postMessage`,
`chat.update` and `chat.getPermalink`. It POSTs a form-encoded body (blocks
as JSON) with the bearer token and returns the parsed body. When `ok` is
false it raises `Slack::Error` carrying Slack's `error` code. A 429 raises
`Slack::RateLimited` with the `Retry-After` value, defaulting to 30 seconds
when the header is missing. A 5xx response raises `Slack::Unavailable`,
which is retried like a network error.

`Slack.client` returns the shared client. `Slack.configured?` is true when
`SLACK_BOT_TOKEN` is set. Tests swap in `Slack::FakeClient` (see Testing).

## Phase 1: `#jobs` cross-posting

### Data

`hiring_job_posts` gains:

- `slack_message_ts` (string): the current `#jobs` message, if any
- `slack_posted_status` (string): the status that message last rendered
  (`active`, `filled`, `expired`, `archived`, `withdrawn`)
- `slack_message_url` (string): the message permalink, for "Discuss in #jobs"

All jobs are posted, including members-only ones: the workspace is itself
members-only.

### Trigger

`Hiring::JobPost` gets an `after_commit` that enqueues
`Hiring::SlackJobPostSyncJob` when any of `published_at`, `approved_at`,
`expires_at`, `filled_at`, `archived_at`, `title`, `description`,
`employment_type`, `seniority`, salary, pay or location fields changed, and
`Slack.configured?`. The job always renders from current state, so duplicate
enqueues are harmless.

### Sync rules

| Current status            | Message state                                | Action |
|---------------------------|----------------------------------------------|--------|
| `active`                  | no `slack_message_ts`                        | `chat.postMessage`; store `ts`, `slack_posted_status = "active"` |
| `active`                  | `ts` present, posted status `active`         | `chat.update` in place |
| `active`                  | `ts` present, posted status not `active`     | Repost (renewed or reopened): post a new message, store the new `ts` and `active`. The old message keeps its closed rendering and its thread |
| `filled`/`expired`/`archived` | `ts` present, posted status `active`     | `chat.update` to the closed rendering; set posted status to the job status |
| `draft`/`pending_review`  | `ts` present, posted status `active`         | (A live job declined back to draft) `chat.update` to closed, labelled "No longer available"; posted status `withdrawn` |
| anything else             |                                              | Nothing |

A live job that's deleted (an admin removing it) can't be synced, since the
record is gone by the time a job runs. Instead `Hiring::JobPost` renders the
closed message ("No longer available") in a `before_destroy` when the posted
status is `active` and a `ts` is present, and an `after_destroy_commit`
enqueues `Hiring::SlackJobPostCloseJob` with the `ts`, text and blocks as plain
values. That job only calls `chat.update`, with the same failure handling as
the sync job; `message_not_found` is ignored. A sync enqueued before the
delete is discarded (`ActiveJob::DeserializationError`).

### Expiry sweep

Expiry is time-based, so nothing fires when a job expires.
`Hiring::SlackJobSweepJob` runs hourly from `config/recurring.yml`. It finds
posts with `slack_posted_status: "active"` and `expires_at < now`, and
enqueues a sync for each.

### Message

Block Kit, rendered by `Hiring::JobPostSlackMessage` (`#text`, `#blocks`
for a given job):

- Live: bold title, linked to the public job URL · company name. A line with
  type, seniority, location and pay (whatever's present). A two-line plain-text
  excerpt of the description. A **View & apply** button to the public job URL.
  The `text` fallback is "New <kind_noun> at <company>: <title>".
- Closed: struck-through title · company, then a label: "Filled",
  "Expired", or "No longer available" (archived or withdrawn). No button.

### Discuss in #jobs

When a job has a `slack_message_ts`, the public job page shows a "Discuss in
#jobs" link to the message permalink. The permalink comes from
`chat.getPermalink` at post time and is stored in `slack_message_url`, so
the page never calls Slack. The `ts` is saved before the permalink is
fetched, so a permalink failure and retry can't post twice. A message with
no stored permalink gets it backfilled on the next update.

### Failures

- Network errors, `Slack::Unavailable` and `Slack::RateLimited`: `retry_on`
  with backoff (rate limits wait `Retry-After`).
- `message_not_found` on update (someone deleted it in Slack): clear
  `ts`/url/posted status. If the job is active, post a fresh message.
  Otherwise stop.
- Other Slack errors (`channel_not_found`, `not_in_channel`,
  `invalid_auth`, ...): config problems. `Rails.logger.error { ... }` and
  discard.

## Phase 2: Sign in and connect with Slack

### Provider

Slack's "Sign in with Slack" is OpenID Connect. A small
`OmniAuth::Strategies::SlackOpenid` (in `lib/omniauth/strategies/`) is built
on the bundled `omniauth-oauth2`, rather than adding `omniauth_openid_connect`
and its dependencies. It uses Slack's `openid/connect/authorize`,
`openid.connect.token` and `openid.connect.userInfo` endpoints, with scopes
`openid email profile`. A userInfo response with `ok: false` fails the
sign-in cleanly. It is registered in `UserRodauthPlugin`, next to Google and
GitHub:

- `omniauth_provider :slack_openid, SLACK_CLIENT_ID, SLACK_CLIENT_SECRET, name: :slack, team: SLACK_TEAM_ID`.
  The `team` param makes Slack open straight to the DevCongress workspace.
- Only registered when `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET` and
  `SLACK_TEAM_ID` are all set.
- Callback URL to register with Slack: `<RAILS_DEFAULT_URL>/users/auth/slack/callback`.

### Callback checks

The existing `before_omniauth_callback_route` gains a `slack` branch:

- The `https://slack.com/team_id` claim must equal `SLACK_TEAM_ID`.
  Otherwise flash "That isn't the DevCongress Slack workspace." and redirect
  to login. Nothing is linked.
- `email_verified` must be true (same rule as Google).

The identity is stored in `user_identities` with provider `slack`, `uid` =
the Slack user id (the DM target), and `info` from `social_profile_info`
(name, avatar). Onboarding picks up the name and avatar the same way it does
for Google and GitHub.

`User#slack_identity` returns the Slack identity, or nil.

### Sign-in and connect

- `_social_sign_in.html.erb` gains "Continue with Slack" (Tabler
  `BrandSlack` icon). Signup, linking by verified email, and onboarding behave
  exactly as for Google and GitHub.
- Signed-in users connect with a POST to the same request path. The
  callback hook loads the signed-in account first, so the identity attaches
  to it (rodauth-omniauth on its own matches accounts by email). Afterwards
  the user lands back on notification settings.
- If that Slack account is already linked to another user, flash "That Slack
  account is connected to another DevCongress Connect account." and change
  nothing.
- A user who already has a Slack account connected can't add a second one:
  flash "Disconnect your current Slack account first."
- The same rule holds when signed out: a new Slack account whose verified
  email matches an account that already has a different Slack account is
  refused with "That email's account is already connected to a different
  Slack account." and a redirect to login. (The hook looks the account up by
  email itself, via `account_from_omniauth`, and the callback reuses it.)

### Connecting turns email off

When a Slack identity is created for a user (signup or connect), every
categorised email is turned off for them: an email opt-out row is inserted for
each category in `NotificationOptOut::CATEGORIES` (insert, ignoring rows
that already exist). Slack DMs take over. The user can turn email back on for
any category from the settings page. The flash after connecting says so:
"Slack connected. Notifications now come as Slack DMs. You can turn email
back on in notification settings."

### Disconnect

`DELETE /dashboard/settings/slack` (`DashboardPortal::SlackConnectionsController#destroy`)
removes the Slack identity.

- When Slack isn't connected, the notice is "Slack isn't connected."
- Blocked when it is the user's only way to sign in (no password and no
  other identity): flash "Set a password first so you can still sign in."
- On disconnect, email is turned back on for every category the user still
  had on in Slack (delete their email opt-out for each category without a
  Slack opt-out), so nobody silently stops getting notifications. Slack
  opt-out rows are kept in case they reconnect.

### Driving people to Slack

- The settings page card and the dashboard card share the
  `shared/_slack_card` partial. Unlinked: "DevCongress lives on Slack. Join
  the community, then connect your account...", with **Join Slack**
  (`SLACK_INVITE_URL`) and **Connect Slack** buttons. Linked: "Connected as
  <name>", with **Disconnect**.
- The card is shown only when Slack is usable: `SLACK_INVITE_URL` is set or
  the `slack` sign-in provider is registered (`SlackHelper#slack_available?`).
  Each button shows only when its piece is set up. On the settings page a
  connected user always sees it, so they can disconnect.
- The dashboard card is shown only to users without a Slack identity and is
  dismissible. Dismissal is stored in the `slack_prompt_dismissed` cookie by
  a registered Stimulus controller (`dismiss_controller`; the existing
  `dismissable` controller closes `<details>` dropdowns).
- Public job page: "Discuss in #jobs" (phase 1). For signed-out visitors,
  also "Join the DevCongress Slack".
- Footer: a Slack icon linking to `SLACK_INVITE_URL`, next to the existing
  social links.
- Developer profiles: a Slack badge for linked users, linking to
  `<SLACK_WORKSPACE_URL>/team/<uid>`.

## Phase 3: Slack DMs and per-channel settings

### Opt-outs

`email_opt_outs` is renamed to `notification_opt_outs`, and the model to
`NotificationOptOut`:

- New `channel` string column, not null, default `"email"`; existing rows
  become `email`. Validated against `NotificationOptOut::CHANNELS`
  (`email`, `slack`).
- The unique index becomes `[user_id, channel, category]`.
- `User#wants_notification?(category, via:)` and
  `User#opt_out!(category, via:)` replace `wants_email?` and
  `opt_out_of_email!`. Callers are updated.

Every category is on in both channels until opted out, except that connecting
Slack turns email off (phase 2). Essential emails (Rodauth, invitations, job
review) stay email-only, with no DM.

### DM classes

`SlackDm` base class (`app/models/slack_dm.rb`):

- `self.category = :applications`
- `initialize(**params)`, where `params` are records
- Subclasses define `recipient`, `text` (notification fallback) and `blocks`
- `deliver_later` enqueues `SlackDmJob.perform_later(self.class.name, **params)`
  when `Slack.configured?`. Records serialise through GlobalID, the same as
  mailers.
- User-supplied text (names, titles, a company's note) is escaped for Slack
  mrkdwn in both `text` and `blocks`. A multi-line note is quoted on every
  line.

`SlackDmJob` rebuilds the DM. At perform time it skips the DM if the
recipient has no Slack identity or has opted out of the category on Slack, so
a change made after enqueueing still applies. It discards the DM when a
record no longer exists (`ActiveJob::DeserializationError`). Otherwise it calls
`chat.postMessage(channel: identity.uid, text:, blocks:)`.

| DM class                              | Mirrors                         | Recipient | Button |
|---------------------------------------|---------------------------------|-----------|--------|
| `Network::FollowedDm`                 | `FollowMailer#followed`         | followee | "View <first name>'s profile" |
| `Hiring::ApplicationReceivedDm`       | `JobApplicationMailer#received` | each verified company user | "Review application" |
| `Hiring::ApplicationStatusChangedDm`  | `#status_changed`               | applicant (including the optional message) | "View your application", or "Browse open jobs" when rejected |
| `Showcase::CreditInvitedDm`           | `ContributorMailer#invited`     | credited profile's user | "Confirm or decline" |
| `Showcase::CreditConfirmedDm`         | `ContributorMailer#confirmed`   | project owner | "View the project" |

Each call site that enqueues the mailer also enqueues the matching DM.

Each DM has a short headline, one or two lines of context, a button (see
the table above), and a context block: "Turn off
Slack DMs for <label> · Notification settings". The first link is a
Slack-channel unsubscribe link.

### Unsubscribe tokens

- Tokens become `[user_id, channel, category]`.
- `NotificationOptOut.resolve` still accepts the old two-element tokens,
  reading them as `email`, so links in emails already sent keep working.
- The `/unsubscribe/:token` page names the channel: the heading reads "Turn
  off <category> Slack DMs?" or "Turn off <category> emails?".

### Settings page

- `/dashboard/settings/email` becomes `/dashboard/settings/notifications`
  (`DashboardPortal::NotificationSettingsController`). The old path
  redirects.
- Slack card at the top (phase 2), then a table: one row per category, with
  an Email checkbox and a Slack checkbox.
- The Slack checkboxes are disabled, with the hint "Connect Slack first",
  until Slack is connected.
- Without Slack sign-in (no `slack` provider) there's nothing to connect, so
  the Slack column and hint are hidden, unless the user is already connected.
- Saving replaces the user's opt-out rows per channel. Slack opt-outs only
  change once Slack is connected.
- The user-menu link becomes "Notification settings".
- Email footers link to the new settings path.

### Failures

- `user_not_found`, `account_inactive`, `cannot_dm_bot`: the person left
  or was deactivated. `Rails.logger.warn { ... }` and discard. The identity
  isn't unlinked, since they may come back.
- Other Slack errors (`invalid_auth`, `missing_scope`, ...): config
  problems. `Rails.logger.error { ... }` and discard.
- Network errors and rate limits: retry, as for `#jobs`.

## Testing

`Slack::FakeClient` records calls and can be set up to return a given error.
Tests set `Slack.client` to it, so there's no real HTTP and no WebMock.

- `Slack::Client`: raises `Slack::Error` with the code on `ok: false`, and
  `Slack::RateLimited` with `Retry-After`.
- Sync job: one test per row of the sync table. Also: the repost after renew
  or reopen keeps the old message closed, `message_not_found` recovery, a
  config error is discarded, and nothing is enqueued when Slack isn't
  configured.
- Sweep: picks up expired `active` posts only.
- Message rendering: live and closed variants, and optional fields left out
  when blank.
- Sign-in: wrong team rejected, unverified email rejected, signed-in connect
  attaches the identity, a Slack account already linked to someone else is
  blocked.
- Connect turns email off for all categories. Disconnect turns email back on
  for categories still on in Slack. Disconnect is blocked when Slack is the
  only way to sign in.
- DMs: skipped without an identity, skipped when opted out on Slack, sent
  otherwise. Each DM class renders the expected text and links. Each call site
  enqueues its DM.
- Opt-outs: migration maps existing rows to `email`, old two-element tokens
  resolve as `email`, and Slack tokens opt out of Slack only.
- Settings page: Slack column disabled when unlinked, saving both channels,
  and the redirect from `/settings/email`.
