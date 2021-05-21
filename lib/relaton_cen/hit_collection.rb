# frozen_string_literal: true

require "relaton_cen/hit"

module RelatonCen
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    DOMAIN = "https://standards.cen.eu/dyn/www/"

    # @return [Mechanize]
    attr_reader :agent

    # @param ref [String]
    # @param year [String]
    def initialize(ref, year = nil) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      super ref, year
      @agent = Mechanize.new
      agent.user_agent_alias = "Mac Safari"
      if !ref || ref.empty?
        @array = []
        return
      end

      search_page = agent.get "#{DOMAIN}f?p=204:105:0:::::"
      form = search_page.at "//form"
      req_body = form.xpath("//input").map do |f|
        next if f[:name].empty? || f[:name] == "f11"

        val = case f[:value]
              when "LANGUAGE_LIST" then 0
              when "STAND_REF" then ref
              else
                case f[:name]
                when "p_request" then "S1-S2-S3-S4-S5-S6"
                when "f10" then ""
                else f[:value]
                end
              end
        if f[:name] == "f10" then "f10=#{f[:value]}&f11=#{val}"
        else "#{f[:name]}=#{val}"
        end
      end.compact.join("&")
      resp = agent.post form[:action], req_body
      @array = hits resp
    end

    private

    # @param resp [Mechanize::Page]
    # @return [Array<RelatonCen::Hit>]
    def hits(resp)
      resp.xpath("//table[@class='dashlist']/tbody/tr/td[2]").map do |h|
        ref = h.at("strong/a")
        code = ref.text.strip
        url = ref[:href]
        Hit.new({ code: code, url: url }, self)
      end
    end
  end
end
