# frozen_string_literal: true

require "test_helper"

class RbscmlexLexerTest < Minitest::Test

  # issue #5

  def test_it_can_retrieve_token_with_specifying_offset
    input = "(lambda (x y) (+ x y))"
    expected_tokens = [
      :lparen,                  #  0: (
      :identifier,              #  1: lambda
      :lparen,                  #  2: (
      :identifier,              #  3: x
      :identifier,              #  4: y
      :rparen,                  #  5: )
      :lparen,                  #  6: (
      :identifier,              #  7: +
      :identifier,              #  8: x
      :identifier,              #  9: y
      :rparen,                  # 10: )
      :rparen,                  # 11: )
    ]
    l = Rbscmlex::Lexer.new(input)
    offset = 3
    token = l.peek_token(offset)
    assert_equal expected_tokens[offset], token.type
    more_offset = 4
    token = l.peek_token(more_offset)
    assert_equal expected_tokens[offset + more_offset], token.type
  end

  def test_it_can_peek_token_with_specifying_offset
    input = "(lambda (x y) (+ x y))"
    expected_tokens = [
      :lparen,                  # (
      :identifier,              # lambda
      :lparen,                  # (
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :lparen,                  # (
      :identifier,              # +
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :rparen,                  # )
    ]
    l = Rbscmlex::Lexer.new(input)
    0.upto(expected_tokens.size - 1) { |offset|
      token = l.peek_token(offset)
      assert_equal expected_tokens[offset], token.type
    }
  end

  def test_peek_token_raise_stop_iteration_if_it_exceeds_the_limit
    input = "(lambda (x y) (+ x y))"
    expected_tokens = [
      :lparen,                  # (
      :identifier,              # lambda
      :lparen,                  # (
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :lparen,                  # (
      :identifier,              # +
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :rparen,                  # )
    ]
    l = Rbscmlex::Lexer.new(input)
    expected_tokens.size.times {
      _ = l.next_token
    }
    assert_raises(StopIteration) {
      _ = l.peek_token
    }
  end

  def test_peek_token_returns_nil_if_it_exeeds_the_limit_with_offset
    input = "(lambda (x y) (+ x y))"
    expected_tokens = [
      :lparen,                  # (
      :identifier,              # lambda
      :lparen,                  # (
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :lparen,                  # (
      :identifier,              # +
      :identifier,              # x
      :identifier,              # y
      :rparen,                  # )
      :rparen,                  # )
    ]
    l = Rbscmlex::Lexer.new(input)
    assert_nil l.peek_token(expected_tokens.size)
    assert_nil l.peek_token(expected_tokens.size + 1)
    assert_nil l.peek_token(expected_tokens.size + 2)
  end

  def test_it_can_skip_token_with_specifying_offset
    input = "(lambda (x y) (+ x y))"
    expected_tokens = [
      :lparen,                  #  0: (
      :identifier,              #  1: lambda
      :lparen,                  #  2: (
      :identifier,              #  3: x
      :identifier,              #  4: y
      :rparen,                  #  5: )
      :lparen,                  #  6: (
      :identifier,              #  7: +
      :identifier,              #  8: x
      :identifier,              #  9: y
      :rparen,                  # 10: )
      :rparen,                  # 11: )
    ]
    l = Rbscmlex::Lexer.new(input)
    offset = 3
    l.skip_token(offset)
    assert_equal expected_tokens[offset], l.current_token.type
    more_offset = 4
    l.skip_token(more_offset)
    assert_equal expected_tokens[offset + more_offset], l.current_token.type
  end

  # issue #4

  def test_it_can_handle_pecurilar_identifiers
    tcs = [
      "...",
      "+",
      "+soup+",
      "<=?",
      "->string",
      "a34kTMNs",
      "lambda",
      "q",
      "V17a",
      "the-word-recursion-has-many-meanings",
    ]
    assert_token_type(tcs, :identifier)
  end

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
    token = l.next_token

    assert_equal :lparen, token.type
    assert_equal "(", token.literal
  end

  def test_it_can_detect_rparen
    l = Rbscmlex::Lexer.new(")")
    token = l.next_token

    assert_equal :rparen, token.type
    assert_equal ")", token.literal
  end

  # vector litral

  def test_it_can_detect_vector_lpraen
    l = Rbscmlex::Lexer.new("#(")
    token = l.next_token

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
      :identifier,              # =
      #
      :identifier,              # n
      #
      :number,                  # 0
      :rparen,                  # )
      #
      :number,                  # 1
      #
      :lparen,                  # (
      :identifier,              # *
      #
      :identifier,              # n
      #
      :lparen,                  # (
      :identifier,              # fact
      #
      :lparen,                  # (
      :identifier,              # -
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
      token = l.next_token
      assert_equal expected, token.type
    }
  end

  # initialize from an array of tokens
  def test_it_can_initialize_from_tokens
    arys = [
      [                         # Hash
        {type: :lparen, literal: "("},
        {type: :identifier, literal: "list"},
        {type: :number, literal: "1"},
        {type: :number, literal: "2"},
        {type: :number, literal: "3"},
        {type: :rparen, literal: ")"},
      ],
      [                         # JSON
        {"type":"lparen","literal":"("},
        {"type":"identifier","literal":"list"},
        {"type":"number","literal":"1"},
        {"type":"number","literal":"2"},
        {"type":"number","literal":"3"},
        {"type":"rparen","literal":")"},
      ],
    ]

    expected_tokens = [
      :lparen,
      :identifier,
      :number,
      :number,
      :number,
      :rparen,
    ]

    arys.each { |ary|
      lex = Rbscmlex::Lexer.new(ary)
      expected_tokens.each { |expected|
        token = lex.next_token
        assert_equal expected, token.type
      }
    }
  end

  private

  def assert_token_type(test_cases, expected_type)
    test_cases.each { |input|
      l = Rbscmlex::Lexer.new(input)
      token = l.next_token
      assert_equal expected_type, token.type
      assert_equal input.rstrip.lstrip, token.literal
    }
  end

  def refute_token_type(test_cases, expected_type)
    test_cases.each { |input|
      l = Rbscmlex::Lexer.new(input)
      token = l.next_token
      refute_equal expected_type, token.type
      assert_equal input.rstrip.lstrip, token.literal
    }
  end

end
