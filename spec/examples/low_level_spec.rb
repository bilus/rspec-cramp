require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "sample_actions")

describe HelloWorld, :cramp => true do
	def app
		HelloWorld
	end

	it "should respond to a GET request" do
		get("/") do |response|
			response.status.should == 200
			response.headers.should have_key "Content-Type"
			response.should be_matching :status => :ok
			stop # This is important.
		end
	end
	it "should match the body" do
		get("/") do |response|
			response.read_body do
				response.body.should include "Hello, world!"  # MockResponse::body returns an Array.
				response.should be_matching :body => "Hello, world!"
				# Note: no call to stop here.
			end
		end
	end
end