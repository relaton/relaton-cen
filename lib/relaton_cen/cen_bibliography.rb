# frozen_string_literal: true

require "mechanize"
require "relaton_iso_bib"
require "relaton_cen/scrapper"
require "relaton_cen/hit_collection"
require "relaton_cen/hit"
require "relaton_cen/xml_parser"

module RelatonCen
  # Class methods for search Cenelec standards.
  class CenBibliography
    class << self
      # @param text [String]
      # @return [RelatonCen::HitCollection]
      def search(text, year = nil)
        # /^C?EN\s(?<code>.+)/ =~ text
        HitCollection.new text, year
      rescue Mechanize::ResponseCodeError => e
        raise RelatonBib::RequestError, e.message
      end

      # @param code [String] the CEN standard Code to look up
      # @param year [String] the year the standard was published (optional)
      # @param opts [Hash] options; restricted to :all_parts if all-parts
      #   reference is required
      # @return [RelatonBib::BibliographicItem, nil]
      def get(code, year = nil, opts = {})
        code_parts = code_to_parts code
        year ||= code_parts[:year] if code_parts

        bib_get(code, year, opts)
      end

      #
      # Decopmposes a CEN standard code into its parts.
      #
      # @param [String] code the CEN standard code to decompose
      #
      # @return [MatchData] the decomposition of the code
      #
      def code_to_parts(code)
        %r{^
          (?<code>[^:-]+)(?:-(?<part>\d+))?
          (?::(?<year>\d{4}))?
          (?:\+(?<amd>[A-Z]\d+)(?:(?<amy>\d{4}))?)?
        }x.match code
      end

      private

      def fetch_ref_err(code, year, missed_years) # rubocop:disable Metrics/MethodLength
        id = year ? "#{code}:#{year}" : code
        warn "[relaton-cen] WARNING: no match found online for #{id}. "\
             "The code must be exactly like it is on the standards website."
        unless missed_years.empty?
          warn "[relaton-cen] (There was no match for #{year}, though there "\
               "were matches found for #{missed_years.join(', ')}.)"
        end
        # if /\d-\d/.match? code
        #   warn "[relaton-cen] The provided document part may not exist, or "\
        #     "the document may no longer be published in parts."
        # else
        #   warn "[relaton-cen] If you wanted to cite all document parts for "\
        #     "the reference, use \"#{code} (all parts)\".\nIf the document "\
        #     "is not a standard, use its document type abbreviation (TS, TR, "]
        #     "PAS, Guide)."
        # end
        nil
      end

      # @param code [String]
      # @return [RelatonCen::HitCollection]
      def search_filter(code) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
        parts = code_to_parts code
        warn "[relaton-cen] (\"#{code}\") fetching..."
        result = search(code)
        result.select do |i|
          pts = code_to_parts i.hit[:code]
          parts[:code] == pts[:code] &&
            (!parts[:part] || parts[:part] == pts[:part]) &&
            (!parts[:year] || parts[:year] == pts[:year]) &&
            parts[:amd] == pts[:amd] && (!parts[:amy] || parts[:amy] == pts[:amy])
        end
      end

      # Sort through the results from Isobib, fetching them three at a time,
      # and return the first result that matches the code,
      # matches the year (if provided), and which # has a title (amendments do not).
      # Only expects the first page of results to be populated.
      # Does not match corrigenda etc (e.g. ISO 3166-1:2006/Cor 1:2007)
      # If no match, returns any years which caused mismatch, for error reporting
      def isobib_results_filter(result, year)
        missed_years = []
        result.each do |r|
          /:(?<pyear>\d{4})/ =~ r.hit[:code]
          if !year || year == pyear
            ret = r.fetch
            return { ret: ret } if ret
          end

          missed_years << pyear
        end
        { years: missed_years }
      end

      def bib_get(code, year, _opts)
        result = search_filter(code) || return
        ret = isobib_results_filter(result, year)
        if ret[:ret]
          warn "[relaton-cen] (\"#{code}\") found #{ret[:ret].docidentifier.first&.id}"
          ret[:ret]
        else
          fetch_ref_err(code, year, ret[:years])
        end
      end
    end
  end
end
