require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "sample_actions")

# Decorate your spec with :cramp => true
describe HelloWorld, :cramp => true do
  
  # You need to define this method
  def app
    HelloWorld # Here goes your cramp application, action or http routes.
  end

  # Matching on status code.
  it "should respond to a GET request" do
    get("/").should respond_with :status => :ok         # Matches responses from 200 to 299.
    get("/").should respond_with :status => 200         # Matches only 200.
    get("/").should respond_with :status => "200"       # Same as above.
    get("/").should respond_with :status => /^2.*/      # Matches response codes starting with 2.
    get("/").should_not respond_with :status => :error  # Matches any HTTP error.
  end

  # Matching on response body.
  it "should respond with text starting with 'Hello'" do
    get("/").should respond_with :body => /^Hello.*/
  end
  it "should respond with 'Hello, world!'" do
    get("/").should respond_with :body => "Hello, world!"
  end
  
  # Matching on response headers.
  it "should respond with html" do
    get("/").should respond_with :headers => {"Content-Type" => "text/html"}
    get("/").should_not respond_with :headers => {"Content-Type" => "text/plain"}
    get("/").should_not respond_with :headers => {"Unexpected-Header" => /.*/}
  end
  
  # Matching using lambdas.
  it "should match my sophisticated custom matchers" do
    # Entire headers.
    status_check = lambda {|status| status.between?(200, 299)}
    body_check = lambda {|body| body =~ /.*el.*/}
    headers_check = lambda {|headers| true} # Any headers will do.
    get("/").should respond_with :status => status_check, :body => body_check, :headers => headers_check
    # Header value.
    get("/").should respond_with :headers => {"Content-Type" => lambda {|value| value == "text/html"}}
    get("/").should_not respond_with :headers => {"Content-Type" => lambda {|value| value == "text/plain"}}
  end
  
  # Supports POST/GET/PUT/DELETE and you don't have to use the matcher.
  it "should work without a matcher" do
    get "/"
    post "/"
    put "/"
    delete "/"
  end
  
  # Request params & custom headers.
  it "should accept my params" do
    post("/", :params => {:text => "whatever"}, :headers => {"Custom-Header" => "blah"})
  end
end