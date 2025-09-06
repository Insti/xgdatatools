require_relative "test_helper_simple"
require_relative "../extractxgdata"

class TestExtractXGData < Minitest::Test
  include TestHelper

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

  def test_directoryisvalid_existing_directory
    # Use a directory that should exist
    result = directoryisvalid("/tmp")
    assert_equal "/tmp", result
  end

  def test_directoryisvalid_nonexistent_directory
    assert_raises(ArgumentError) do
      directoryisvalid("/nonexistent/directory/path")
    end
  end

  def test_directoryisvalid_file_instead_of_directory
    # Create a temporary file and try to use it as directory
    temp_file = create_temp_file("test")
    assert_raises(ArgumentError) do
      directoryisvalid(temp_file.path)
    end
    temp_file.close
    temp_file.unlink
  end
end