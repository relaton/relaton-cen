module RelatonCen
  module Util
    extend RelatonBib::Util

    def self.logger
      RelatonCen.configuration.logger
    end
  end
end
