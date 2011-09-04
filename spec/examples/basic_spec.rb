require 'cramp'
require File.join(File.dirname(__FILE__), '../../lib/rspec_cramp')

class HelloWorld < Cramp::Action
  def start
    render "Hello, world!"
    finish
  end
end

describe HelloWorld, :cramp => true do
  def app
    HelloWorld
  end

  it "should respond to a GET request" do
    get("/").should respond_with :status => :ok, :body => "Hello, world!"
    get("/").should_not respond_with :status => :error
  end
end