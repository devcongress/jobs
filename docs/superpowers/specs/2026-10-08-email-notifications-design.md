# Email notification settings

## Goal

Let users turn off non-essential emails by category, from a settings page or
with a one-click unsubscribe link in each email.

## Categories

All categories are on by default. A user turns one off by opting out.

| Category          | Label            | Emails                                                                                  |
|-------------------|------------------|-----------------------------------------------------------------------------------------|
| `network`         | Network activity | `Network::FollowMailer#followed` (new follower, new connection)                         |
| `applications`    | Job applications | `Hiring::JobApplicationMailer#received` (company users), `#status_changed` (developer)  |
| `project_credits` | Project credits  | `Showcase::ContributorMailer#invited`, `#confirmed`                                     |

Always sent, with no opt-out: Rodauth account emails, company invitations,
`Hiring::JobReviewMailer` (`approved` and `declined` go to companies, and
`review_requested` goes to admins).

## Data

New table `email_opt_outs`, created in `app/models` because it belongs to `User`:

- `user_id` (FK, not null)
- `category` (string, not null)
- `created_at`
- unique index on `[user_id, category]`, declared inline in `create_table`

Model `EmailOptOut`:

- `belongs_to :user`
- `category` is validated against `EmailOptOut::CATEGORIES`, a constant holding
  the keys and labels from the table above.

Additions to `User`:

- `has_many :email_opt_outs, dependent: :delete_all`
- `wants_email?(category)`: returns true unless an opt-out row exists for that category
- `opt_out_of_email!(category)`: idempotent; does nothing if the row already exists

## Gating mail

A `CategorizedEmail` concern, included in `ApplicationMailer`, adds a private
`categorized_mail(category, to: user, **mail_options)`. Categorised actions call
it in place of `mail`.

- If `to` has opted out, it returns without calling `mail`. Action Mailer then
  sends nothing, the same way the existing `return if recipients.empty?`
  guards work.
- Otherwise it sets `List-Unsubscribe: <unsubscribe_url>` and
  `List-Unsubscribe-Post: List-Unsubscribe=One-Click`.
- It also exposes `@email_category`, `@unsubscribe_url` and
  `@email_settings_url` to the layouts. The HTML and text footers then add
  "Turn off <label> emails · Email settings" below the usual note.
- The opt-out is checked when the email is delivered, not when it's enqueued,
  so a change made in between still applies.

Each categorised email has exactly one recipient. Company emails that
currently go to every verified company user are split up:

- `received`: the model enqueues one email per verified company user, passing
  `recipient:`. Users who opted out are skipped when it's delivered.
- `approved` and `declined` are essential, but they also move to one email per
  user (`recipient:`) so all company emails work the same way.

## Unsubscribe

- Token: `Rails.application.message_verifier(:email_unsubscribe).generate([user.id, category])`.
  It has no expiry and stays valid even if the user opts back in.
- `GET /unsubscribe/:token` (main app, `UnsubscribesController#show`): a page
  in the public site layout that names the category, shows a "Turn off"
  button, and links to the settings page. A GET never changes anything, so
  email link-scanners can't unsubscribe people by visiting the link.
- `POST /unsubscribe/:token` (`#create`): records the opt-out and shows a
  confirmation. The `List-Unsubscribe-Post` one-click request from mail
  clients posts here too, so this action skips CSRF verification.
- An invalid token, or one whose user was deleted, gets a 404.
- No sign-in is required.

## Settings page

- Lives in the dashboard portal at `/dashboard/settings/email`
  (`DashboardPortal::EmailSettingsController`, with `show` and `update`).
- Shows one checkbox per category with its label and a short description of
  which emails it covers.
- Saving replaces the user's opt-out rows with the unchecked categories, then
  redirects back with a flash message.
- The user menu in `shared/_user_topbar` gets an "Email notifications" link
  next to "Change password".

## Testing

- Model tests for `EmailOptOut` and `User#wants_email?` / `#opt_out_of_email!`
  (the opt-out is idempotent and categories are validated).
- Mailer tests:
  - An opted-out recipient isn't delivered.
  - Categorised emails carry the `List-Unsubscribe` headers and the footer link.
  - Essential emails carry neither.
- Hiring:
  - `received` is sent per user and skips users who opted out.
  - `approved` and `declined` are sent per user.
- Request tests:
  - Unsubscribe GET shows the confirmation page and doesn't opt out.
  - POST opts out.
  - A bad token returns a 404.
  - The settings page renders and saving updates the opt-outs.
  - The settings page needs sign-in.
