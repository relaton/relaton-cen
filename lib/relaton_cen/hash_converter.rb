module RelatonCen
  class HashConverter < RelatonIsoBib::HashConverter
    class << self
      # @param item_hash [Hash]
      # @return [RelatonCen::BibliographicItem]
      def bib_item(item_hash)
        BibliographicItem.new(**item_hash)
      end
    end
  end
end
