require 'cramp'

class HelloWorld < Cramp::Action
  def start
    render "Hello, world!"
    finish
  end
end