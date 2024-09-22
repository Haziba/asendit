RSpec.shared_context "logged_in" do |admin: false|
  let(:logged_in_user) { User.first || create(:user, place: create(:place, :with_grades), admin: admin) }

  before do
    logged_in_user.place.update(user: logged_in_user)

    @original_dev_user = ENV['DEV_USER']
    ENV['DEV_USER'] = logged_in_user.id.to_s
  end

  after do
    ENV['DEV_USER'] = @original_dev_user
  end
end
