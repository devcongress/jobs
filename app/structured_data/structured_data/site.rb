module StructuredData
  # The site itself and DevCongress, for the home page.
  class Site < Base
    def initialize(view:)
      super(nil, view:)
    end

    def to_h
      [
        {"@context" => CONTEXT, "@type" => "WebSite", "name" => "DevCongress Connect", "url" => view.root_url},
        {"@context" => CONTEXT, "@type" => "Organization", "name" => "DevCongress", "url" => "https://devcongress.org",
         "logo" => view.image_url("brand/devcongress-dev-square.png"), "sameAs" => ["https://x.com/devcongress"]}
      ]
    end
  end
end
