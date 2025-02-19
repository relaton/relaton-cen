# frozen_string_literal: true

require "digest/md5"
require "mechanize"
require "relaton/iso"
require_relative "cen/version"
require_relative "cen/util"
require_relative "cen/item"
require_relative "cen/bibitem"
require_relative "cen/bibdata"
# require_relative "relaton_cen/scrapper"
# require_relative "relaton_cen/hit_collection"
# require_relative "relaton_cen/hit"
# require_relative "relaton_cen/xml_parser"
# require_relative "relaton_cen/hash_converter"
# require_relative "relaton_cen/cen_bibliography"

module Relaton
  module Cen
    # Returns hash of XML greammar
    # @return [String]
    def self.grammar_hash
      # gem_path = File.expand_path "..", __dir__
      # grammars_path = File.join gem_path, "grammars", "*"
      # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
      Digest::MD5.hexdigest RelatonCen::VERSION + RelatonIsoBib::VERSION + RelatonBib::VERSION # grammars
    end
  end
end
