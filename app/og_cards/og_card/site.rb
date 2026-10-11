module OgCard
  # The default card, for pages without a record of their own.
  class Site < Base
    def title = "DevCongress Connect"

    def subtitle = "Developers, jobs and the people behind them."

    def footer = "Profiles · Jobs & gigs · Projects"

    def route = [:og_site_image, {}]

    def cache_key = ["site"]
  end
end
