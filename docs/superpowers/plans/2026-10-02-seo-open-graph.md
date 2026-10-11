# SEO: Open Graph, preview images, structured data, sitemap — Implementation Plan

**Goal:** Implement `docs/superpowers/specs/2026-10-02-seo-open-graph-design.md`.

**Architecture:** The `site` layout renders meta tags from `content_for` values
set by each page through `SeoHelper`. JSON-LD comes from plain-Ruby builders in
`app/structured_data/`. Preview images are SVG templates rendered to PNG by
libvips on request (`OgImagesController`), cached in `Rails.cache` under the
record's cache key. `SitemapsController` serves `/sitemap.xml`.

**Tech Stack:** Rails 8.1, ruby-vips (librsvg + pango), fontconfig, Minitest.

**User Verification:** NO — no user verification required.

---

### Task 1: Shared avatar colours and initials

- Modify `app/components/initials_avatar.rb`: a `PALETTE` of Tailwind class →
  hex, with class methods `initials_for(name)` and `hex_for(seed)` that the
  component and the OG cards both use.

### Task 2: OG card rendering

- Create `vendor/fonts/*.ttf` (DM Serif Display 400; Inter 400/700; latin and
  latin-ext), `config/fonts.conf`, and `config/initializers/og_fonts.rb`
  (sets `FONTCONFIG_FILE` before libvips loads).
- Create `app/og_cards/og_card/base.rb` and the `site`, `developer`,
  `company`, `job` and `project` cards, plus the SVG template
  `app/views/og_cards/card.svg.erb`.
- Test: `test/og_cards/og_card_test.rb` checks that each card renders a
  1200×630 PNG and that long text is truncated.

### Task 3: OG image endpoints

- Create `app/controllers/og_images_controller.rb` and its routes under `/og`.
- Test: `test/integration/og_images_test.rb` checks PNGs for public records,
  404 for non-public ones, and the cache headers.

### Task 4: Structured data builders

- Create `app/structured_data/structured_data/{site,developer_profile,company,job_posting,project}.rb`.
- Test: `test/structured_data/job_posting_test.rb` and friends.

### Task 5: Layout and page wiring

- Create `app/helpers/seo_helper.rb`.
- Modify `app/views/layouts/site.html.erb` and the public views (home,
  developer, company, job and project pages).
- Test: `test/integration/seo_meta_test.rb` checks the tags, the JSON-LD, and
  that non-public pages fall back to the site card.

### Task 6: Sitemap and robots

- Create `app/controllers/sitemaps_controller.rb` and
  `app/views/sitemaps/show.xml.builder`.
- Modify `config/routes.rb` and `public/robots.txt`.
- Test: `test/integration/sitemap_test.rb`.

### Task 7: Production check

- Render a card inside the production Docker image to confirm the fonts and
  librsvg work there.
