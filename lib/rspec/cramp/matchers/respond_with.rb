# respond_to RSpec matcher.
# See spec/examples for sample usage.
#
RSpec::Matchers.define :respond_with do |options = {}|
  match do |response|
    @actual_response = response
    response.matching?(options)
  end
  
  failure_message_for_should do
    @actual_response.last_failure_message_for_should
  end
  failure_message_for_should_not do
    @actual_response.last_failure_message_for_should_not
  end
end