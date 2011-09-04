require File.join(File.dirname(__FILE__), "mock_response")

module Cramp
  
  # Usage:
  # describe MyAction, :cramp => true do
  #   def app
  #     MyAction
  #   end
  # 
  #   it "should render home page" do
  #     get("/").should respond_with :status => :ok, :body => "Hello, world!"
  #   end
  # end
  shared_context "given a Cramp application", :cramp => true do
    before(:all) do 
      @request = Rack::MockRequest.new(app)
    end
    
    def get(path, options = {}, &block)
      if block
        async_request(:get, path, options, &block)
      else
        sync_request(:get, path, options)
      end
    end
    
    def stop
      EM.stop
    end
    
    def default_timeout
      3
    end
    
    RSpec::Matchers.define :respond_with do |options = {}|
      match do |response|
        @actual_response = response
        response.matching?(options)
      end
      
      failure_message_for_should do
        @actual_response.last_failure_message_for_should
      end
      failure_message_for_should_not do
        @actual_response.last_failure_message_for_should_not
      end
    end
    
    private
    
    def async_request(method, path, options, &block)
      callback = build_response(block)
      headers = {'async.callback' => callback}
      timeout_secs = options.delete(:timeout) || default_timeout
      begin
        timeout(timeout_secs) do
          EM.run do
            catch(:async) do
              result = @request.send(method, path, headers)
              callback.call([result.status, result.header, "Something went wrong"])
            end
          end
        end
      rescue Timeout::Error => e
        raise Timeout::Error.new(e.message + " (No render call in action?)")
      end
    end
    
    def sync_request(method, path, options)
      max_chunks = options.delete(:max_chunks) || 1
      response = nil
      async_request(:get, path, options) do |result|
        if result.status.between?(200, 299)
          result.read_body(max_chunks)
        else
          EM.next_tick { EM.stop }
        end
        response = result
      end
      response
    end
    
    def build_response(block)
      proc do |result|
        response = MockResponse.new(result)
        block.call(response)
      end
    end
  end
end