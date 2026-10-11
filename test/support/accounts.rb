module AccountsTestHelper
  def create_user!(email: "dev#{SecureRandom.hex(4)}@example.com")
    User.create!(email:, status: :verified, password_hash: BCrypt::Password.create("password123"))
  end

  def create_profile!(user: create_user!, name: "Ada Lovelace", **attributes)
    first_name, other_names = name.split(" ", 2)
    user.create_developer_profile!(first_name:, other_names:, handle: "ada-#{SecureRandom.hex(3)}", **attributes)
  end

  def create_company!(owner: nil, name: "Company #{SecureRandom.hex(3)}")
    Company.create!(name:).tap do |company|
      company.company_users.create!(user: owner, role: :owner) if owner
    end
  end

  # Published jobs are approved too unless review: true (first-job review).
  def create_job!(company:, published: true, review: false, **attributes)
    job = company.job_posts.create!(title: "Backend Engineer", description: "Build things.", **attributes)
    return job unless published

    company.update!(jobs_trusted_at: Time.current) unless review || company.jobs_trusted?
    job.publish!
    job
  end

  # Logs in and follows the post-login redirects (/welcome checks for invites first).
  def login_user(user)
    login_as(user, portal: :user)
    follow_redirect! while response.redirect?
  end
end
