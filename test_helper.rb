require 'minitest/autorun'
require 'minitest/pride'
require 'stringio'
require 'tempfile'
require 'fileutils'

# Test helper module for common test utilities
module TestHelper
  # Create a StringIO with test data
  def create_string_io(data)
    StringIO.new(data.pack('C*'))
  end

  # Create a temporary file with test data
  def create_temp_file(data)
    temp = Tempfile.new('test_data')
    temp.binmode
    temp.write(data.pack('C*')) if data.is_a?(Array)
    temp.write(data) if data.is_a?(String)
    temp.rewind
    temp
  end

  # Helper to capture stdout
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  # Helper to test hash-like behavior
  def assert_hash_like_behavior(obj, key, value)
    # Test setting with []= and method call
    obj[key] = value
    assert_equal value, obj[key]
    
    # Test method-style access
    obj.send("#{key}=", value) if obj.respond_to?("#{key}=")
    assert_equal value, obj.send(key) if obj.respond_to?(key)
  end

  # Generate test byte arrays for various scenarios
  def generate_test_bytes(size, pattern = nil)
    if pattern
      (0...size).map { |i| pattern[i % pattern.size] }
    else
      (0...size).map { |i| i % 256 }
    end
  end

  # Create mock stream with specific data
  def mock_stream_with_data(data)
    StringIO.new(data.is_a?(String) ? data : data.pack('C*'))
  end
end