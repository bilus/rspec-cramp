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

Project status
--------------	

*Important:* This is work in progress. I haven't created a gem yet. 

1. For the time being, only GET request method is supported.
2. There are still pending specs I'll take care of soon (esp. passing extra headers).
3. I extracted the code from one of my projects and wrote the matchers from scratch test-first. Still, I plan to actually use it to replace the 'legacy' matchers in my project; this will probably uncover some bugs.

If you have any comments regarding the code as it is now (I know it's a bit messy), please feel free to tweet [@MartinBilski](http://twitter.com/#!/MartinBilski)