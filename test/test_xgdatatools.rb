require_relative "test_helper"

class TestXgdatatools < Minitest::Test
  def setup
    # Save original logger
    @original_logger = Xgdatatools.instance_variable_get(:@logger)
  end

  def teardown
    # Restore original logger
    Xgdatatools.instance_variable_set(:@logger, @original_logger)
  end

  def test_singleton_logger
    # Reset logger to ensure we're testing from fresh state
    Xgdatatools.instance_variable_set(:@logger, nil)

    # Get two logger instances
    logger1 = Xgdatatools.logger
    logger2 = Xgdatatools.logger

    # They should be the same object (singleton)
    assert_same logger1, logger2, "Logger should be a singleton"
  end

  def test_logger_is_logger_instance
    logger = Xgdatatools.logger
    assert_instance_of Logger, logger, "Should return a Logger instance"
  end

  def test_init_logger_with_level
    # Test with different levels
    Xgdatatools.init_logger(level: :debug)
    logger = Xgdatatools.logger
    assert_equal Logger::DEBUG, logger.level

    Xgdatatools.init_logger(level: :error)
    logger = Xgdatatools.logger
    assert_equal Logger::ERROR, logger.level
  end

  def test_init_logger_with_output
    # Test with StringIO output
    output = StringIO.new
    Xgdatatools.init_logger(output: output)
    logger = Xgdatatools.logger

    logger.info "Test message"
    output.rewind
    assert_includes output.read, "Test message"
  end

  def test_logger_assignment
    custom_logger = Logger.new(StringIO.new)
    Xgdatatools.logger = custom_logger

    assert_same custom_logger, Xgdatatools.logger
  end

  def test_default_logger_level
    # Reset logger and check default level
    Xgdatatools.instance_variable_set(:@logger, nil)
    logger = Xgdatatools.logger
    assert_equal Logger::INFO, logger.level, "Default level should be INFO"
  end

  def test_logger_formatter
    output = StringIO.new
    Xgdatatools.init_logger(output: output)
    logger = Xgdatatools.logger

    logger.info "Test message"
    output.rewind
    result = output.read

    # Should have the expected format: [SEVERITY] message\n
    assert_match(/\[INFO\] Test message\n/, result)
  end
end
