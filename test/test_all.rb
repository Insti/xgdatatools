#!/usr/bin/env ruby
# Test runner for all xgdatatools tests

require_relative "test_helper"

# Require all test files
test_files = [
  "test_xgutils.rb",
  "test_xgstruct.rb",
  "test_xgzarc.rb",
  "test_xgimport.rb"
]

puts "Running all xgdatatools tests..."
puts "=" * 50

total_runs = 0
total_assertions = 0
total_failures = 0
total_errors = 0
total_skips = 0

test_files.each do |test_file|
  puts "\nRunning #{test_file}..."
  puts "-" * 30

  # Capture the output
  result = `ruby #{test_file} 2>&1`
  exit_status = $?.exitstatus

  puts result

  # Parse the result summary
  if result =~ /(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors, (\d+) skips/
    runs, assertions, failures, errors, skips = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i
    total_runs += runs
    total_assertions += assertions
    total_failures += failures
    total_errors += errors
    total_skips += skips
  end

  if exit_status != 0
    puts "❌ #{test_file} FAILED"
  else
    puts "✅ #{test_file} PASSED"
  end
end

puts "\n" + "=" * 50
puts "TOTAL SUMMARY:"
puts "Runs: #{total_runs}"
puts "Assertions: #{total_assertions}"
puts "Failures: #{total_failures}"
puts "Errors: #{total_errors}"
puts "Skips: #{total_skips}"

if total_failures == 0 && total_errors == 0
  puts "\n🎉 ALL TESTS PASSED!"
  exit 0
else
  puts "\n💥 SOME TESTS FAILED!"
  exit 1
end
