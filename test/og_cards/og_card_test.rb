require "test_helper"

class OgCardTest < ActiveSupport::TestCase
  test "wrap fits words into lines by measured width and ends with an ellipsis when it runs out" do
    title = "Senior Backend Engineer for Payments Infrastructure and Reliability"
    lines = OgCard::Base.wrap(title, style: :title, width: 500, lines: 2)

    assert_equal 2, lines.size
    assert lines.last.end_with?("…")
    lines.each { |line| assert_operator OgCard::Base.text_width(line, OgCard::Base::FONTS[:title]), :<=, 500 }
    assert_equal ["Short"], OgCard::Base.wrap("Short", style: :title, width: 500, lines: 2)
    assert_equal [], OgCard::Base.wrap(nil, style: :body, width: 500)
  end

  test "wrap cuts a single word that is too wide on its own" do
    line = OgCard::Base.wrap("Supercalifragilisticexpialidocious", style: :title, width: 300).sole

    assert_operator OgCard::Base.text_width(line, OgCard::Base::FONTS[:title]), :<=, 300
  end

  test "user text is escaped in the SVG" do
    profile = Developers::Profile.new(name: "<Ada & co>", handle: "ada", headline: "</text><script/>", availability: :open)

    svg = OgCard::Developer.new(profile).svg
    assert_includes svg, "&lt;Ada &amp; co&gt;"
    assert_not_includes svg, "<script/>"
    assert Nokogiri::XML(svg) { |config| config.strict }
  end

  test "the version changes when the record does" do
    profile = Developers::Profile.new(name: "Ada", handle: "ada", availability: :open, updated_at: 1.day.ago, id: 1)
    before = OgCard::Developer.new(profile).version
    profile.updated_at = Time.current

    assert_not_equal before, OgCard::Developer.new(profile).version
  end
end
