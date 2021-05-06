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
    alias :to_s :literal
  }

  class << self

    # Instantiates a new token object form type and literal.  The 3rd
    # argument specifies the form of the object.  It must be one of
    # :token, :hash, and :json.

    def new_token(type, literal = nil, form = :token)
      case form
      when :token
        Token.new(type, literal)
      when :hash
        {type: type, literal: literal}
      when :json
        JSON.generate(to_hash)
      else
        raise InvalidConversionTypeError, "cannot generate #{type} as token"
      end
    end

    # Returns true when the argument is valid token type.

    def token_type?(type)
      TOKEN_TYPES.include?(type)
    end

    # Converts a Hash object, which has type and literal as its key,
    # to a new token object.  The value associated to type of the Hash
    # must be valid token type.  Otherwise, raises UnknownTokenTypeError.

    def hash2token(hash)
      if h.key?("type") and h.key?("literal")
        type = h["type"].intern
        raise UnknownTokenTypeError, ("got=%s" % type) unless token_type?(type)
        literal = h["literal"]
        Token.new(type.intern, literal)
      else
        raise InvalidHashError, ("got=%s" % hash)
      end
    end

    # Converts a JSON notation, which hash type and literal, to a new
    # token object.  The value associated to type of the Hash must be
    # valid token type.  Otherwise, raises UnknownTokenTypeError.

    def json2token(json)
      h = JSON.parse(json)
      begin
        hash2token(h)
      rescue InvalidHashError => _
        raise InvalidJsonError, ("got=%s" % json)
      end
    end
  end

end
