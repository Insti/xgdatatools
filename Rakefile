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

desc "Run XGFileParser tests"
task :test_xgfile_parser do
  ruby "test/test_xgfile_parser.rb"
end

desc "Run XGDataTools tests"
task :test_xgdatatools do
  ruby "test/test_xgdatatools.rb"
end

desc "Run XGBinaryExtract tests"
task :test_xgbinaryextract do
  ruby "test/test_xgbinaryextract.rb"
end

desc "Run Board Alignment tests"
task :test_board_alignment do
  ruby "test/test_board_alignment.rb"
end

desc "Run Cube Class Integration tests"
task :test_cube_class_integration do
  ruby "test/test_cube_class_integration.rb"
end

desc "Run Goal Board Format tests"
task :test_goal_board_format do
  ruby "test/test_goal_board_format.rb"
end

desc "Run Move Class Integration tests"
task :test_move_class_integration do
  ruby "test/test_move_class_integration.rb"
end

task default: :test
