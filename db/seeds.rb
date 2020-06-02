# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
#
# Industries:
# Initial list of known industries.

open("https://gist.githubusercontent.com/claudey/679c682e4291d7b54059c7c19b1dfdf2/raw/3687da0264ca4fa6867d12b561c164a8b9c29af6/industries.txt", "r") do |content|
  content.each_line do |industry_name|
    Industry.where(name: industry_name.chomp!)
      .first_or_create.update_attributes({name: industry_name})
  end
end

# Add a default test user
User.where(email: "test@example.com")
  .first_or_create.update_attributes({ 
    email: 'test@example.com', 
    password: 'password1', 
    password_confirmation: 'password1' 
  })

companies = [
  {
    name: 'Acme Inc', 
    industry: 'Entertainment', 
    description: 'We are leaders in creating fun stuff.',
    website: 'https://www.acmeinc.example.com/',
    email: 'info@acmeinc.example.com',
    phone: '012345657',
    city: 'Lego',
    state_or_region: 'Alb',
    post_code: '12029',
    country: 'Somewhere'
  },
  {
    name: 'Brick House', 
    industry: 'Media', 
    description: 'We build playable bricks.',
    website: 'https://brickhouse.example.com/',
    email: 'info@brickhouse.example.com',
    phone: '01234687',
    city: 'Lego',
    state_or_region: 'Alb',
    post_code: '12022',
    country: 'Somewhere'
  },
  {
    name: 'Cool Tech', 
    industry: 'Education', 
    description: 'We are leaders cool technology.',
    website: 'https://cooltech.example.com/',
    email: 'info@cooltech.example.com',
    phone: '01234565789',
    city: 'Lego',
    state_or_region: 'Alb',
    post_code: '12029',
    country: 'Somewhere'
  }
]

user = User.find_by(email: "test@example.com")

# Add some default companies and add relationship to test user
companies.each do |company|
  Company.where(email: company[:email])
    .first_or_create.update_attributes(company)
  
  c = Company.find_by(email: company[:email])
  unless user.companies.exists?(c.id)
    user.companies << c
  end
end

jobs = [
  {
    role: 'Software Engineer',
    duration: 'Full-Time',
    salary: 'USD 500 - 1k',
    requirements: 'Some stuff',
    qualification: '*Have a diploma*',
    perks: '- Free lunch',
    city: 'Port 1',
    country: 'Fya',
    company_id: 1,
    apply_link: 'https://jobs.devcongress.org/jobs/44-software-developer-petra-trust',
  },
  {
    role: 'Senior Software Engineer',
    duration: 'Full-Time',
    salary: 'USD 2 - 3k',
    requirements: 'Some stuff',
    qualification: '*Have a degree*',
    perks: '- Free lunch',
    city: 'Port 1',
    country: 'Fya',
    company_id: 1,
    apply_link: 'https://jobs.devcongress.org/jobs/44-software-developer-petra-trust',
  },
  {
    role: 'User Experience Designer',
    duration: 'Full-Time',
    salary: 'USD 1 - 2k',
    requirements: 'Good eyes for design',
    qualification: '*Have existing experience*',
    perks: '- Free lunch',
    city: 'Port 44',
    country: 'Fya',
    company_id: 2,
    apply_link: 'https://jobs.devcongress.org/jobs/44-software-developer-petra-trust',
  },
  {
    role: 'Technical Writer',
    duration: 'Full-Time',
    salary: 'USD 500 - 1k',
    requirements: 'Some stuff',
    qualification: '*Have a diploma*',
    perks: '- Free lunch',
    remote_ok: 'True',
    city: 'Port 24',
    country: 'Fya',
    company_id: 3,
    apply_link: 'https://jobs.devcongress.org/jobs/44-software-developer-petra-trust',
  },
]

jobs.each do |job|
  puts job[:role]
  Job.where(role: job[:role], requirements: job[:requirements])
    .first_or_create.update_attributes(job)
  
  j = Job.find_by(role: job[:role], requirements: job[:requirements])
  j.renewals.create([{:renewed_on => 5.days.from_now}])
end
