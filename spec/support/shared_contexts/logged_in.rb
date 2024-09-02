RSpec.shared_context "logged_in" do |admin: false|
  let(:climber) { 'harry.boyes@gmail.com' }
  let(:logged_in_user) { User.find_by(reference: climber) || create(:user, reference: climber, place: Place.first) }

  before do
    @original_dev_user = ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER']
    ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER'] = climber
  end

  after do
    ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER'] = @original_dev_user
  end
end
