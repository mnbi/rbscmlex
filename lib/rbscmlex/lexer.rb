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
      convert(@tokens[index])
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

    def next_token
      check_pos
      @current_pos = @next_pos
      @next_pos += 1
      self[@current_pos]
    end

    def peek_token(num = 0)
      check_pos
      self[@next_pos + num]
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

    def check_pos
      raise StopIteration if @next_pos >= size
    end

    S2R_MAP = { "(" => "( ", ")" => " ) ", "'" => " ' " } # :nodoc:

    def tokenize(src)
      cooked = src.gsub(/[()']/, S2R_MAP)

      cooked.split(" ").map { |literal|
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
        when BOOLEAN
          Rbscmlex.new_token(:boolean, literal)
        when IDENTIFIER
          Rbscmlex.new_token(:identifier, literal)
        when CHAR
          Rbscmlex.new_token(:character, literal)
        when STRING
          Rbscmlex.new_token(:string, literal)
        when ARITHMETIC_OPS, COMPARISON_OPS
          Rbscmlex.new_token(:op_proc, literal)
        when REAL_NUM, RATIONAL, COMPLEX, PURE_IMAG
          Rbscmlex.new_token(:number, literal)
        else
          Rbscmlex.new_token(:illegal, literal)
        end
      }
    end

    # :startdoc:

  end
end
