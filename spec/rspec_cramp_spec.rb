require File.join(File.dirname(__FILE__), "spec_helper")

module Cramp
  
  describe "rspec-cramp" do
    class SuccessfulResponse < Cramp::Action
      on_start :render_and_finish
      def render_and_finish
        render "ok"
        finish
      end
    end

    class HelloWorldResponse < Cramp::Action
      on_start :render_and_finish
      def render_and_finish
        render "Hello, world"
        finish
      end
    end
    
    class MultipartResponse < Cramp::Action
      on_start :render_and_finish
      def render_and_finish
        render "part1"
        render "part2"
        finish
      end
    end

    class ErrorResponse < Cramp::Action
      on_start :just_finish
      def respond_with
        [500, {'Content-Type' => 'text/html'}]
      end
      def just_finish
        finish
      end
    end
    
    
    class RaiseBeforeStart < Cramp::Action
      before_start :raise_error
      def raise_error
        raise "Error in before_start"
      end
    end

    class RaiseOnStart < Cramp::Action
      on_start :raise_error
      def raise_error
        raise "Error in on_start"
      end
    end

    class RaiseOnFinish < Cramp::Action
      on_start :just_finish
      on_finish :raise_error
      def just_finish
        finish
      end
      def raise_error
        raise "Error in on_finish"
      end
    end
    
    class NoResponse < Cramp::Action
      on_start :noop
      def noop
      end
    end
    
    class CustomHeaders < Cramp::Action
      on_start :ok_and_finish
      def respond_with
        [200, {'Extra-Header' => 'ABCD', 'Another-One' => 'QWERTY'}]
      end
      def ok_and_finish
        render "ok"
        finish
      end
    end
    
    class SseAction < Cramp::Action
      self.transport = :sse
      periodic_timer :write_hello, :every => 0.5
      def write_hello
        @num ||= 1
        render "Hello #{@num}"
        @num += 1
      end
    end
    
    class SseNoRenderAction < Cramp::Action
      self.transport = :sse
    end

    class RequestHeaders < Cramp::Action
      on_start :render_request_headers
      def render_request_headers
        response = http_headers.inject("Request headers:\n") {|acc, (k,v)| acc << "#{k}: #{v}\n"; acc}
        render response
        finish
      end
      
      private
      
      def http_headers
        @env.inject({}){|acc, (k,v)| acc[$1.upcase] = v if k =~ /^http_(.*)/i; acc}
      end
    end
    
    class RequestParams < Cramp::Action
      on_start :render_and_finish
      def render_and_finish
        render params[:text]
        finish
      end
    end
      
    
    def routes
      HttpRouter.new do
        add('/200').to SuccessfulResponse
        add('/hello_world').to HelloWorldResponse
        add('/multipart').to MultipartResponse
        add('/500').to ErrorResponse
        add('/no_response').to NoResponse
        add('/custom_header').to CustomHeaders
        add('/raise_before_start').to RaiseBeforeStart
        add('/raise_on_start').to RaiseOnStart
        add('/raise_on_finish').to RaiseOnFinish
        add('/sse').to SseAction
        add('/sse_no_render').to SseNoRenderAction
        add('/get_only').request_method('GET').to SuccessfulResponse
        add('/post_only').request_method('POST').to SuccessfulResponse
        add('/put_only').request_method('PUT').to SuccessfulResponse
        add('/delete_only').request_method('DELETE').to SuccessfulResponse
        add('/request_headers').to RequestHeaders
        add('/request_params').to RequestParams
      end
    end
    
    describe "'respond_with' matcher", :cramp => true do
      def app
        routes
      end
      
      it "should raise error for unsupported match options" do
        lambda { get("/200").should respond_with :whatever => "ABC" }.should raise_error
      end

      shared_examples_for "async_request" do |method|

        describe "timeout" do
          it "- timeout when no response" do
            lambda { send(method, "/no_response") }.should raise_error Timeout::Error
          end
          it "- allow the timeout to be defined by the user" do
            lambda do
              timeout(2) do
                lambda {send(method, "/no_response", {:timeout => 1}) }.should raise_error Timeout::Error
              end
            end.should_not raise_error Timeout::Error
          end
        end
        
        describe "exact match on response status" do
          it "should match successful response" do
            send(method, "/200").should respond_with :status => 200
            send(method, "/200").should respond_with :status => "200"
            send(method, "/200").should respond_with :status => :ok
          end
          it "should match error response" do
            send(method, "/500").should respond_with :status => 500
            send(method, "/500").should respond_with :status => "500"
            send(method, "/500").should respond_with :status => :error
            send(method, "/500").should_not respond_with :status => 200
            send(method, "/500").should_not respond_with :status => "200"
            send(method, "/500").should_not respond_with :status => :ok
          end
          it "should match non-async errors from http router" do
            send(method, "/404").should respond_with :status => 404
            send(method, "/404").should respond_with :status => "404"
          end
        end

        describe "regex match on response status" do
          it "should match successful response" do
            send(method, "/200").should respond_with :status => /^2.*/
          end
          it "should match error response" do
            send(method, "/500").should respond_with :status => /^5.*/
            send(method, "/500").should_not respond_with :status => /^2.*/
          end
          it "should match non-sync errors from http router" do
            send(method, "/404").should respond_with :status => /^4.*/
          end
        end
        
        describe "lambda match on response status" do
          it "should match when true" do
            send(method, "/200").should respond_with :status => lambda {|status| status == 200}
          end
          it "should not match when false" do
            send(method, "/200").should_not respond_with :status => lambda {|status| status == 500}
          end
        end
        
        describe "exact match on response header values" do
          it "should match with one expected header" do
            send(method, "/custom_header").should respond_with :headers => {"Extra-Header" => "ABCD"}
          end
          it "should match all with two expected headers" do
            send(method, "/custom_header").should respond_with :headers => {"Extra-Header" => "ABCD", "Another-One" => "QWERTY"}
          end
          it "should not match if value does not match" do
            send(method, "/custom_header").should_not respond_with :headers => {"Extra-Header" => "1234"}
          end
          it "should not match iff the header isn't there" do
            send(method, "/custom_header").should_not respond_with :headers => {"Non-Existent-One" => "QWERTY"}
          end
        end
        
        describe "regex match on response header values" do
          it "should match with one expected header" do
            send(method, "/custom_header").should respond_with :headers => {"Extra-Header" => /^ABCD$/}
          end
          it "should match all with two expected headers" do
            send(method, "/custom_header").should respond_with :headers => {"Extra-Header" => /^ABCD$/, "Another-One" => /^QWERTY$/}
          end
          it "should not match if value does not match" do
            send(method, "/custom_header").should_not respond_with :headers => {"Extra-Header" => /^1234$/}
          end
          it "should not match iff the header isn't there" do
            send(method, "/custom_header").should_not respond_with :headers => {"Non-Existent-One" => /^QWERTY$/}
          end
        end

        describe "lambda match on response header values" do
          it "should match when true" do
            send(method, "/custom_header").should respond_with :headers => {"Extra-Header" => lambda {|value| value == "ABCD"}}
          end
          it "should not match when false" do
            send(method, "/custom_header").should_not respond_with :headers => {"Extra-Header" => lambda {|value| value == "WRONG"}}
          end
        end

        describe "regex match on response header fields" do
          it "should match with one expected header" do
            send(method, "/custom_header").should respond_with :headers => {/Extra\-Header/i => /^ABCD$/}
          end
          it "should match all with two expected headers" do
            send(method, "/custom_header").should respond_with :headers => {/Extra\-Header/i => /^ABCD$/, "Another-One" => /^QWERTY$/}
          end
          it "should not match if value does not match" do
            send(method, "/custom_header").should_not respond_with :headers => {/Extra\-Header/i => /^1234$/}
          end
          it "should not match iff the header isn't there" do
            send(method, "/custom_header").should_not respond_with :headers => {/Non\-Existent\-One/i => /^QWERTY$/}
          end
        end  
        
        describe "lambda match on entire header " do
          it "should match when true" do
            match_headers = lambda do |headers|
              headers.find {|(k, v)| k == "Extra-Header" && v == "ABCD"}
            end
            send(method, "/custom_header").should respond_with :headers => match_headers
          end
          it "should not match when false" do
            match_headers = lambda do |headers|
              headers.find {|(k, v)| k == "Non-Existent-One" && v == "QWERTY"}
            end
            send(method, "/custom_header").should_not respond_with :headers => match_headers
          end
        end
        
        # FIXME How to handle a situation where nothing is rendered? get reads the body...
        
        describe "exact match on response body" do
          it "should match with successful response" do
            send(method, "/200").should respond_with :body => "ok"
            send(method, "/200").should_not respond_with :body => "wrong"
          end
          it "should not load body on error response" do
            # TODO Not sure about this behaviour. What do you think? Use "Something went wrong"?
            send(method, "/500").should respond_with :body => /.*Cramp::Body.*/
          end
          it "should match non-async response from http router" do
            send(method, "/404").should respond_with :body => "Something went wrong"
          end
        end
        describe "regex match on response body" do
          it "should match the body" do
            send(method, "/hello_world").should respond_with :body => /.*Hello.*/
            send(method, "/hello_world").should_not respond_with :body => /.*incorrect.*/
          end
        end
   
        describe "lambda match on response body" do
          it "should match when true" do
            send(method, "/hello_world").should respond_with :body => lambda {|body| body =~ /.*Hello.*/}
          end
          it "should not match when false" do
            send(method, "/hello_world").should_not respond_with :body => lambda {|body| body =~ /.*incorrect.*/}
          end
        end
   
        describe "exact match on multipart response body" do
          it "should match with successful response" do
            send(method, "/multipart", :max_chunks => 2).should respond_with :body => "part1part2"
            send(method, "/multipart", :max_chunks => 2).should_not respond_with :body => "whatever"
          end
        end
        describe "regex match on multipart response body" do
          it "should match the body" do
            send(method, "/multipart", :max_chunks => 2).should respond_with :body => /.*part.*/
            send(method, "/multipart", :max_chunks => 2).should_not respond_with :body => /.*incorrect.*/
          end
        end
        
        describe "exact match on response body chunks" do
          it "should match with successful response" do
            send(method, "/multipart", :max_chunks => 2).should respond_with :chunks => ["part1", "part2"]
            send(method, "/multipart", :max_chunks => 2).should_not respond_with :chunks => ["whatever1", "whatever2"]
          end
        end
        describe "regex match on response body chunks" do
          # Note: In theory, an exact match would also work but because the content also contains an event-id, 
          # it is not practical.
          it "should match with successful response" do
            send(method, "/multipart", :max_chunks => 2).should respond_with :chunks => [/part1/, /part2/]
            send(method, "/multipart", :max_chunks => 2).should_not respond_with :chunks => [/whatever1/, /whatever2/]
          end
        end
        
        describe "lambda match on response body chunks" do
          it "should match when true" do
            send(method, "/multipart", :max_chunks => 2).should respond_with(:chunks => lambda do |chunks| 
              chunks[0] =~ /part1/ && chunks[1] =~ /part2/
            end)
          end
          it "should not match when false" do
            send(method, "/multipart", :max_chunks => 2).should_not respond_with(:chunks => lambda do |chunks| 
              chunks[0] =~ /whatever1/ || chunks[1] =~ /whatever2/
            end)
          end
        end

        
        describe "multiple conditions" do
          it "should match on status and body" do
            send(method, "/200").should respond_with :status => :ok, :body => "ok"
            send(method, "/200").should_not respond_with :status => :ok, :body => "incorrect"
            send(method, "/200").should_not respond_with :status => :error, :body => "ok"
          end
        end
        
        describe "sse support" do
          # Note: In theory, xact match would also work but because the content also contains an event-id, 
          # it is not practical.
          it "should match with successful response" do
            send(method, "/sse", :max_chunks => 2).should respond_with :chunks => [/^data: Hello 1.*/, /^data: Hello 2.*/]
            send(method, "/sse", :max_chunks => 2).should_not respond_with :chunks => [/.*Incorrect 1.*/, /.*Incorrect 2.*/]
          end

          it "should not wait for body if it is skipped explicitly" do
            lambda { send(method, "/sse_no_render", :max_chunks => 0) }.should_not raise_error Timeout::Error
            send(method, "/sse_no_render", :max_chunks => 0).should respond_with :status => 200, :body => ""
          end
        end
        
        it "should correctly handle exception in the callbacks" do
          send(method, "/raise_on_start").should respond_with :status => 200  # Unfortunately, the headers have been already sent.
        end
        
        describe "when an action raises an exception" do
          it "should handle error in before_start handler" do
            get("/raise_before_start").should respond_with :status => 500
          end

          it "should handle error in on_start handler" do
            # Headers were already sent by the time the exception was raised.
            get("/raise_on_start").should respond_with :body => /.*Error in on_start.*/, :status => 200 
          end

          it "should handle error in on_finish handler" do
            # Headers were already sent by the time the exception was raised.
            get("/raise_on_finish").should respond_with :body => /.*Error in on_finish.*/, :status => 200 
          end
        end
        
        it "should support custom request headers" do
          get("/request_headers", :headers => {"Custom1" => "ABC", "Custom2" => "DEF"}).should respond_with :body => /.*^Custom1: ABC$.*/i
          get("/request_headers", :headers => {"Custom1" => "ABC", "Custom2" => "DEF"}).should respond_with :body => /.*^Custom2: DEF$.*/i
        end
        
        it "should support request params" do
          get("/request_params", :params => {:text => "Hello, world!"}).should respond_with :body => "Hello, world!"
        end
        
        it "should pass body chunks to the block" do
          actual_chunks = []
          get("/sse", :max_chunks => 2).should respond_with(:chunks => lambda {|chunks| actual_chunks = chunks; true})
          actual_chunks.should have(2).elements
          actual_chunks[0].should include "Hello 1"
          actual_chunks[1].should include "Hello 2"
        end
      end
      
      describe "GET request" do
        it_should_behave_like "async_request", :get 
        
        it "should be able to access paths accessible only with GET" do
          get("/get_only").should respond_with :status => :ok
        end
        it "should not be able to access paths non-accessible with GET" do
          get("/post_only").should respond_with :status => 405
        end
      end

      describe "POST request" do
        it_should_behave_like "async_request", :post 

        it "should be able to access paths accessible only with POST" do
          post("/post_only").should respond_with :status => :ok
        end
        it "should not be able to access paths non-accessible with POST" do
          post("/get_only").should respond_with :status => 405
        end
      end
      
      describe "DELETE request" do
        it_should_behave_like "async_request", :delete

        it "should be able to access paths accessible only with DELETE" do
          delete("/delete_only").should respond_with :status => :ok
        end
        it "should not be able to access paths non-accessible with DELETE" do
          delete("/post_only").should respond_with :status => 405
        end
      end

      describe "PUT request" do
        it_should_behave_like "async_request", :put

        it "should be able to access paths accessible only with PUT" do
          put("/put_only").should respond_with :status => :ok
        end
        it "should not be able to access paths non-accessible with PUT" do
          put("/post_only").should respond_with :status => 405
        end
      end
    end
  
    # FIXME Better failure message for response matcher.
    describe "'be_matching' matcher", :cramp => true do
      def app
        routes
      end
      
      # Note: Only basic specs here because respond_with matcher uses the same code and is extensively tested.
       
      it "should support expectations on response status" do
        get("/200") do |response|
          response.should be_matching :status => 200
          response.should be_matching :status => :ok
          response.should_not be_matching :status => 500
          stop
        end
      end
      it "should support expectations on response body" do
        get("/200") do |response|
          response.read_body do
            response.body.should == ["ok"]
            response.body.should_not == ["whatever"]
          end
        end
      end
      it "should support array access" do
        get("/200") do |response|
          response[0].should == 200
          response[1].should be_a Hash
          response[2].should be_a Cramp::Body
          response[-1].should be_a Cramp::Body
          stop
        end
      end
      it "should handle exceptions in block" do
        lambda { get("/404") do |response|
          raise "this is an error"
        end }.should raise_error
      end
      
      describe "improper body access" do
        it "should warn user if body is accessed via an attribute without read_body" do
           get("/200") do |response|
             lambda { response.body }.should raise_error 
             stop
           end
         end       
         it "should warn user if body is accessed via an attribute outside read_body" do
           get("/200") do |response|
             response.read_body
             lambda { response.body }.should raise_error 
             stop
           end
         end
       end
    end
  end
end
