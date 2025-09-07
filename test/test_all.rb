#!/usr/bin/env ruby
## test/test_all.rb
require_relative "test_helper"

# Dynamically require all test files in the test directory
test_dir = File.dirname(__FILE__)
test_files = Dir.glob(File.join(test_dir, "test_*.rb")).sort

test_files.each do |test_file|
  test_name = File.basename(test_file, ".rb")
  # Skip test_all.rb and test_helper.rb
  unless test_name == "test_all" || test_name == "test_helper"
    require_relative test_name
  end
end

# Minitest will autorun all tests at exit
