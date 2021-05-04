# frozen_string_literal: true

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

    def to_csv
      type_part = ":#{type}"
      literal_part = literal.nil? ? "nil" : "#{literal}"
      "\"#{type_part}\",\"#{literal_part}\""
    end
  }

end
