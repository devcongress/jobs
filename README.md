# DevCongress Connect

A catalogue of our developers, what they've built, who they know, and where
they can work next. It grew out of the DevCongress Jobs app.

Built on [Plutonium](https://github.com/radioactive-labs/plutonium-core),
Rails 8.1 and SQLite, and deployed with Kamal. See [docs/DESIGN.md](docs/DESIGN.md)
for the domain model and roadmap.

## Requirements

- Ruby 3.3+ (see `.ruby-version`)
- Node 22 (see `.node-version`), with `corepack enable` so the pinned Yarn 4 is used

## Setup

```sh
bin/setup      # installs gems and JS packages, prepares the databases
bin/dev        # web server plus JS/CSS watchers, at http://localhost:3000
bin/rails test
bundle exec standardrb
```

## Where things are

| Path | What |
|---|---|
| `/` | Public pages (main app) |
| `/users/login`, `/users/create-account` | User accounts |
| `/onboarding` | First step after signup: creates a developer profile, a company, or both |
| `/setup/developer/new`, `/setup/company/new` | Create whichever was skipped, or another company |
| `/dashboard` | Signed-in user's home (`packages/dashboard_portal`) |
| `/developer/:handle` | Developer portal, scoped to the user's own profile (`packages/developer_portal`); models in `packages/developers` |
| `/company/:slug` | Company portal, scoped to one company (`packages/company_portal`) |
| `/admins/login`, `/admin` | Admin accounts (TOTP available, not yet enforced) and admin portal (`packages/admin_portal`) |
| `/devs`, `/@handle` | Public developer directory and profile pages |
| `/jobs`, `/jobs/:id`, `/companies/:slug` | Public jobs board, job and company pages |
| `/projects`, `/projects/:slug` | Public projects and project pages (`packages/showcase`) |
| `/developer/:handle/network` | Connections, followers, following and people you may know (`packages/network`) |
| `/manage/*` | Jobs, errors, Litestream and performance dashboards (admins only) |

Admins can't sign up. Create the first one with:

```sh
EMAIL=you@example.com bin/rails rodauth:admin
```

In development, emails open in the browser through letter_opener.

## Emails

Every email uses the branded layout in `app/views/layouts/mailer.{html,text}.erb`
and the building blocks in `app/helpers/email_helper.rb` (inline styles only,
since mail clients drop stylesheets). Preview them all at
<http://localhost:3000/rails/mailers>; the previews in `test/mailers/previews`
use your development records.

| Email | Sent to | When |
|---|---|---|
| Confirm email, reset password, confirm new email, password changed/reset | The account | Account activity (Rodauth, `app/views/rodauth_mailer`) |
| Unlock account | Admin | Too many failed admin sign-ins |
| Review needed | All admins | A company or individual publishes their first post |
| Post live / changes needed | The poster | An admin approves or declines that post |
| New applicant | Company members | Someone applies in the app |
| Application update | Applicant | Status moves to reviewing, shortlisted, rejected or hired, with the team's optional message |
| Company invite | Invitee | A member invites someone |
| New follower / you're connected | The person followed | Someone follows them (at most once a week per pair) |
| Credited on a project | Contributor | A project's owner adds them; they confirm or decline |
| Credit confirmed | Project owner | A contributor confirms |

## Deploy

Kamal, configured in `config/deploy.yml`, to the shared Hetzner box
(95.216.244.221) at <https://connect.devcongress.org>. Rails credentials hold only
`secret_key_base`; everything else is an environment variable. Deploy with
`bin/deploy`, not `bin/kamal deploy`: it loads `.env.production` and
`config/master.key`, checks nothing required is missing, then builds and rolls out.

```sh
cp .env.production.template .env.production   # once, then fill it in
bin/deploy
```

| Variable | Required | Purpose |
|---|---|---|
| `KAMAL_REGISTRY_PASSWORD` | yes | ghcr.io token for `devcongress/connect` |
| `RAILS_MASTER_KEY` | yes | Decrypts `config/credentials.yml.enc`, which holds only `secret_key_base`. Read from `config/master.key` (gitignored) |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | yes | From `bin/rails db:encryption:init`. Encrypts invite tokens |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | yes | As above |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | yes | As above |
| `RESEND_API_KEY` | yes | Outgoing mail through Resend. `devcongress.org` must be verified there |
| `LITESTREAM_REPLICA_BUCKET`, `LITESTREAM_ACCESS_KEY_ID`, `LITESTREAM_SECRET_ACCESS_KEY` | yes | Litestream S3 replica |
| `LITESTREAM_REPLICA_REGION`, `LITESTREAM_REPLICA_ENDPOINT` | yes | Backblaze B2 region and S3 endpoint, e.g. `eu-central-003` and `https://s3.eu-central-003.backblazeb2.com` |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | no | "Continue with Google". Callback: `https://connect.devcongress.org/users/auth/google/callback` |
| `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` | no | "Continue with GitHub". Callback: `https://connect.devcongress.org/users/auth/github/callback` |
| `SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_TEAM_ID` | no | "Continue with Slack", limited to the DevCongress workspace. Callback: `https://connect.devcongress.org/users/auth/slack/callback` |
| `SLACK_BOT_TOKEN`, `SLACK_JOBS_CHANNEL_ID` | no | Bot token (scope `chat:write`) for `#jobs` cross-posts and notification DMs. Invite the bot to `#jobs` |
| `SLACK_INVITE_URL`, `SLACK_WORKSPACE_URL` | no | "Join Slack" links, and profile links such as `https://devcongress-community.slack.com` |

The host, URL and mail sender are fixed in `config/deploy.yml`. The app refuses
to boot in production if a required variable is missing; the list lives in
`config/initializers/001_ensure_required_env.rb`.

Three roles run on the one host and share `/storage/devcongress_connect`: `web`,
`job` (Solid Queue) and `litestream`. Litestream replicates only the primary
database to `devcongress_connect/production.sqlite3` in the bucket; queue, cache, cable,
errors and Rails Pulse are reconstructible. Uploads (`storage/uploads`) are not
replicated.

`.kamal/hooks/pre-deploy` runs once per deploy, before the new version boots:
it checks the server's secrets file, restores any database missing from the
volume (`bin/rails litestream:restore_missing`), then runs `db:prepare` and the
idempotent `db:seed`. It is
the only place migrations run, so `--skip-hooks` deploys none.

The very first deploy has no secrets file on the server for the hook to use,
so it takes two runs: `bin/deploy --skip-hooks`, then `bin/deploy`.

One-time server setup: the container runs as uid 1000, and Docker creates a
missing bind-mount directory as root, so hand it to uid 1000 before the first
deploy. Mode 700 keeps the databases unreadable to other accounts on the host,
whatever mode SQLite gives the files inside:

```sh
sudo mkdir -p /storage/devcongress_connect
sudo chown 1000:1000 /storage/devcongress_connect
sudo chmod 700 /storage/devcongress_connect
```

## Working with Claude

The Plutonium skills are synced into `.claude/skills`. Refresh them after
upgrading the gem with `bin/rails g pu:skills:sync`.
