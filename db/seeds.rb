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
    Industry.create name: industry_name
  end
end
