# Building blocks for HTML emails. Mail clients ignore most stylesheets, so
# every style is inline and layout uses tables.
module EmailHelper
  INK = "#111111"
  PINK = "#D10F72" # primary-600: passes AA contrast with white text
  CREAM = "#F5F2E8"
  MUTED = "#55524B"
  FONT = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Inter, Roboto, Helvetica, Arial, sans-serif"
  SERIF = "'DM Serif Display', Georgia, 'Times New Roman', serif"

  def email_heading(text)
    tag.h1 text, style: "margin:0 0 16px;font-family:#{SERIF};font-size:28px;line-height:1.2;font-weight:400;color:#{INK};"
  end

  def email_paragraph(content = nil, &)
    tag.p(content, style: "margin:0 0 16px;font-size:16px;line-height:1.6;color:#{INK};", &)
  end

  def email_muted(content = nil, &)
    tag.p(content, style: "margin:0 0 12px;font-size:13px;line-height:1.5;color:#{MUTED};", &)
  end

  # A pill button built from a table so it renders in Outlook too.
  def email_button(label, url)
    tag.table(role: "presentation", cellpadding: 0, cellspacing: 0, border: 0, style: "margin:8px 0 24px;") do
      tag.tr do
        tag.td(style: "border-radius:999px;background:#{PINK};") do
          link_to label, url, style: "display:inline-block;padding:13px 26px;border-radius:999px;font-family:#{FONT};font-size:16px;font-weight:600;line-height:1;color:#ffffff;text-decoration:none;"
        end
      end
    end
  end

  # The plain link under a button, for clients that block or mangle buttons.
  def email_link_fallback(url)
    email_muted do
      safe_join(["Button not working? Paste this link into your browser:", tag.br,
        link_to(url, url, style: "color:#{PINK};word-break:break-all;")])
    end
  end

  # A highlighted box in the DevCongress card style: ink border on cream.
  def email_panel(&)
    tag.table(role: "presentation", width: "100%", cellpadding: 0, cellspacing: 0, border: 0, style: "margin:0 0 24px;") do
      tag.tr do
        tag.td(style: "padding:16px 20px;background:#{CREAM};border:2px solid #{INK};border-radius:12px;font-size:15px;line-height:1.5;color:#{INK};", &)
      end
    end
  end

  # Title plus a muted detail line, used inside panels.
  def email_panel_title(title, detail = nil)
    safe_join([
      tag.div(title, style: "font-size:17px;font-weight:700;color:#{INK};"),
      (tag.div(detail, style: "margin-top:4px;font-size:14px;color:#{MUTED};") if detail.present?)
    ].compact)
  end

  def email_link(label, url)
    link_to label, url, style: "color:#{PINK};font-weight:600;"
  end
end
