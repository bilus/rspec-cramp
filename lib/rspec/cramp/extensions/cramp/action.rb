# Monkey-patch so that even if there is an exception raised in on_start or in on_finish
# the exception dump is rendered so that:
# - you can match against it in your spec,
# - get method doesn't time out waiting for anything to be rendered (may not be true for on_finish).
#
module Cramp
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
end