require_relative "test_helper"
require_relative "../xgutils"

class TestXGUtils < Minitest::Test
  include TestHelper

  def test_streamcrc32_with_full_stream
    # Test CRC32 calculation on full stream
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream)
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_numbytes
    # Test CRC32 calculation with specific byte count
    test_data = "Hello, World! Extra data that should be ignored"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, numbytes: 13)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_startpos
    # Test CRC32 calculation with start position
    test_data = "Ignore this part. Hello, World!"
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, startpos: 18)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_startpos_and_numbytes
    # Test CRC32 calculation with both start position and byte count
    test_data = "Ignore this. Hello, World! Ignore this too."
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, startpos: 13, numbytes: 13)
    expected_crc = Zlib.crc32("Hello, World!") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_with_custom_blksize
    # Test CRC32 calculation with custom block size
    test_data = "A" * 1000  # Large data to test chunking
    stream = StringIO.new(test_data)

    crc = XGUtils.streamcrc32(stream, blksize: 100)
    expected_crc = Zlib.crc32(test_data) & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 0, stream.tell  # Stream position should be restored
  end

  def test_streamcrc32_empty_stream
    # Test CRC32 calculation on empty stream
    stream = StringIO.new("")

    crc = XGUtils.streamcrc32(stream)
    expected_crc = Zlib.crc32("") & 0xffffffff

    assert_equal expected_crc, crc
  end

  def test_streamcrc32_preserves_position
    # Test that stream position is preserved
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)
    stream.seek(5)  # Move to middle of stream

    XGUtils.streamcrc32(stream)
    assert_equal 5, stream.tell  # Position should be restored
  end

  def test_utf16intarraytostr_basic
    # Test basic UTF16 to string conversion
    int_array = [72, 101, 108, 108, 111, 0]  # "Hello" followed by null terminator
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello", result
  end

  def test_utf16intarraytostr_with_special_chars
    # Test with special characters
    int_array = [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33, 0]  # "Hello, World!"
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello, World!", result
  end

  def test_utf16intarraytostr_null_array
    # Test with empty array
    int_array = [0]  # Just null terminator
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "", result
  end

  def test_utf16intarraytostr_no_null_terminator
    # Test array without null terminator
    int_array = [72, 101, 108, 108, 111]  # "Hello" without null
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "Hello", result
  end

  def test_utf16intarraytostr_multiple_nulls
    # Test array with multiple nulls (should stop at first)
    int_array = [72, 101, 0, 108, 108, 111, 0]  # "He" then null
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "He", result
  end

  def test_delphidatetimeconv_basic
    # Test basic Delphi datetime conversion
    delphi_datetime = 0.0  # Dec 30, 1899
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(1899, 12, 30), result
  end

  def test_delphidatetimeconv_with_days
    # Test conversion with days
    delphi_datetime = 1.0  # Dec 31, 1899
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(1899, 12, 31), result
  end

  def test_delphidatetimeconv_with_fractional_day
    # Test conversion with fractional day (time component)
    delphi_datetime = 0.5  # Dec 30, 1899 12:00:00
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    expected = DateTime.new(1899, 12, 30, 12, 0, 0)
    assert_equal expected, result
  end

  def test_delphidatetimeconv_with_days_and_time
    # Test conversion with both days and time
    delphi_datetime = 1.25  # Dec 31, 1899 06:00:00
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    expected = DateTime.new(1899, 12, 31, 6, 0, 0)
    assert_equal expected, result
  end

  def test_delphidatetimeconv_year_2000
    # Test Y2K and beyond
    days_to_2000 = (DateTime.new(2000, 1, 1) - DateTime.new(1899, 12, 30)).to_i
    delphi_datetime = days_to_2000.to_f
    result = XGUtils.delphidatetimeconv(delphi_datetime)

    assert_equal DateTime.new(2000, 1, 1), result
  end

  def test_delphishortstrtostr_basic
    # Test basic short string conversion
    shortstring_bytes = [5, 72, 101, 108, 108, 111]  # Length 5, "Hello"
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "Hello", result
  end

  def test_delphishortstrtostr_empty_string
    # Test empty string
    shortstring_bytes = [0]  # Length 0
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "", result
  end

  def test_delphishortstrtostr_max_length
    # Test maximum length string (255 chars)
    test_string = "A" * 255
    shortstring_bytes = [255] + test_string.bytes
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal test_string, result
  end

  def test_delphishortstrtostr_with_special_chars
    # Test with special characters
    test_string = "Héllo, Wørld!"
    shortstring_bytes = [test_string.bytesize] + test_string.bytes
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal test_string, result
  end

  def test_delphishortstrtostr_longer_buffer
    # Test when buffer is longer than specified length
    shortstring_bytes = [5, 72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100]  # Length 5, but more data
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal "Hello", result  # Should only read 5 characters
  end

  def test_delphishortstrtostr_utf8_encoding
    # Test that result is properly UTF-8 encoded
    shortstring_bytes = [5, 72, 101, 108, 108, 111]  # "Hello"
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    assert_equal Encoding::UTF_8, result.encoding
  end

  def test_streamcrc32_zero_bytes
    # Test CRC32 calculation with zero bytes
    test_data = "Hello, World!"
    stream = StringIO.new(test_data)
    stream.seek(5)  # Move to middle

    crc = XGUtils.streamcrc32(stream, numbytes: 0)
    expected_crc = Zlib.crc32("") & 0xffffffff

    assert_equal expected_crc, crc
    assert_equal 5, stream.tell  # Position should be restored
  end

  def test_utf16intarraytostr_empty_array
    # Test with completely empty array
    int_array = []
    result = XGUtils.utf16intarraytostr(int_array)

    assert_equal "", result
  end

  def test_delphishortstrtostr_buffer_shorter_than_length
    # Test when buffer is shorter than specified length
    shortstring_bytes = [10, 65, 66, 67]  # Says length 10 but only 3 chars

    # This should not crash and handle gracefully
    result = XGUtils.delphishortstrtostr(shortstring_bytes)

    # Should get the available characters
    assert_equal "ABC", result
  end

  # Test module is properly defined
  def test_module_exists
    assert defined?(XGUtils)
    assert XGUtils.is_a?(Module)
  end

  # Test all methods are module methods
  def test_module_methods
    expected_methods = [:streamcrc32, :utf16intarraytostr, :delphidatetimeconv, :delphishortstrtostr]

    expected_methods.each do |method|
      assert XGUtils.respond_to?(method), "XGUtils should respond to #{method}"
    end
  end
end
