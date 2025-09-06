require "rake/testtask"

desc "Run all tests"
task :test do
  ruby "test/test_all.rb"
end

desc "Run all tests with coverage report"
task :coverage do
  puts "Running tests with coverage analysis..."
  ruby "test/test_all.rb"
  puts "\nCoverage report generated in coverage/ directory"
  puts "Open coverage/index.html in a browser to view the report"
end

desc "Run XGUtils tests"
task :test_xgutils do
  ruby "test/test_xgutils.rb"
end

desc "Run XGStruct tests"
task :test_xgstruct do
  ruby "test/test_xgstruct.rb"
end

desc "Run XGZarc tests"
task :test_xgzarc do
  ruby "test/test_xgzarc.rb"
end

desc "Run XGImport tests"
task :test_xgimport do
  ruby "test/test_xgimport.rb"
end

desc "Run ExtractXGData tests"
task :test_extractxgdata do
  ruby "test/test_extractxgdata.rb"
end

task default: :test
