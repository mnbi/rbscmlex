# frozen_string_literal: true

require "json"

module Rbscmlex

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

  Token = Struct.new(:type, :literal) {
    alias :to_s :literal

    def to_hash
      {type: type, literal: literal}
    end

    def to_json
      JSON.generate(to_hash)
    end
  }

  class << self
    def json2token(json)
      h = JSON.parse(json)
      if h.key?("type") and h.key?("literal")
        type = h["type"].intern
        raise UnknownTokenType, ("got=%s" % type) unless TOKEN_TYPES.include?(type)
        literal = h["literal"]
        Token.new(type.intern, literal)
      else
        raise InvalidJsonError, ("got=%s" % json)
      end
    end
  end

end
