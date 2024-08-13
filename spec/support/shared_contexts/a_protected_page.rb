RSpec.shared_examples "a protected page" do |path, return_path: '/'|
  scenario "redirects to the root page when accessed by an anonymous user" do
    visit path

    expect(page).to have_current_path(return_path)
  end
end