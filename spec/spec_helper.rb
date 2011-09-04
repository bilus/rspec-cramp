require "rubygems"
require "cramp"
require "rspec"
require "http_router"
require File.join(File.dirname(__FILE__), '../lib/rspec_cramp')

require 'active_support/buffered_logger'
logger = ActiveSupport::BufferedLogger.new(File.join(File.dirname(__FILE__), "tests.log"))
logger.level = ActiveSupport::BufferedLogger::DEBUG
Cramp.logger = logger