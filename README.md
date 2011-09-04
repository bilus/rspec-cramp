Rspec-cramp is a simple library to make it easier to write specs for [cramp](http://cramp.in).

Quick start
-----------

	describe MyCrampAction, :cramp => true do
		def app
			MyCrampAction
		end
		
		it "should respond to a GET request" do
			get("/").should respond_with :status => :ok, :body => "Hello, world!"
		end
	end
	
The matcher is fairly flexible and also works with multipart responses (more than one Cramp::Action.render), SSE and so on. I'll create more examples and docs but for the time being, pls. take a look at the code.

Take a look at [spec/examples/](https://github.com/bilus/rspec-cramp/tree/master/spec/examples)

This work is based on [Naik Pratik's code](https://github.com/lifo/cramp/blob/master/lib/cramp/test_case.rb) and writing specs in a similar fashion is still supported though there is a helper for loading the body and a response matcher.

	describe MyCrampAction, :cramp => true do
		def app
			MyCrampAction
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
 

Project status
--------------	

*Important:* This is work in progress. I haven't created a gem yet. 

1. For the time being, only GET request method is supported.
2. There are still pending specs I'll take care of soon (esp. passing extra headers).
3. I extracted the code from one of my projects and wrote the matchers from scratch test-first. Still, I plan to actually use it to replace the 'legacy' matchers in my project; this will probably uncover some bugs.

Some other stuff to do:

- rspec_cramp_spec.rb - Better failure message for response matcher.
- mock_response.rb - Better failure message showing the specific mismatches that made it fail.
- mock_response.rb - Better failure message showing the specific successful matches that made it fail.
- rspec_cramp_spec.rb - Rewrite the repetitive code below using data-based spec generation.
- rspec_cramp_spec.rb - Not sure about this behaviour. What do you think? Use "Something went wrong"?
- rspec_cramp_spec.rb - Only basic matching here because respond_with matcher uses the same method.

If you have any comments regarding the code as it is now (I know it's a bit messy), please feel free to tweet [@MartinBilski](http://twitter.com/#!/MartinBilski)