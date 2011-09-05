require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "sample_actions")

describe HelloWorld, :cramp => true do
  def app
    HelloWorld
  end

  it "should respond to a GET request" do
    # Variaus ways to match a response code.
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
    get("/").should respond_with :headers => {"Content-Type" => "text/html"}
    get("/").should_not respond_with :headers => {"Content-Type" => "text/plain"}
    get("/").should_not respond_with :headers => {"Unexpected-Header" => /.*/}
  end
end