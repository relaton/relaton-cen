# frozen_string_literal: true

module RelatonCen
  # Hit.
  class Hit < RelatonBib::Hit
    attr_writer :fetch

    # Parse page.
    # @return [RelatonBib::BibliographicItem]
    def fetch
      @fetch ||= Scrapper.parse_page self
    end
  end
end
