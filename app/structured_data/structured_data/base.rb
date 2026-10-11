# schema.org JSON-LD for the public pages. Each builder returns a plain hash;
# `view` is the view rendering the page, for URL and markdown helpers.
module StructuredData
  class Base
    CONTEXT = "https://schema.org"

    def initialize(record, view:)
      @record = record
      @view = view
    end

    private

    attr_reader :view

    def person(profile)
      {"@type" => "Person", "name" => profile.name, "url" => view.developer_page_url(handle: profile.handle)}
    end

    def address(city:, country:, region: nil)
      return if city.blank? && country.blank?

      {"@type" => "PostalAddress", "addressLocality" => city, "addressRegion" => region,
       "addressCountry" => World.country_code(country) || country}.compact_blank
    end
  end
end
