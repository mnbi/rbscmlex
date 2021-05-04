# frozen_string_literal: true

require "test_helper"

class RbscmlexLexerTest < Minitest::Test

  # boolean

  def test_it_can_detect_f
    tcs = ["#f"]
    assert_token_type(tcs, :boolean)
  end

  def test_it_can_detect_t
    tcs = ["#t"]
    assert_token_type(tcs, :boolean)
  end

  # identifier

  def test_it_can_detect_identifier
    tcs = ["foo", "bar", "hoge"]
    assert_token_type(tcs, :identifier)
  end

  # char

  def test_it_can_detect_char
    tcs = ["#\\a", "#\\space", "#\\newline"]
    assert_token_type(tcs, :character)
  end

  # string

  def test_it_can_detect_a_string
    tcs = ["\"foo\"", "\"bar-hoge\""]
    assert_token_type(tcs, :string)
  end

  # numbers

  def test_it_can_detect_integer_as_number
    tcs = ["123456", "0", "123456789012345678901234567890"]
    assert_token_type(tcs, :number)
  end

  def test_it_can_detect_integer_ignoring_whitespaces
    tcs = ["  123456   "]
    assert_token_type(tcs, :number)
  end

  def test_it_can_detect_real_number_as_number
    tcs = ["123,456", "-3.14", "0.101", "+0.0001"]
    assert_token_type(tcs, :number)
  end

  def test_it_can_detect_rational_as_number
    tcs = ["1/2", "-2/3", "3.14/6.28", "0.9/0.001"]
    assert_token_type(tcs, :number)
  end

  def test_it_can_detect_complex_as_number
    tcs = ["1+2i", "-2+3i", "4-5i", "-6-7i", "+8.9i", "-10.11i", "2/3+4/5i"]
    assert_token_type(tcs, :number)
  end

  # keywords

  def test_it_can_detect_keyword_if
    tcs = ["if"]
    assert_token_type(tcs, :identifier)
  end

  def test_it_can_detect_keyword_define
    tcs = ["define"]
    assert_token_type(tcs, :identifier)
  end

  # parenthesis

  def test_it_can_detect_lparen
    l = Rbscmlex::Lexer.new("(")
    token = l.next

    assert_equal :lparen, token.type
    assert_equal "(", token.literal
  end

  def test_it_can_detect_rparen
    l = Rbscmlex::Lexer.new(")")
    token = l.next

    assert_equal :rparen, token.type
    assert_equal ")", token.literal
  end

  # vector litral

  def test_it_can_detect_vector_lpraen
    l = Rbscmlex::Lexer.new("#(")
    token = l.next

    assert_equal :vec_lparen, token.type
    assert_equal "#(", token.literal
  end

  # compound test

  def test_it_can_detect_tokens_properly
    input = "(define (fact n) (if (= n 0) 1 (* n (fact (- n 1)))))"
    expected_tokens = [
      :lparen,                  # (
      :identifier,              # define
      #
      :lparen,                  # (
      :identifier,              # fact
      #
      :identifier,              # n
      :rparen,                  # )
      #
      :lparen,                  # (
      :identifier,              # if
      #
      :lparen,                  # (
      :op_proc,                 # =
      #
      :identifier,              # n
      #
      :number,                  # 0
      :rparen,                  # )
      #
      :number,                  # 1
      #
      :lparen,                  # (
      :op_proc,                 # *
      #
      :identifier,              # n
      #
      :lparen,                  # (
      :identifier,              # fact
      #
      :lparen,                  # (
      :op_proc,                 # -
      #
      :identifier,              # n
      #
      :number,                  # 1
      :rparen,                  # )
      :rparen,                  # )
      :rparen,                  # )
      :rparen,                  # )
      :rparen,                  # )
    ]
    l = Rbscmlex::Lexer.new(input)
    expected_tokens.each { |expected|
      token = l.next
      assert_equal expected, token.type
    }
  end

  private

  def assert_token_type(test_cases, expected_type)
    test_cases.each { |input|
      l = Rbscmlex::Lexer.new(input)
      token = l.next
      assert_equal expected_type, token.type
      assert_equal input.rstrip.lstrip, token.literal
    }
  end

  def refute_token_type(test_cases, expected_type)
    test_cases.each { |input|
      l = Rbscmlex::Lexer.new(input)
      token = l.next
      refute_equal expected_type, token.type
      assert_equal input.rstrip.lstrip, token.literal
    }
  end

end
