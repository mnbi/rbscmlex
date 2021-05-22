# frozen_string_literal: true

require "json"

module Rbscmlex

  # A lexical analyzer for Scheme program.  It returns an Array
  # instance of tokens.  The representation of each token is depends
  # on the specification of type, which is specified to the `new`
  # method.
  #
  # Currently, 3 types of the representation are available.
  #
  #   1. a struct Token,
  #   2. a Hash object,
  #   3. a JSON string.

  class Lexer

    class << self

      def version               # :nodoc:
        "(scheme-lexer :version #{VERSION})"
      end

    end

    include Enumerable

    def initialize(obj, form: TOKEN_DEFAULT_FORM)
      set_form(form)
      init_pos
      case obj
      when String
        # obj must be source program of Scheme.
        @tokens = tokenize(obj)
      when Array
        # obj might be an array of tokens.
        input_form = detect_form(obj[0])
        case input_form
        when :hash, :json, :token
          @tokens = read_tokens(obj, form: input_form)
        else
          raise InvalidConversionTypeError, "cannot convert #{obj[0]} as token"
        end
      else
        raise InvalidConversionTypeError, "cannot convert #{obj} as tokens"
      end
    end

    def [](index)
      token = @tokens[index]
      token and convert(token)
    end

    def each(&blk)
      if block_given?
        @tokens.each { |tk|
          yield convert(tk)
        }
        self
      else
        to_a.to_enum
      end
    end

    def to_a
      convert_all(@tokens)
    end

    def size
      @tokens.size
    end

    def current_token
      self[@current_pos]
    end

    def next_token(offset = 0)
      check_pos(offset)
      skip_token(offset)
      self[@current_pos]
    end

    def peek_token(offset = 0)
      # Since `peek_token` does not modify the position to read, raise
      # StopIteration only if the next position truly exceed the
      # bound.
      check_pos(0)
      self[@next_pos + offset]
    end

    def skip_token(offset = 0)
      check_pos(offset)
      @current_pos = @next_pos + offset
      @next_pos += (1 + offset)
      nil
    end

    def rewind
      init_pos
      self
    end

    # :stopdoc:

    private

    def set_form(form)
      if TOKEN_FORMS.include?(form)
        @form = form
      else
        raise InvalidConversionTypeError, "cannot generate #{form} as token"
      end
    end

    def init_pos
      @current_pos = @next_pos = 0
    end

    def read_tokens(ary, form: :token)
      conv_proc ={hash: :hash2token, json: :json2token, token: nil}[form]
      conv_proc ? ary.map{|e| Rbscmlex.send(conv_proc, e)} : ary.dup
    end

    def detect_form(obj)
      case obj
      when Hash
        valid_token?(obj) ? :hash : nil
      when Token
        :token
      when String
        begin
          JSON.parse(obj, symbolize_names: true)
        rescue JSON::ParserError => _
          nil
        else
          :json
        end
      else
        nil
      end
    end

    def valid_token?(obj)
      case obj
      when Hash
        obj.key?(:type) and obj.key?(:literal)
      when Token
        Rbscmlex.token_type?(obj.type)
      else
        false
      end
    end

    def converter
      { hash: :to_h, json: :to_json, token: nil}[@form]
    end

    def convert(token)
      converter ? token.send(converter) : token
    end

    def convert_all(tokens)
      converter ? token.map(&converter) : tokens
    end

    def check_pos(offset = 0)
      raise StopIteration if (@next_pos + offset) >= size
    end

    S2R_MAP = { "(" => "( ", ")" => " ) ", "'" => " ' " }

    BOOLEAN    = /\A#(f(alse)?|t(rue)?)\Z/
    STRING     = /\A\"[^\"]*\"\Z/

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

    def tokenize(src)
      cooked = src.gsub(/[()']/, S2R_MAP).strip

      split_at_space(cooked).map { |literal|
        case literal
        when "("
          Rbscmlex.new_token(:lparen, literal)
        when ")"
          Rbscmlex.new_token(:rparen, literal)
        when "."
          Rbscmlex.new_token(:dot, literal)
        when "'"
          Rbscmlex.new_token(:quotation, literal)
        when "#("
          Rbscmlex.new_token(:vec_lparen, literal)
        when "|"                # not supported yet
          Rbscmlex.new_token(:illegal, literal)
        when BOOLEAN
          Rbscmlex.new_token(:boolean, literal)
        when CHAR
          Rbscmlex.new_token(:character, literal)
        when STRING
          Rbscmlex.new_token(:string, literal)
        when REAL_NUM, RATIONAL, COMPLEX, PURE_IMAG
          Rbscmlex.new_token(:number, literal)
        else
          if Identifier.identifier?(literal)
            Rbscmlex.new_token(:identifier, literal)
          else
            Rbscmlex.new_token(:illegal, literal)
          end
        end
      }
    end

    def split_at_space(source)
      escaped = false
      in_string = false
      after_space = false
      slice = String.new        # an empty string
      results = []
      source.each_char { |rune|
        case rune
        when "\\"
          slice << rune
          escaped = !escaped if in_string
          after_space = false
        when '"'
          if !in_string or !escaped
            in_string = !in_string
          end
          slice << rune
          escaped = false
          after_space = false
        when /[\s]/
          if in_string
            slice << rune
          elsif !after_space
            results << slice.dup
            slice.clear
          end
          escaped = false
          after_space = true
        else
          slice << rune
          escaped = false
          after_space = false
        end
      }
      results << slice unless slice.empty?
      results
    end

    # Holds functions to check a literal is valid as an identifier
    # defined in R7RS.
    #
    # Call identifier? function as follows:
    #
    #   Identifier.identifier?(literal)
    #
    # It returns true if the literal is valid as an identifier.

    module Identifier

      DIGIT              = "0-9"
      LETTER             = "a-zA-Z"
      SPECIAL_INITIAL    = "!\\$%&\\*/:<=>\\?\\^_~"
      INITIAL            = "#{LETTER}#{SPECIAL_INITIAL}"
      EXPLICIT_SIGN      = "\\+\\-"
      SPECIAL_SUBSEQUENT = "#{EXPLICIT_SIGN}\\.@"
      SUBSEQUENT         = "#{INITIAL}#{DIGIT}#{SPECIAL_SUBSEQUENT}"

      REGEXP_INITIAL = Regexp.new("[#{INITIAL}]")
      REGEXP_EXPLICIT_SIGN = Regexp.new("[#{EXPLICIT_SIGN}]")
      REGEXP_SUBSEQUENT = Regexp.new("[#{SUBSEQUENT}]+")

      def self.identifier?(literal)
        size = literal.size
        c = literal[0]
        case c
        when REGEXP_INITIAL
          return true if size == 1
          subsequent?(literal[1..-1])
        when REGEXP_EXPLICIT_SIGN
          return true if size == 1
          if literal[1] == "."
            dot_identifier?(literal[1..-1])
          else
            if sign_subsequent?(literal[1])
              return true if size == 2
              subsequent?(literal[2..-1])
            else
              false
            end
          end
        when "."
          dot_identifier?(literal)
        else
          false
        end
      end

      def self.subsequent?(sub_literal)
        REGEXP_SUBSEQUENT === sub_literal
      end

      def self.sign_subsequent?(sub_literal)
        return false if sub_literal.size != 1
        case sub_literal[0]
        when REGEXP_INITIAL
          true
        when REGEXP_EXPLICIT_SIGN
          true
        when "@"
          true
        else
          false
        end
      end

      def self.dot_identifier?(sub_literal)
        return false if sub_literal[0] != "."
        return true if sub_literal.size == 1
        if dot_subsequent?(sub_literal[1])
          return true if sub_literal.size == 2
          subsequent?(sub_literal[2..-1])
        else
          false
        end
      end

      def self.dot_subsequent?(sub_literal)
        return true if sub_literal == "."
        sign_subsequent?(sub_literal)
      end

    end

    # :startdoc:

  end
end
