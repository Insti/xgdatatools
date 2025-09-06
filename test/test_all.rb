#!/usr/bin/env ruby
## test/test_all.rb
require_relative "test_helper"

# Require all test files (do NOT use system calls)
require_relative "test_xgutils"
require_relative "test_xgstruct"
require_relative "test_xgzarc"
require_relative "test_xgimport"

# Minitest will autorun all tests at exit
