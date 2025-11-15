$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "toon"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
