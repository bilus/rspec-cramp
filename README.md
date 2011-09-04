Rspec-cramp is a simple library to make it easier to write specs for [cramp](http://cramp.in).

Quick start
-----------

	require 'rspec_cramp'

	describe MyCrampAction, :cramp => true do
		def app
			MyCrampAction
		end
		
		it "should respond to a GET request" do
			get("/").should respond_with :status => :ok, :body => "Hello, world!"
		end
	end
	
Take a look at [spec/examples/](https://github.com/bilus/rspec-cramp/tree/master/spec/examples)

Project status
--------------	

*Important:* This is work in progress. I haven't created a gem yet. 

1. For the time being, only GET request method is supported.
2. There are still pending specs I'll take care of soon (esp. passing extra headers).
3. I extracted the code from one of my projects and wrote the matchers from scratch test-first. Still, I plan to actually use it to replace the 'legacy' matchers in my project; this will probably uncover some bugs.

Some other stuff to do:

- rspec_cramp_spec.rb (245)	 Better failure message for response matcher.
- mock_response.rb (57)	 Better failure message showing the specific mismatches that made it fail.
- mock_response.rb (61)	 Better failure message showing the specific successful matches that made it fail.
- rspec_cramp_spec.rb (102)	 Rewrite the repetitive code below using data-based spec generation.
- rspec_cramp_spec.rb (174)	 Not sure about this behaviour. What do you think? Use "Something went wrong"?
- rspec_cramp_spec.rb (247)	 Only basic matching here because respond_with matcher uses the same method.

If you have any comments regarding the code as it is now (I know it's a bit messy), please feel free to tweet [@MartinBilski](http://twitter.com/#!/MartinBilski)