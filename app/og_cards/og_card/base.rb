# A 1200×630 link-preview image (og:image), drawn as SVG and rendered to PNG
# by libvips. Subclasses fill in the text; the layout lives in
# app/views/og_cards/card.svg.erb.
module OgCard
  class Base
    WIDTH = 1200
    HEIGHT = 630
    # Bump to re-render every card after a design change.
    DESIGN_VERSION = 2

    Avatar = Data.define(:initials, :color, :shape)

    def eyebrow = nil

    def title = raise(NotImplementedError)

    def subtitle = nil

    def body = nil

    def footer = nil

    def avatar = nil

    # The URL helper and params for the card's image route.
    def route = raise(NotImplementedError)

    # What the image depends on; any change gives the card a new URL.
    def cache_key = raise(NotImplementedError)

    def version = Digest::SHA256.hexdigest([DESIGN_VERSION, *cache_key].join("/")).first(16)

    def png
      Rails.cache.fetch(["og-card", version]) do
        Vips::Image.svgload_buffer(svg).write_to_buffer(".png")
      end
    end

    def svg
      ApplicationController.render(template: "og_cards/card", formats: [:svg], layout: false, locals: {card: self})
    end

    # Pango font descriptions matching the SVG template's text styles.
    FONTS = {
      title: "DM Serif Display 64", subtitle: "Inter 30", body: "Inter 28", footer: "Inter Bold 26"
    }.freeze

    # Word-wraps text into at most `lines` lines no wider than `width` pixels in
    # the given style, ending in an ellipsis when it doesn't fit. SVG text
    # doesn't wrap, so lines are measured with the same fonts librsvg uses.
    def self.wrap(text, style:, width:, lines: 1)
      font = FONTS.fetch(style)
      fits = ->(candidate) { text_width(candidate, font) <= width }
      words = text.to_s.squish.split
      result = []

      while words.any? && result.size < lines
        line = words.shift
        line = line.chop until line.size <= 1 || fits.call(line)
        line = "#{line} #{words.shift}" while words.any? && fits.call("#{line} #{words.first}")
        result << line
      end
      if words.any?
        last = result.pop
        last = last.chop.rstrip until last.size <= 1 || fits.call("#{last}…")
        result << "#{last}…"
      end
      result
    end

    def self.text_width(text, font)
      Vips::Image.text(ERB::Util.html_escape(text), font:, dpi: 72).width
    end

    def self.wordmark_data_uri
      @wordmark_data_uri ||= "data:image/png;base64,#{Base64.strict_encode64(Rails.root.join("app/assets/images/brand/devcongress-wordmark.png").binread)}"
    end

    private

    def avatar_for(name, seed:, shape: :circle)
      Avatar.new(InitialsAvatar.initials_for(name), InitialsAvatar.hex_for(seed), shape)
    end
  end
end
