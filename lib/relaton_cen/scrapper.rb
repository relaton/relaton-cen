# frozen_string_literal: true

module RelatonCen
  # Scrapper.
  module Scrapper
    COMMITTEES = {
      "TC 459" =>
        "ECISS - European Committee for Iron and Steel Standardization",
    }.freeze

    class << self
      # Parse page.
      # @param hit [RelatonCen::Hit]
      # @return [RelatonIsoBib::IsoBibliographicItem]
      def parse_page(hit) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        doc = hit.hit_collection.agent.get hit.hit[:url]
        BibliographicItem.new(
          fetched: Date.today.to_s,
          type: "standard",
          docid: fetch_docid(hit.hit[:code]),
          language: ["en"],
          script: ["Latn"],
          title: fetch_titles(doc),
          doctype: RelatonBib::DocumentType.new(type: "international-standard"),
          docstatus: fetch_status(doc),
          ics: fetch_ics(doc),
          date: fetch_dates(doc),
          # contributor: fetch_contributors(doc),
          editorialgroup: fetch_editorialgroup(doc),
          structuredidentifier: fetch_structuredid(hit.hit),
          abstract: fetch_abstract(doc),
          copyright: fetch_copyright(doc),
          link: fetch_link(doc.uri.to_s),
          relation: fetch_relations(doc),
          place: ["London"],
        )
      end

      private

      # @param doc [Mechanize::Page]
      # @return [Array<RelatonIsobib::Ics>]
      def fetch_ics(doc)
        doc.xpath("//tr[th[.='ICS']]/td/text()").filter_map do |ics|
          ics_code = ics.text.match(/[^\s]+/).to_s.gsub("\u00A0", "")
          next if ics_code.empty?

          RelatonIsoBib::Ics.new ics_code
        end
      end

      # Fetch abstracts.
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_abstract(doc)
        content = doc.at("//tr[th[.='Abstract/Scope']]/td")
        [{ content: content.text, language: "en", script: "Latn" }]
      end

      # Fetch docid.
      # @param ref [String]
      # @return [Array<RelatonBib::DocumentIdentifier>]
      def fetch_docid(ref)
        [RelatonBib::DocumentIdentifier.new(type: "CEN", id: ref, primary: true)]
      end

      # Fetch status.
      # @param doc [Mechanize::Page]
      # @return [RelatonBib::DocumentStatus, NilClass]
      def fetch_status(doc)
        s = doc.at("//tr[th[.='Status']]/td")
        return unless s

        RelatonBib::DocumentStatus.new(stage: s.text.strip)
      end

      # Fetch workgroup.
      # @param doc [Mechanize::Page]
      # @return [RelatonIsoBib::EditorialGroup]
      def fetch_editorialgroup(doc) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
        code = doc.at("//tr/td/h1/text()").text
        title = doc.at("//tr/td[3]/h1").text
        %r{/(?<type>\w+)(?:\s(?<num>[^/]+))?$} =~ code
        tc = []
        COMMITTEES.each do |k, v|
          next unless code.include? k

          t, n = k.split
          tc << RelatonBib::WorkGroup.new(name: v, type: t, number: n)
        end
        sc = []
        if tc.any?
          sc << RelatonBib::WorkGroup.new(name: title, type: type, number: num)
        else
          tc << RelatonBib::WorkGroup.new(name: title, type: type, number: num)
        end
        RelatonIsoBib::EditorialGroup.new(technical_committee: tc,
                                          subcommittee: sc)
      end

      # @param hit [RelatonCen::Hit]
      # @return [RelatonIsoBib::StructuredIdentifier]
      def fetch_structuredid(hit)
        %r{(?<pnum>\d+)(?:-(?<part>\d+))?(?:-(?<subpart>\d+))?} =~ hit[:code]
        RelatonIsoBib::StructuredIdentifier.new(
          project_number: pnum, part: part, subpart: subpart, type: "CEN",
        )
      end

      # Fetch relations.
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_relations(doc)
        doc.xpath(
          "//div[@id='DASHBOARD_LISTRELATIONS']/table/tr[th[.!='Sales Points']]",
        ).each_with_object([]) do |rt, a|
          type = relation_type rt.at("th").text.downcase
          rt.xpath("td/a").each do |r|
            a << { type: type, bibitem: create_relation(r) }
          end
        end
      end

      def relation_type(type)
        case type
        when "supersedes" then "obsoletes"
        when "superseded by" then "obsoletedBy"
        when /bibliographic references/ then "cites"
        when /normative reference/ then "cites"
        else type
        end
      end

      def create_relation(rel)
        fref = RelatonBib::FormattedRef.new(content: rel.text, language: "en", script: "Latn")
        link = fetch_link HitCollection::DOMAIN + rel[:href]
        BibliographicItem.new(formattedref: fref, type: "standard", link: link)
      end

      # Fetch titles.
      # @param doc [Mechanize::Page]
      # @return [RelatonBib::TypedTitleStringCollection]
      def fetch_titles(doc)
        te = doc.at("//tr[th[.='Title']]/td").text.strip
        RelatonBib::TypedTitleString.from_string te, "en", "Latn"
      end

      # Fetch dates
      # @param hit [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_dates(doc) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
        doc.xpath("//div[@id='DASHBOARD_LISTIMPLEMENTATIONDATES']/table/tr")
          .each_with_object([]) do |d, a|
          on = d.at("td").text
          next if on.empty?

          t = d.at("th").text
          type = case t
                 when /DOR/ then "adapted"
                 when /DAV/ then "issued"
                 when /DOA/ then "announced"
                 when /DOP/ then "published"
                 when /DOW/ then "obsoleted"
                 else t.downcase
                 end
          a << { type: type, on: on }
        end
      end

      # Fetch contributors
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      # def fetch_contributors(doc)
      #   contrib = { role: [type: "publisher"] }
      #   contrib[:entity] = owner_entity doc
      #   [contrib]
      # end

      # Fetch links.
      # @param url [String]
      # @return [Array<Hash>]
      def fetch_link(url)
        [{ type: "src", content: url }]
      end

      # Fetch copyright.
      # @param doc [Mechanize::Page]
      # @return [Array<Hash>]
      def fetch_copyright(doc)
        date = doc.at("//tr[th[.='date of Availability (DAV)']]/td").text
        owner = owner_entity
        from = date.match(/^\d{4}/).to_s
        [{ owner: [owner], from: from }]
      end

      # @return [Hash]
      def owner_entity
        {
          abbreviation: "CEN",
          name: "European Committee for Standardization",
          url: "https://cen.eu",
        }
      end
    end
  end
end
