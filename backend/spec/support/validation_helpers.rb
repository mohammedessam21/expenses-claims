module ValidationHelpers
  def errors_for(record, attribute)
    record.validate
    record.errors[attribute]
  end
end

RSpec.configure do |config|
  config.include ValidationHelpers, type: :model
end
