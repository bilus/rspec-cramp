class HelloWorld < Cramp::Action
  def start
    render "Hello, world!"
    finish
  end
end

class ErrorOnStart < Cramp::Action
  on_start :raise_error
  def raise_error
    raise "Error in on_start"
  end
end

class ErrorBeforeStart < Cramp::Action
  before_start :raise_error
  def raise_error
    raise "Error in before_start"
  end
end

class ErrorOnFinish < Cramp::Action
  on_start :just_finish
  on_finish :raise_error
  def just_finish
    finish
  end
  def raise_error
    raise "Error in on_finish"
  end
end

class CustomHeader < Cramp::Action
  on_start :render_custom_header
  def respond_with
    [200, {'Content-Type' => 'text/html', 'Custom-Header' => @env["HTTP_CUSTOM_HEADER"]}]
  end
  def render_custom_header
    render @env["HTTP_CUSTOM_HEADER"]
    finish
  end
end
