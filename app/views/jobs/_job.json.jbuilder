json.extract! job, :id, :role, :duration, :salary, :requirements, :qualification, :perks, :company, :contact_email, :poster_name, :poster_email, :phone, :created_at, :updated_at
json.url job_url(job, format: :json)
