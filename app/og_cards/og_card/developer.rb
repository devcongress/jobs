module OgCard
  class Developer < Base
    def initialize(profile)
      @profile = profile
    end

    def eyebrow = "Developer"

    def title = @profile.name

    def subtitle = "@#{@profile.handle}"

    def body = @profile.headline

    def footer
      [[@profile.city, @profile.country].compact_blank.join(", ").presence,
        SiteHelper::AVAILABILITY.fetch(@profile.availability).first].compact.join(" · ")
    end

    def avatar = avatar_for(@profile.name, seed: @profile.handle)

    def route = [:og_developer_image, {handle: @profile.handle}]

    def cache_key = ["developer", @profile.cache_key_with_version]
  end
end
