# frozen_string_literal: true

require "json"

module Rbscmlex

  TOKEN_FORMS = [ :token, :hash, :json, ] # :nodoc:
  TOKEN_DEFAULT_FORM = :token             # :nodoc:

  TOKEN_TYPES = [             # :nodoc:
    # delimiters
    :lparen,                  # `(`
    :rparen,                  # `)`
    :vec_lparen,              # `#(`
    :bytevec_lparen,          # `#u8(`
    :quotation,               # `'`
    :backquote,               # "`" (aka quasiquote)
    :comma,                   # `,`
    :comma_at,                # `,@`
    :dot,                     # `.`
    :semicolon,               # `;`
    :comment_lparen,          # `#|`
    :comment_rparen,          # `|#`
    # value types
    :identifier,              # `foo`
    :boolean,                 # `#f` or `#t` (`#false` or `#true`)
    :number,                  # `123`, `456.789`, `1/2`, `3+4i`
    :character,               # `#\a`
    :string,                  # `"hoge"`
    # operators
    :op_proc,                 # `+`, `-`, ...
    # control
    :illegal,
  ]

  # a structure to store properties of a token of Scheme program.

  Token = Struct.new(:type, :literal) {
    # :stopdoc:
    # `to_a` and `to_h` are automatically defined for a class
    # generated from Struct.
    # :startdoc:

    alias :to_s :literal

    # Generates a new string of JSON notation, which has "type" and
    # "literal" as its key.
    def to_json
      JSON.generate(to_h)
    end
  }

  class << self

    # Instantiates a new token object form type and literal.

    def new_token(type, literal = nil)
      Token.new(type, literal)
    end

    # Returns true when the argument is valid token type.

    def token_type?(type)
      TOKEN_TYPES.include?(type)
    end

    # Returns a new Hash object with type and literal as its keys.

    def make_hash(type, literal)
      {type: type, literal: literal}
    end

    # Converts a Hash object, which has type and literal as its key,
    # to a new token object.  The value associated to type of the Hash
    # must be valid token type.  Otherwise, raises UnknownTokenTypeError.

    def hash2token(hash)
      if hash.key?(:type) and hash.key?(:literal)
        type = hash[:type].intern
        raise UnknownTokenTypeError, ("got=%s" % type) unless token_type?(type)
        literal = hash[:literal]
        new_token(type, literal)
      else
        raise InvalidHashError, ("got=%s" % hash)
      end
    end

    # Converts a JSON notation, which hash type and literal, to a new
    # token object.  The value associated to type of the JSON must be
    # valid token type.  Otherwise, raises UnknownTokenTypeError.

    def json2token(json)
      h = JSON.parse(json, symbolize_names: true)
      begin
        hash2token(h)
      rescue InvalidHashError => _
        raise InvalidJsonError, ("got=%s" % json)
      end
    end

    # Converts a Token object to a Hash object.

    def token2hash(token)
      token.to_h
    end

    # Converts a Token object to a string of JSON notation.

    def token2json(token)
      token.to_json
    end

    # Converts a Hash object to a string of JSON notation.

    def hash2json(hash)
      JSON.generate(hash)
    end


    # Converts a JSON notation to a new Hash object.

    def json2hash(json)
      JSON.parse(json)
    end

  end

end
