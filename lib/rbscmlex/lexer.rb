# frozen_string_literal: true

require "json"

module Rbscmlex

  # A base class of a lexical analyzer for Scheme program.  It returns
  # an Array instance of tokens.  The representation of each token is
  # depends on the specification of type, which is specified to the
  # `new` method.
  #
  # Currently, 3 types of the representation are available.
  #
  #   1. a struct Token,
  #   2. a Hash object,
  #   3. a JSON string.
  #

  class Lexer

    class << self

      def version               # :nodoc:
        "(scheme-lexer :version #{VERSION})"
      end

    end

    # :stopdoc:

    BOOLEAN    = /\A#(f(alse)?|t(rue)?)\Z/
    STRING     = /\A\"[^\"]*\"\Z/

    # idents
    EXTENDED_CHARS = "!\\$%&\\*\\+\\-\\./:<=>\\?@\\^_~"
    IDENT_PAT  = "[a-zA-Z_][a-zA-Z0-9#{EXTENDED_CHARS}]*"
    IDENTIFIER = Regexp.new("\\A#{IDENT_PAT}\\Z")

    # operators
    ARITHMETIC_OPS = /\A[+\-*\/%]\Z/
    COMPARISON_OPS = /\A([<>]=?|=)\Z/

    # numbers
    REAL_PAT   = "(([1-9][0-9]*)|0)(\.[0-9]+)?"
    RAT_PAT    = "#{REAL_PAT}\\/#{REAL_PAT}"
    C_REAL_PAT = "(#{REAL_PAT}|#{RAT_PAT})"
    C_IMAG_PAT = "#{C_REAL_PAT}"
    COMP_PAT   = "#{C_REAL_PAT}(\\+|\\-)#{C_IMAG_PAT}i"

    REAL_NUM   = Regexp.new("\\A[+-]?#{REAL_PAT}\\Z")
    RATIONAL   = Regexp.new("\\A[+-]?#{RAT_PAT}\\Z")
    COMPLEX    = Regexp.new("\\A[+-]?#{COMP_PAT}\\Z")
    PURE_IMAG  = Regexp.new("\\A[+-](#{C_IMAG_PAT})?i\\Z")

    # char
    SINGLE_CHAR_PAT = "."
    SPACE_PAT       = "space"
    NEWLINE_PAT     = "newline"

    CHAR_PREFIX = "\#\\\\"
    CHAR_PAT    = "(#{SINGLE_CHAR_PAT}|#{SPACE_PAT}|#{NEWLINE_PAT})"
    CHAR        = Regexp.new("\\A#{CHAR_PREFIX}#{CHAR_PAT}\\Z")

    # :startdoc:

    include Enumerable

    def initialize(src, type: :token)
      @type = type
      @tokens = tokenize(src)
      @size = @tokens.size

      @current_pos = @next_pos = 0
    end

    def each(&blk)
      @tokens.each(&blk)
    end

    def to_a
      @tokens
    end

    def size
      @size
    end

    def current_token
      @tokens[@current_pos]
    end

    def next_token
      raise StopIteration if @next_pos >= @size
      @current_pos = @next_pos
      @next_pos += 1
      @tokens[@current_pos]
    end

    def peek_token(num = 0)
      @tokens[@next_pos + num]
    end

    def rewind
      @current_pos = @next_pos = 0
      self
    end

    private

    S2R_MAP = { "(" => "( ", ")" => " ) ", "'" => " ' " } # :nodoc:

    def tokenize(src)
      cooked = src.gsub(/[()']/, S2R_MAP)

      cooked.split(" ").map { |literal|
        case literal
        when "("
          new_token(:lparen, literal)
        when ")"
          new_token(:rparen, literal)
        when "."
          new_token(:dot, literal)
        when "'"
          new_token(:quotation, literal)
        when "#("
          new_token(:vec_lparen, literal)
        when BOOLEAN
          new_token(:boolean, literal)
        when IDENTIFIER
          new_token(:identifier, literal)
        when CHAR
          new_token(:character, literal)
        when STRING
          new_token(:string, literal)
        when ARITHMETIC_OPS, COMPARISON_OPS
          new_token(:op_proc, literal)
        when REAL_NUM, RATIONAL, COMPLEX, PURE_IMAG
          new_token(:number, literal)
        else
          new_token(:illegal, literal)
        end
      }
    end

    def new_token(type, literal)
      token = Token.new(type, literal)
      if @type != :token
        converter = "to_#{@type}".intern
        raise InvalidConversionTypeError unless token.respond_to?(converter)
        token = token.send(converter)
      end
      token
    end

  end
end
