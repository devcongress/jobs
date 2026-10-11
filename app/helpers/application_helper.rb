module ApplicationHelper
  # A "dev:word{};" label coloured like the DevCongress logo: pink "dev",
  # black punctuation, grey word and braces.
  def dev_mark(word)
    tag.span(class: "whitespace-nowrap") do
      safe_join([
        tag.span("dev", class: "text-[#e8117f]"),
        tag.span(":", class: "text-[#111]"),
        tag.span("#{word}{}", class: "text-[#555]"),
        tag.span(";", class: "text-[#111]")
      ])
    end
  end
end
