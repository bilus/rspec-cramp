A set of rspec matchers and helpers that make it easier to write specs for [cramp](http://cramp.in).

Quick start
-----------

	describe HelloWorld, :cramp => true do
	  def app
	    HelloWorld
	  end

	  it "should respond to a GET request" do
	    # Various ways to match a response code.
	    get("/").should respond_with :status => :ok         # Matches responses from 200 to 299.
	    get("/").should respond_with :status => 200         # Matches only 200.
	    get("/").should respond_with :status => "200"       # Same as above.
	    get("/").should respond_with :status => /^2.*/      # Matches response codes starting with 2.
	    get("/").should_not respond_with :status => :error  # Matches any HTTP error.
	  end

	  it "should respond with text starting with 'Hello'" do
	    get("/").should respond_with :body => /^Hello.*/
	  end

	  it "should respond with 'Hello, world!'" do
	    get("/").should respond_with :body => "Hello, world!"
	  end
  
	  it "should respond with html" do
	    get("/").should respond_with :header => {"Content-Type" => "text/html"}
	    get("/").should_not respond_with :header => {"Content-Type" => "text/plain"}
	    get("/").should_not respond_with :header => {"Unexpected-Header" => /.*/}
	  end
	end
	
The matcher is fairly flexible, supports regular expressions and also works with multipart responses (more than one `Cramp::Action.render`), SSE and so on. I'll create more examples and docs but for the time being, pls. take a look at the code.

**DISCLAIMER:** I haven't done any work with WebSockets yet so if there is anyone willing to add support for WebSockets, please [tweet me](http://twitter.com/#!/MartinBilski)

More examples: [spec/examples/](https://github.com/bilus/rspec-cramp/tree/master/spec/examples)

Project status
--------------	

**IMPORTANT:** This is work in progress. I haven't created a gem yet. 

1. There are still pending specs I'll take care of soon (esp. passing extra headers).
2. I extracted the code from one of my projects and rewrote the matchers from scratch test-first. Still, after the weekend I plan to actually use it to replace the 'legacy' matchers in my project; this will probably uncover some bugs and may make me add more functionality.

If you have any comments regarding the code as it is now (I know it's a bit messy), please feel free to tweet [@MartinBilski](http://twitter.com/#!/MartinBilski)

Notes
----

1. The previous version had a problem with exceptions raised in `on_start` or `on_finish` or with `on_start` that called `finish` without rendering anything because the request helper methods always try to read one body chunk after a successful response (200-299).   
  
	Actually, it wasn't a very big deal, the call would simply time out and raise `Timeout::Error` with a special error message hinting at the problem: *execution expired (No render call in action?*.
	
	In the latest version, I [monkey-patched `Cramp::Action`](https://github.com/bilus/rspec-cramp/tree/master/lib/rspec_cramp.rb) to dump the exception if it occurs in `on_start` or in `on_finish` but responding with "Some error has occurred" or something similar is also an option.
	
	See [this example spec](https://github.com/bilus/rspec-cramp/tree/master/spec/examples/errors_spec.rb) to see error handling in action.
	
	I'm definitely open to suggestions, especially how this can be fixed without the cramp surgery. Is the timeout better? Unfortunately, the matcher always loads one chunk of the body on successful response by default.

2. This work is based on [Pratik Naik's code](https://github.com/lifo/cramp/blob/master/lib/cramp/test_case.rb) and writing specs in a similar fashion is still supported though there is a helper for loading the body and a response matcher and some accessors to make your life easier.  

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
	
	In general, I recommend using the 'respond_with' matcher whenever possible; I think it makes the specs more readable because it hides some gory details (for good or bad). 
