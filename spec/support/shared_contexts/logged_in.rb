RSpec.shared_context "logged_in", shared_context: :metadata do
  before do
    @original_dev_user = ENV['DEV_USER']
    ENV['DEV_USER'] = 'harry.boyes@gmail.com'
  end

  after do
    ENV['DEV_USER'] = @original_dev_user
  end
end
