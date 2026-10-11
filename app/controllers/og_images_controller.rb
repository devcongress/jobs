# Link-preview images (og:image) for the public site. Crawlers fetch these
# without a session, so only records guests may see get a card. The URL
# carries the card's version, so responses can be cached for good.
class OgImagesController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def site
    send_card OgCard::Site.new
  end

  def developer
    profile = Developers::Profile.find_by!(handle: params[:handle].downcase)
    send_card OgCard::Developer.new(guest_visible!(profile))
  end

  def company
    send_card OgCard::Company.new(Company.organizations.find_by!(slug: params[:slug]))
  end

  def job
    send_card OgCard::Job.new(guest_visible!(Hiring::JobPost.includes(:company).find(params[:id])))
  end

  def project
    send_card OgCard::Project.new(guest_visible!(Showcase::Project.includes(:owner, :skills).find_by!(slug: params[:slug])))
  end

  private

  def guest_visible!(record)
    raise ActiveRecord::RecordNotFound unless record.visible_to?(nil)

    record
  end

  def send_card(card)
    expires_in 1.year, public: true, immutable: true
    send_data card.png, type: "image/png", disposition: "inline"
  end
end
