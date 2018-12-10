json.array! @matches do |match|
  json.(
    match,
    :created_at,
    :role,
    :duration,
    :salary,
    :requirements,
    :qualification,
    :perks,
    :remote_ok,
    :city,
    :country,
    :apply_link)
  json.url job_url(match)

  json.company(
    match.company,
    :name,
    :industry,
    :logo,
    :website,
    :description,
    :city,
    :state_or_region,
    :post_code,
    :country)
end
