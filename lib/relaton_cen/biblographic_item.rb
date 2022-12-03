module RelatonCen
  class BibliographicItem < RelatonIsoBib::IsoBibliographicItem
    #
    # Fetches CEN flavor schema version.
    #
    # @return [String] schema version
    #
    def ext_schema
      @ext_schema ||= schema_versions["relaton-model-cen"]
    end
  end
end
