# frozen_string_literal: true

module Rbscmlex
  require_relative "rbscmlex/error"
  require_relative "rbscmlex/token"
  require_relative "rbscmlex/lexer"
  require_relative "rbscmlex/version"

  def self.lexer(source)
    Lexer.new(source)
  end

end
