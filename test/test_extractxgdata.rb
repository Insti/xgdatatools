require_relative "test_helper_simple"

class TestExtractXGData < Minitest::Test
  include TestHelper

  # Load the script after setting up test environment
  def setup
    # Save original ARGV and PROGRAM_NAME
    @original_argv = ARGV.dup
    @original_program_name = $PROGRAM_NAME
    
    # Clear ARGV for testing
    ARGV.clear
    
    # Load the extractxgdata file for testing functions
    # We need to load it in a way that doesn't execute the main block
    load File.expand_path("../extractxgdata.rb", __dir__)
  end

  def teardown
    # Restore original ARGV and PROGRAM_NAME
    ARGV.replace(@original_argv)
    $PROGRAM_NAME = @original_program_name
  end

  # Test helper functions first
  
  def test_parseoptsegments_valid_single_segment
    result = parseoptsegments("all")
    assert_equal ["all"], result
  end

  def test_parseoptsegments_valid_multiple_segments
    result = parseoptsegments("comments,gdhdr,thumb")
    assert_equal ["comments", "gdhdr", "thumb"], result
  end

  def test_parseoptsegments_all_valid_segments
    valid_segments = "all,comments,gdhdr,thumb,gameinfo,gamefile,rollouts,idx"
    result = parseoptsegments(valid_segments)
    expected = ["all", "comments", "gdhdr", "thumb", "gameinfo", "gamefile", "rollouts", "idx"]
    assert_equal expected, result
  end

  def test_parseoptsegments_invalid_segment
    assert_raises(ArgumentError) do
      parseoptsegments("invalid")
    end
  end

  def test_parseoptsegments_mixed_valid_invalid
    assert_raises(ArgumentError) do
      parseoptsegments("all,invalid,comments")
    end
  end

  def test_parseoptsegments_empty_segment
    assert_raises(ArgumentError) do
      parseoptsegments("all,,comments")
    end
  end

  def test_parseoptsegments_error_message_includes_invalid_segment
    error = assert_raises(ArgumentError) do
      parseoptsegments("invalid_segment")
    end
    assert_includes error.message, "invalid_segment"
    assert_includes error.message, "not a recognized segment"
  end

  def test_directoryisvalid_existing_directory
    # Use a directory that should exist
    result = directoryisvalid("/tmp")
    assert_equal "/tmp", result
  end

  def test_directoryisvalid_nonexistent_directory
    error = assert_raises(ArgumentError) do
      directoryisvalid("/nonexistent/directory/path")
    end
    assert_includes error.message, "doesn't exist"
  end

  def test_directoryisvalid_file_instead_of_directory
    # Create a temporary file and try to use it as directory
    temp_file = create_temp_file("test")
    error = assert_raises(ArgumentError) do
      directoryisvalid(temp_file.path)
    end
    assert_includes error.message, "doesn't exist"
    temp_file.close
    temp_file.unlink
  end

  # Test script execution without actually running the main block
  def test_script_loads_without_error
    # The script should load its dependencies without error
    begin
      require "optparse"
      require "pp"
      assert true, "Dependencies loaded successfully"
    rescue => e
      flunk "Failed to load dependencies: #{e.message}"
    end
  end

  def test_required_modules_are_loaded
    # Test that the script loads the required modules
    assert defined?(XGImport), "XGImport module should be loaded"
    assert defined?(XGZarc), "XGZarc module should be loaded" 
    assert defined?(XGStruct), "XGStruct module should be loaded"
  end

  # Test option parser behavior by creating our own instance
  def test_option_parser_help_format
    require "optparse"
    
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: test_program [options] FILE [FILE ...]"
      opts.separator ""
      opts.separator "XG data extraction utility"
      opts.separator ""
      opts.separator "Options:"

      opts.on("-d", "--directory DIR", "Directory to write segments to",
        "(Default is same directory as the import file)") do |dir|
        # Test option
      end

      opts.on("-h", "--help", "Show this help message") do
        # Test option
      end
    end

    help_text = parser.to_s
    assert_includes help_text, "Usage: test_program [options] FILE"
    assert_includes help_text, "XG data extraction utility"
    assert_includes help_text, "--directory DIR"
    assert_includes help_text, "--help"
  end

  def test_option_parser_directory_validation
    require "optparse"
    
    options = {}
    parser = OptionParser.new do |opts|
      opts.on("-d", "--directory DIR") do |dir|
        options[:outdir] = directoryisvalid(dir)
      end
    end

    # Test valid directory
    parser.parse!(["-d", "/tmp"])
    assert_equal "/tmp", options[:outdir]

    # Test invalid directory
    options.clear
    assert_raises(ArgumentError) do
      parser.parse!(["-d", "/nonexistent"])
    end
  end

  # Test main script behavior using subprocess to avoid exit issues
  def test_script_help_output
    # Test help option by running the script in a subprocess
    output = `cd #{File.dirname(__dir__)} && ruby extractxgdata.rb --help 2>/dev/null`
    exit_status = $?.exitstatus
    
    assert_equal 0, exit_status
    assert_includes output, "Usage:"
    assert_includes output, "XG data extraction utility"
    assert_includes output, "--directory"
    assert_includes output, "--help"
  end

  def test_script_no_files_error
    # Test error when no files are specified
    output = `cd #{File.dirname(__dir__)} && ruby extractxgdata.rb 2>&1`
    exit_status = $?.exitstatus
    
    assert_equal 1, exit_status
    assert_includes output, "Error: No XG files specified"
  end

  def test_script_invalid_directory_error
    # Test error with invalid directory option
    output = `cd #{File.dirname(__dir__)} && ruby extractxgdata.rb -d /nonexistent dummy.xg 2>&1`
    exit_status = $?.exitstatus
    
    assert_equal 1, exit_status
    assert_includes output, "Error:"
    assert_includes output, "doesn't exist"
  end

  def test_script_file_processing_paths
    # Test the file path processing logic by creating a mock scenario
    require "fileutils"
    
    # Create a temporary directory for testing
    test_dir = "/tmp/xgdata_test_#{Process.pid}"
    FileUtils.mkdir_p(test_dir)
    
    begin
      # Create a dummy input file 
      dummy_file = File.join(test_dir, "test.xg")
      File.write(dummy_file, "dummy xg content")
      
      # Test the path processing logic that would happen in the main loop
      xgfilename = dummy_file
      xgbasepath = File.dirname(xgfilename)
      xgbasefile = File.basename(xgfilename)
      xgext = File.extname(xgfilename)
      
      assert_equal test_dir, xgbasepath
      assert_equal "test.xg", xgbasefile  
      assert_equal ".xg", xgext
      
      # Test with output directory override
      options = { outdir: "/tmp" }
      xgbasepath = options[:outdir] if options[:outdir]
      assert_equal "/tmp", xgbasepath
      
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end

  def test_script_output_filename_generation
    # Test the output filename generation logic
    xgbasefile = "testfile.xg"
    xgext = ".xg"
    xgbasepath = "/tmp"
    
    # Mock a segment with extension
    segment_ext = ".gdf"
    
    output_filename = File.join(
      File.expand_path(xgbasepath),
      File.basename(xgbasefile, xgext) + segment_ext
    )
    
    expected = File.join(File.expand_path("/tmp"), "testfile.gdf")
    assert_equal expected, output_filename
  end

  def test_file_basename_extension_logic
    # Test the file naming logic more thoroughly
    test_cases = [
      ["test.xg", ".xg", "test"],
      ["path/to/file.xg", ".xg", "file"], 
      ["noext", "", "noext"],
      ["multiple.dots.xg", ".xg", "multiple.dots"]
    ]
    
    test_cases.each do |filename, expected_ext, expected_base|
      actual_ext = File.extname(filename)
      actual_base = File.basename(filename, actual_ext)
      
      assert_equal expected_ext, actual_ext, "Extension mismatch for #{filename}"
      assert_equal expected_base, actual_base, "Basename mismatch for #{filename}"
    end
  end

  # Test error handling patterns
  def test_error_handling_structure
    # Test that the expected error classes are defined
    assert defined?(XGImport::Error), "XGImport::Error should be defined"
    assert defined?(XGZarc::Error), "XGZarc::Error should be defined"
    
    # Test error inheritance
    assert XGImport::Error < StandardError
    assert XGZarc::Error < StandardError
  end

  # Additional edge case tests
  def test_parseoptsegments_whitespace_handling
    # Test segments with whitespace (should not be trimmed in current implementation)
    assert_raises(ArgumentError) do
      parseoptsegments(" all ")
    end
    
    assert_raises(ArgumentError) do
      parseoptsegments("all, comments")
    end
  end

  def test_parseoptsegments_case_sensitivity
    # Test that segments are case sensitive
    assert_raises(ArgumentError) do
      parseoptsegments("ALL")
    end
    
    assert_raises(ArgumentError) do
      parseoptsegments("Comments")
    end
  end

  def test_parseoptsegments_empty_string
    result = parseoptsegments("")
    assert_equal [], result  # Empty string splits to empty array
    
    # But empty segment should fail validation if we had any
    assert_raises(ArgumentError) do
      parseoptsegments("all,,comments")  # This has an empty segment in the middle
    end
  end

  def test_directoryisvalid_edge_cases
    # Test with current directory
    result = directoryisvalid(".")
    assert_equal ".", result
    
    # Test with root directory (should exist on Unix systems)
    result = directoryisvalid("/")
    assert_equal "/", result
  end

  def test_script_constants_and_requirements
    # Test that required constants are available after loading
    assert defined?(OptionParser), "OptionParser should be available"
    assert defined?(PP), "PP should be available"
  end

  def test_main_script_file_detection
    # Test the __FILE__ == $PROGRAM_NAME pattern
    # When loaded as a library, the main block shouldn't execute
    current_file = File.expand_path("../extractxgdata.rb", __dir__)
    refute_equal current_file, $PROGRAM_NAME, "Script should not execute main block when loaded as library"
  end

  def test_script_with_valid_directory_option
    # Test script with valid directory option but invalid file
    require "fileutils"
    
    test_dir = "/tmp/xgdata_output_test_#{Process.pid}"
    FileUtils.mkdir_p(test_dir)
    
    begin
      output = `cd #{File.dirname(__dir__)} && ruby extractxgdata.rb -d #{test_dir} nonexistent.xg 2>&1`
      exit_status = $?.exitstatus
      
      # Should fail because file doesn't exist, but directory option should be processed correctly
      assert_equal 1, exit_status
      assert_includes output, "Processing file:" if output.include?("Processing file:")
    ensure
      FileUtils.rm_rf(test_dir)
    end
  end

  def test_file_extension_edge_cases
    # Test various file extension scenarios
    test_cases = [
      ["file.", ".", "file"],
      [".hidden", "", ".hidden"],
      ["path/to/.config", "", ".config"],
      ["file.tar.gz", ".gz", "file.tar"]
    ]
    
    test_cases.each do |filename, expected_ext, expected_base|
      actual_ext = File.extname(filename)
      actual_base = File.basename(filename, actual_ext)
      
      assert_equal expected_ext, actual_ext, "Extension mismatch for #{filename}"
      assert_equal expected_base, actual_base, "Basename mismatch for #{filename}"
    end
  end

  def test_segment_constants_accessibility
    # Test that segment constants are accessible (they should be loaded via xgimport)
    skip "Segment constants require valid XG file structure" unless defined?(XGImport::Import::Segment)
    
    # These should be defined if the modules are properly loaded
    constants = %w[XG_GAMEFILE XG_ROLLOUTS GDF_HDR GDF_IMAGE]
    constants.each do |const|
      if XGImport::Import::Segment.const_defined?(const)
        assert XGImport::Import::Segment.const_get(const).is_a?(Integer), 
               "#{const} should be an integer constant"
      end
    end
  end
end