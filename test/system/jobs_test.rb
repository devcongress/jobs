require "application_system_test_case"

class JobsTest < ApplicationSystemTestCase
  setup do
    @job = jobs(:one)
  end

  test "visiting the index" do
    visit jobs_url
    assert_selector "h1", text: "Jobs"
  end

  test "creating a Job" do
    visit jobs_url
    click_on "New Job"

    fill_in "Company", with: @job.company
    fill_in "Contact Email", with: @job.contact_email
    fill_in "Duration", with: @job.duration
    fill_in "Perks", with: @job.perks
    fill_in "Phone", with: @job.phone
    fill_in "Poster Email", with: @job.poster_email
    fill_in "Poster Name", with: @job.poster_name
    fill_in "Qualification", with: @job.qualification
    fill_in "Requirements", with: @job.requirements
    fill_in "Role", with: @job.role
    fill_in "Salary", with: @job.salary
    click_on "Create Job"

    assert_text "Job was successfully created"
    click_on "Back"
  end

  test "updating a Job" do
    visit jobs_url
    click_on "Edit", match: :first

    fill_in "Company", with: @job.company
    fill_in "Contact Email", with: @job.contact_email
    fill_in "Duration", with: @job.duration
    fill_in "Perks", with: @job.perks
    fill_in "Phone", with: @job.phone
    fill_in "Poster Email", with: @job.poster_email
    fill_in "Poster Name", with: @job.poster_name
    fill_in "Qualification", with: @job.qualification
    fill_in "Requirements", with: @job.requirements
    fill_in "Role", with: @job.role
    fill_in "Salary", with: @job.salary
    click_on "Update Job"

    assert_text "Job was successfully updated"
    click_on "Back"
  end

  test "destroying a Job" do
    visit jobs_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Job was successfully destroyed"
  end
end
