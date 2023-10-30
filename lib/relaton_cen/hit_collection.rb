# frozen_string_literal: true

module RelatonCen
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    DOMAIN = "https://standards.cencenelec.eu/dyn/www/"

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

      search_page = agent.get "#{DOMAIN}f?p=205:105:0:::::"
      form = search_page.at "//form[@id='wwvFlowForm']"
      skip_inputs = %w[f11 essentialCookies]
      req_body = form.xpath(".//input").filter_map do |f|
        next if f[:name].empty? || skip_inputs.include?(f[:name])

        val = case f[:value]
              when "LANGUAGE_LIST" then 0
              when "STAND_REF" then CGI.escape(ref)
              else
                case f[:name]
                when "p_request" then "S1-S2-S3-S4-S5-S6-S7-CEN-CLC-"
                when "f10" then ""
                else f[:value]
                end
              end
        if f[:name] == "f10" then "f10=#{f[:value]}&f11=#{val}"
        else
          "#{f[:name]}=#{val}"
        end
      end.join("&")
      resp = agent.post form[:action], req_body
      @array = hits resp
      sort
    end

    private

    def sort
      @array.sort! do |a, b|
        ap = CenBibliography.code_to_parts a.hit[:code]
        bp = CenBibliography.code_to_parts b.hit[:code]
        s = ap[:code] <=> bp[:code]
        s = ap[:part].to_s <=> bp[:part].to_s if s.zero?
        s = bp[:year].to_s <=> ap[:year].to_s if s.zero?
        s = ap[:amd].to_s <=> bp[:amd].to_s if s.zero?
        s = ap[:amy].to_s <=> bp[:amy].to_s if s.zero?
        s = ap[:ac].to_s <=> bp[:ac].to_s if s.zero?
        s
      end
    end

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
