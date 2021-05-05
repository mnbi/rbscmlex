# frozen_string_literal: true

module Rbscmlex
  class Error < StandardError; end

  class UnknownTokenType < Error
  end

  class InvalidConversionTypeError < Error
  end

  class InvalidJsonError < Error
  end

end
