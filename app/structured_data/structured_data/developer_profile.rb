module StructuredData
  class DeveloperProfile < Base
    def to_h
      profile = @record
      {
        "@context" => CONTEXT,
        "@type" => "ProfilePage",
        "url" => view.developer_page_url(handle: profile.handle),
        "dateCreated" => profile.created_at.iso8601,
        "dateModified" => profile.updated_at.iso8601,
        "mainEntity" => person(profile).merge(
          "alternateName" => "@#{profile.handle}",
          "description" => profile.headline,
          "address" => address(city: profile.city, region: profile.region, country: profile.country),
          "sameAs" => [profile.github_url, profile.linkedin_url, profile.x_url, profile.website_url].compact_blank,
          "knowsAbout" => profile.skills.map(&:name)
        ).compact_blank
      }
    end
  end
end
