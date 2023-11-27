module RelatonCen
  module HashConverter
    include RelatonIsoBib::HashConverter
    extend self
    # @param item_hash [Hash]
    # @return [RelatonCen::BibliographicItem]
    def bib_item(item_hash)
      BibliographicItem.new(**item_hash)
    end
  end
end
