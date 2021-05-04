# frozen_string_literal: true

module Rbscmlex

  class Lexer < Enumerator

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

    class << self

      def new(exp, _ = nil)
        tokens = tokenize(exp)
        super(tokens.size) { |y|
          tokens.each { |tk|
            y.yield(tk)
          }
        }
      end

      S2R_MAP = { "(" => "( ", ")" => " ) ", "'" => " ' " } # :nodoc:

      def tokenize(exp)
        source = exp.gsub(/[()']/, S2R_MAP)

        source.split(" ").map { |literal|
          case literal
          when "("
            Token.new(:lparen, literal)
          when ")"
            Token.new(:rparen, literal)
          when "."
            Token.new(:dot, literal)
          when "'"
            Token.new(:quotation, literal)
          when "#("
            Token.new(:vec_lparen, literal)
          when BOOLEAN
            Token.new(:boolean, literal)
          when IDENTIFIER
            Token.new(:identifier, literal)
          when CHAR
            Token.new(:character, literal)
          when STRING
            Token.new(:string, literal)
          when ARITHMETIC_OPS, COMPARISON_OPS
            Token.new(:op_proc, literal)
          when REAL_NUM, RATIONAL, COMPLEX, PURE_IMAG
            Token.new(:number, literal)
          else
            Token.new(:illegal, literal)
          end
        }
      end

    end

  end
end
