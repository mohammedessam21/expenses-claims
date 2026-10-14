module AuthHelpers
  def auth_headers(user)
    { "Authorization" => "Bearer #{user.generate_token_for(:auth)}" }
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
  config.include ActiveSupport::Testing::TimeHelpers
end
