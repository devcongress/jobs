require "active_storage/vips"

# OG cards (app/og_cards) are SVG rendered to PNG by libvips.
#
# Point fontconfig at config/fonts.conf so they render in the brand fonts on
# any machine. Fontconfig reads this once, the first time text is rendered.
ENV["FONTCONFIG_FILE"] = Rails.root.join("config/fonts.conf").to_s

# Active Storage blocks libvips loaders that aren't fuzzed against untrusted
# input, SVG among them. The only SVG libvips sees here is the one OgCard
# builds, with user text escaped; uploads go through Shrine and are never
# handed to libvips. Re-enable that one loader.
Vips.block("VipsForeignLoadSvg", false)
