RSpec.shared_context "logged_in" do |admin: false|
  before do
    @original_dev_user = ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER']
    ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER'] = 'harry.boyes@gmail.com'
  end

  after do
    ENV[admin ? 'DEV_USER' : 'DEV_NONADMIN_USER'] = @original_dev_user
  end
end
