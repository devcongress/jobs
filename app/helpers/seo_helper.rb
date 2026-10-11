# Canonical URLs, link-preview images and JSON-LD for the public site. Pages
# set them with content_for; layouts/site renders the tags.
module SeoHelper
  SITE_NAME = "DevCongress Connect"

  # The page without its filters, keeping the page number on listings.
  def canonical_url
    page = params[:page].to_i
    "#{request.base_url}#{request.path}#{"?page=#{page}" if page > 1}"
  end

  def og_image_url(card)
    name, route_params = card.route
    public_send(:"#{name}_url", **route_params, v: card.version)
  end

  def og_card(card)
    content_for :og_image, og_image_url(card)
  end

  # A JSON-LD object (or array of them). to_json escapes <, > and &, so user
  # text can't close the script tag.
  def structured_data(data)
    content_for :structured_data, ERB::Util.json_escape(data.to_json).html_safe if data.present?
  end
end
