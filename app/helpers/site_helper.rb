require "redcarpet"

module SiteHelper
  MARKDOWN = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, no_images: true, no_styles: true, safe_links_only: true, link_attributes: {rel: "nofollow noopener", target: "_blank"}),
    autolink: true, no_intra_emphasis: true, strikethrough: true, lax_spacing: true
  )

  # User-written markdown (bios, job descriptions). Raw HTML is stripped and the
  # result sanitized again, so nothing a user types can inject markup.
  def render_markdown(text)
    return if text.blank?

    sanitize(MARKDOWN.render(text), tags: %w[p br strong em del a ul ol li h1 h2 h3 h4 blockquote code pre hr],
      attributes: %w[href rel target])
  end

  AVAILABILITY = {
    "looking" => ["Open to work", "text-[#059669]"],
    "open" => ["Open to offers", "text-[#0284c7]"],
    "not_looking" => ["Not looking", "text-[#888]"]
  }.freeze

  def availability_pill(profile)
    label, classes = AVAILABILITY.fetch(profile.availability)
    tag.span(label, class: "dc-badge shrink-0 #{classes}")
  end

  # Who posted a job: the company, or for personal posts the person.
  def poster_avatar(job, size: :md)
    company = job.company
    if company.personal?
      render InitialsAvatar.new(name: company.display_name, seed: company.personal_profile&.handle || company.slug, size:)
    else
      render InitialsAvatar.new(name: company.display_name, seed: company.slug, size:, shape: :square)
    end
  end

  # The poster's public page: their profile (when the viewer may see it) or
  # the company page. Nil when there's nowhere to link.
  def poster_path(job)
    company = job.company
    return public_company_path(company.slug) unless company.personal?

    profile = company.personal_profile
    developer_page_path(handle: profile.handle) if profile&.visible_to?(current_user)
  end

  def pill(text, extra = nil)
    tag.span(text, class: "rounded-full border border-[#e0ddd4] bg-[#f5f2e8] px-2.5 py-0.5 text-xs #{extra}")
  end

  # Keep the current filters when building filter/pagination links.
  def filter_params(**overrides)
    request.query_parameters.symbolize_keys.except(:page).merge(overrides).compact_blank
  end

  def select_options(choices, selected)
    options_for_select(choices, selected)
  end
end
