# frozen_string_literal: true

module Rbscmlex
  class Error < StandardError; end

  class UnknownTokenTypeError < Error
  end

  class InvalidConversionTypeError < Error
  end

  class InvalidHashError < Error
  end

  class InvalidJsonError < Error
  end

end
