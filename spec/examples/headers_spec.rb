require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "sample_actions")

describe CustomHeader, :cramp => true do
  def app
    CustomHeader
  end

  it "should render the value of the custom header" do
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should respond_with :body => /^SAMPLE VALUE$/
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should respond_with :body => "SAMPLE VALUE"
  end
  
  it "should include the custom header in response headers" do
    # Exact match using string & regex.
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should respond_with :headers => {"Custom-Header" => "SAMPLE VALUE"}
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should respond_with :headers => {"Custom-Header" => /^SAMPLE VALUE$/}

    # Header field names are case insensitive - use regex match.
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should respond_with :headers => {/Custom\-Header/i => "SAMPLE VALUE"}

    # Negative match.
    get("/", :headers => {"Custom-Header" => "SAMPLE VALUE"}).should_not respond_with :headers => {"Custom-Header" => "ANOTHER VALUE"}
  end
end