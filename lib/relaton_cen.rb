# frozen_string_literal: true

require "digest/md5"
require_relative "relaton_cen/version"
require "relaton_cen/cen_bibliography"

module RelatonCen
  # Returns hash of XML greammar
  # @return [String]
  def self.grammar_hash
    gem_path = File.expand_path "..", __dir__
    grammars_path = File.join gem_path, "grammars", "*"
    grammars = Dir[grammars_path].sort.map { |gp| File.read gp }.join
    Digest::MD5.hexdigest grammars
  end
end
