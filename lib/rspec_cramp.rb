require File.join(File.dirname(__FILE__), "mock_response")
require 'cramp'

module Cramp
  
  # Monkey-patch so that even if there is an exception raised in on_start or in on_finish
  # the exception dump is rendered so that:
  # - you can match against it in your spec,
  # - get method doesn't time out waiting for anything to be rendered (may not be true for on_finish).
  #
  class Action
    alias :old_handle_exception :handle_exception
    def handle_exception(exception)
      if @_state != :init
        handler = ExceptionHandler.new(@env, exception)
        render handler.pretty
      end
      old_handle_exception(exception)
    end
  end
  
  # Usage:
  #
  # describe MyAction, :cramp => true do
  #   def app
  #     MyAction
  #   end
  # 
  #   it "should render home page" do
  #     get("/").should respond_with :status => :ok, :body => "Hello, world!"
  #   end
  # end
  #
  shared_context "given a Cramp application", :cramp => true do

    # In your describe block using :cramp => true, define a method called 'app' returning an async Rack application. 
    # Example:
    #
    #   def app
    #     HelloWorldAction
    #   end
    
    # Request helper method.
    #
    def request(method, path, options = {}, &block)
      raise "Unsupported request method" unless [:get, :post, :delete, :put].include?(method)
      if block
        async_request(method, path, options, &block)
      else
        sync_request(method, path, options)
      end
    end      
    
    # GET helper method.
    #
    def get(path, options = {}, &block)
      request(:get, path, options, &block)
    end

    # POST helper method.
    #
    def post(path, options = {}, &block)
      request(:post, path, options, &block)
    end

    # DELETE helper method.
    #
    def delete(path, options = {}, &block)
      request(:delete, path, options, &block)
    end

    # PUT helper method.
    #
    def put(path, options = {}, &block)
      request(:put, path, options, &block)
    end
    
    # Use it if using a block version of a request helper method.
    # See spec/examples/low_level_spec.rb for examples.
    #
    def stop
      EM.stop
    end
    
    # You can change the default timeout by overriding this method.
    #
    def default_timeout
      3
    end
    
    # respond_to RSpec matcher.
    # See spec/examples for sample usage.
    #
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
    
    before(:all) do 
      @request = Rack::MockRequest.new(app)
    end
    
    def async_request(method, path, options, &block)
      callback = parse_response(block)
      headers = prepare_http_headers(options.delete(:headers) || {}).merge('async.callback' => callback)
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
      async_request(method, path, options) do |result|
        if result.status.between?(200, 299)
          result.read_body(max_chunks)
        else
          EM.next_tick { EM.stop }
        end
        response = result
      end
      response
    end
    
    def parse_response(block)
      proc do |result|
        response = MockResponse.new(result)
        block.call(response)
      end
    end
    
    def prepare_http_headers(headers)
      headers.inject({}) {|acc, (k,v)| acc["HTTP_#{k.upcase.gsub("-", "_")}"] = v; acc}
    end
  end
end