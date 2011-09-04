require File.join(File.dirname(__FILE__), 'sample_actions')
require File.join(File.dirname(__FILE__), '../../lib/rspec_cramp')

describe HelloWorld, :cramp => true do
	def app
		HelloWorld
	end

	it "should respond to a GET request" do
		get("/") do |response|
			response.should be_matching :status => :ok
			stop # This is important.
		end
	end
	
	it "should match the body" do
		get("/") do |response|
			response.read_body do
				response.should be_matching :body => "Hello, world!"
				# Note: no call to stop here.
			end
		end
	end
end