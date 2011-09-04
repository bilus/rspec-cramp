require File.join(File.dirname(__FILE__), "../spec_helper")
require File.join(File.dirname(__FILE__), "sample_actions")

describe "Error handling", :cramp => true do
  def app
    HttpRouter.new do
      add('/error_before_start').to ErrorBeforeStart
      add('/error_on_start').to ErrorOnStart
      add('/error_on_finish').to ErrorOnFinish
    end
  end

  it "should handle error in before_start handler" do
    get("/error_before_start").should respond_with :status => 500
  end

  it "should handle error in on_start handler" do
    # Headers were already sent by the time the exception was raised.
    get("/error_on_start").should respond_with :body => /.*Error in on_start.*/, :status => 200 
  end
  
  it "should handle error in on_finish handler" do
    # Headers were already sent by the time the exception was raised.
    get("/error_on_finish").should respond_with :body => /.*Error in on_finish.*/, :status => 200 
  end
end