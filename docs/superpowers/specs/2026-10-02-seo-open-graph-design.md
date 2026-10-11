# SEO: Open Graph, preview images, structured data, sitemap

## Goal

Public pages (home, directories, developer profiles, company pages, jobs,
projects) share well as links and are understood by search engines: Open
Graph/Twitter tags, a generated 1200×630 preview image per record, JSON-LD
structured data, and a sitemap.

## Scope

In: the `site` layout and the public pages rendered with it (`home#index`,
`site/developers`, `site/companies`, `site/jobs`, `site/projects`).

Out: GitHub avatars on cards, breadcrumb structured data, auth/portal pages.

"Public" below means visible to anonymous visitors: `visible_to_everyone?` on
profiles and projects (projects also need a public owner), and for jobs
`active? && visible_to_everyone?`. Company pages are public for every
non-personal company (personal ones redirect to the owner's profile), so they
always get tags, a card and structured data; the sitemap lists only companies
with at least one public job, to keep empty pages out of the index.

## 1. Meta tags

The `site` layout keeps reading `content_for :title`, `:description` and
`:noindex`, and adds:

- `<link rel="canonical">`: the request path without the query string, except
  `page` on index pages.
- `og:site_name` ("DevCongress Connect"), `og:title` (the page title without the
  site suffix), `og:description`, `og:url` (the canonical URL), `og:type`
  (`content_for :og_type`, default `website`; developer pages use `profile`),
  `og:image` with `og:image:width` 1200, `og:image:height` 630 and
  `og:image:alt`.
- `twitter:card` `summary_large_image` and `twitter:site` `@devcongress`;
  Twitter falls back to the og tags for the rest.
- `og:image` comes from `content_for :og_image`, defaulting to the site card.
- `content_for :structured_data` renders inside
  `<script type="application/ld+json">`. JSON is generated with `to_json`
  (which escapes `<`, `>` and `&`), so record text cannot close the script tag.

A `SeoHelper` holds `canonical_url`, `og_image_url(record)` and
`structured_data(hash)` so the views stay one-liners.

## 2. Structured data

Builders in `app/structured_data/` return plain hashes, each with `@context`
`https://schema.org`. Pages only emit them when the record is public.

- `StructuredData::Site` (home): `WebSite` (name, url) and an `Organization`
  for DevCongress (name, url `https://devcongress.org`, logo, `sameAs`
  `https://x.com/devcongress`).
- `StructuredData::DeveloperProfile`: `ProfilePage` whose `mainEntity` is a
  `Person`: name, `alternateName` @handle, description (headline), `address`
  (`addressLocality` city, `addressCountry` country), `sameAs` (GitHub,
  LinkedIn, X, website URLs that are present), `knowsAbout` (skill names), url.
- `StructuredData::Company`: `Organization` with name, url (company page),
  `sameAs` the company website when present.
- `StructuredData::JobPosting`: title, description (rendered HTML),
  `datePosted` (published_at), `validThrough` (expires_at), `employmentType`
  mapped from `employment_type` (FULL_TIME, PART_TIME, CONTRACTOR, INTERN, ...),
  `hiringOrganization` (company name and page url), `jobLocation` as a `Place`
  with a `PostalAddress` (city, country) when set, and for remote jobs
  `jobLocationType` `TELECOMMUTE` plus `applicantLocationRequirements` (the
  country when set). `baseSalary` is a `MonetaryAmount` with currency and a
  `QuantitativeValue` (`minValue`, `maxValue`, `unitText` from `pay_period`:
  HOUR, DAY, WEEK, MONTH, YEAR), only when the job is paid and has a salary.
  `directApply` is true when the job accepts applications on the site. Filled,
  expired, archived or unapproved jobs get no JobPosting.
- `StructuredData::Project`: `CreativeWork` with name, description (summary),
  url, `author` (owner `Person` with name and profile url), `contributor`
  (public contributors as `Person`), `keywords` (skill names).

## 3. Preview images

Routes, all `GET`, `format: :png`:

- `/og/site.png`
- `/og/devs/:handle.png`
- `/og/companies/:slug.png`
- `/og/jobs/:id.png`
- `/og/projects/:slug.png`

Page URLs add `?v=<record.cache_version>` (the site card uses a constant
version) so a changed record gets a new URL and crawlers refetch.

`OgImagesController` (public, no auth) loads the record with the same public
rules as the pages and returns 404 otherwise. It calls a card class, caches the
PNG bytes in `Rails.cache` (Solid Cache in production) under
`["og", card.cache_key]`, and responds with `Cache-Control: public,
max-age=31536000, immutable` and `Content-Type: image/png`.

Cards live in `app/og_cards/`: `OgCard::Base` (renders an ERB SVG template
from `app/views/og_cards/`, converts it with
`Vips::Image.new_from_buffer(svg, "")` and `write_to_buffer(".png")`), and one
subclass per type (`Site`, `Developer`, `Company`, `Job`, `Project`) supplying
the template and its fields. Text is truncated in Ruby to fit (titles to two
lines), so the SVG never relies on wrapping.

Design: 1200×630, cream (#F5F2E8) background, an ink-bordered white card with
the pink (#D10F72) offset shadow used on the site, the `dev:congress{};`
wordmark, the initials avatar (circle for people, rounded square for companies)
using the same seed and palette as `InitialsAvatar` (hex values for its Tailwind
colours), the name/title in DM Serif Display and detail lines in Inter:

- Developer: name, @handle, headline, "city, country · availability".
- Company: name, "N open roles".
- Job: title, company, "type · location/remote · pay".
- Project: title, "by owner", summary.
- Site: "DevCongress Connect", "Developers, jobs and the people behind them".

Fonts: TTF files for DM Serif Display and Inter in `vendor/fonts/` (the
existing woff2 files are not reliably readable by fontconfig), with
`config/fonts.conf` pointing at them. `config/initializers/og_fonts.rb` sets
`ENV["FONTCONFIG_FILE"]` before libvips loads, so rendering is the same on
macOS and in Docker. The Docker image already has libvips (with librsvg).

## 4. Sitemap

`GET /sitemap.xml` (`SitemapsController#show`, XML builder): home, `/devs`,
`/jobs`, `/projects`, and every public developer, company with a public job,
public job and public project, each with `lastmod` from `updated_at`. Cached for an hour
(`expires_in 1.hour, public: true`).

`public/robots.txt` adds `Sitemap: https://connect.devcongress.org/sitemap.xml`.

## 5. Testing

- Integration tests per page type: og/twitter tags and canonical present;
  JSON-LD parses and has the key fields; non-public pages have no JSON-LD and
  use the site card.
- `JobPosting` builder unit tests: remote vs on-site, salary present/absent,
  employment type and pay period mapping, filled/expired jobs return nothing.
- OG image endpoints: 200 with a 1200×630 PNG for public records, 404 for
  non-public, cache header set.
- Sitemap: includes public records, excludes private, unpublished and
  expired ones.
