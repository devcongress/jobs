module StructuredData
  class Company < Base
    def to_h
      company = @record
      {
        "@context" => CONTEXT,
        "@type" => "Organization",
        "name" => company.name,
        "url" => view.public_company_url(company.slug),
        "description" => company.description,
        "address" => address(city: company.city, country: company.country),
        "sameAs" => company.website.presence
      }.compact_blank
    end
  end
end
