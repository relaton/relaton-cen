require "nokogiri"

module RelatonCen
  class XMLParser < RelatonIsoBib::XMLParser
    class << self
      private

      # Override RelatonBib::XMLParser.item_data method.
      # @param isoitem [Nokogiri::XML::Element]
      # @returtn [Hash]
      def item_data(isoitem)
        data = super
        ext = isoitem.at "./ext"
        return data unless ext

        data[:price_code] = ext.at("./price-code")&.text
        data[:cen_processing] = ext.at("./cen-processing")&.text
        data
      end

      # @param item_hash [Hash]
      # @return [RelatonBib::BibliographicItem]
      def bib_item(item_hash)
        RelatonBib::BibliographicItem.new **item_hash
      end
    end
  end
end
