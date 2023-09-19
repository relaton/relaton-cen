# frozen_string_literal: true

require "digest/md5"
require "mechanize"
require "nokogiri"
require_relative "relaton_cen/version"
require "relaton_iso_bib"
require "relaton_cen/biblographic_item"
require "relaton_cen/scrapper"
require "relaton_cen/hit_collection"
require "relaton_cen/hit"
require "relaton_cen/xml_parser"
require "relaton_cen/hash_converter"
require "relaton_cen/cen_bibliography"

module RelatonCen
  # Returns hash of XML greammar
  # @return [String]
  def self.grammar_hash
    # gem_path = File.expand_path "..", __dir__
    # grammars_path = File.join gem_path, "grammars", "*"
    # grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest RelatonCen::VERSION + RelatonIsoBib::VERSION + RelatonBib::VERSION # grammars
  end
end
