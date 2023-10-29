# frozen_string_literal: true

RSpec.describe RelatonCen do
  before { RelatonCen.instance_variable_set :@configuration, nil }

  it "has a version number" do
    expect(RelatonCen::VERSION).not_to be nil
  end

  it "returs grammar hash" do
    hash = RelatonCen.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "gets code" do
    VCR.use_cassette "cen_iso_ts_21003_7" do
      file = "spec/fixtures/bibdata.xml"
      bib = RelatonCen::CenBibliography.get "CEN ISO/TS 21003-7"
      xml = bib.to_xml bibdata: true
      write_file file, xml
      expect(xml).to be_equivalent_to read_xml(file)
      schema = Jing.new "grammars/relaton-iso-compile.rng"
      errors = schema.validate file
      expect(errors).to eq []
    end
  end

  it "get document with subcommittee" do
    VCR.use_cassette "subcommittee" do
      bib = RelatonCen::CenBibliography.get "EN 10160:1999"
      expect(bib.editorialgroup.subcommittee[0].name).to eq(
        "Test methods for steel (other than chemical analysis)",
      )
    end
  end

  it "get EN", vcr: "en_13306" do
    expect do
      bib = RelatonCen::CenBibliography.get "EN 13306"
      expect(bib.docidentifier[0].id).to eq "EN 13306"
    end.to output(/Found: `EN 13306`/).to_stderr
  end

  it "get ENV", vcr: "env_1993_1_1" do
    bib = RelatonCen::CenBibliography.get "ENV 1613:1995"
    expect(bib.docidentifier[0].id).to eq "ENV 1613:1995"
  end

  it "get CWA", vcr: "cwa_14050_21_2000" do
    bib = RelatonCen::CenBibliography.get "CWA 14050-21:2000"
    expect(bib.docidentifier[0].id).to eq "CWA 14050-21:2000"
  end

  it "get HD", vcr: "hd_1215_2_1988" do
    bib = RelatonCen::CenBibliography.get "HD 1215-2:1988"
    expect(bib.docidentifier[0].id).to eq "HD 1215-2:1988"
  end

  it "keeep year", vcr: "en_13306" do
    expect do
      bib = RelatonCen::CenBibliography.get "EN 13306", nil, keep_year: true
      expect(bib.docidentifier[0].id).to eq "EN 13306:2017"
    end.to output(/Found: `EN 13306:2017`/).to_stderr
  end

  it "get amendment" do
    VCR.use_cassette "en_285_2015_a1_2021" do
      bib = RelatonCen::CenBibliography.get "EN 285:2015+A1"
      expect(bib.docidentifier[0].id).to eq "EN 285:2015+A1:2021"
    end
  end

  it "get lates without part & year" do
    VCR.use_cassette "en_1325" do
      bib = RelatonCen::CenBibliography.get "EN 1325"
      expect(bib.docidentifier[0].id).to eq "EN 1325"
    end
  end

  context "get document by year" do
    before { RelatonCen.instance_variable_set :@configuration, nil }

    it "in code" do
      VCR.use_cassette "cen_iso_ts_21003_7" do
        bib = RelatonCen::CenBibliography.get "CEN ISO/TS 21003-7:2019"
        expect(bib.docidentifier[0].id).to eq "CEN ISO/TS 21003-7:2019"
      end
    end

    it "in option", vcr: "cen_iso_ts_21003_7" do
      expect do
        bib = RelatonCen::CenBibliography.get "CEN ISO/TS 21003-7", "2019"
        expect(bib.docidentifier[0].id).to eq "CEN ISO/TS 21003-7:2019"
      end.to output(/\(CEN ISO\/TS 21003-7:2019\) Found: `CEN ISO\/TS 21003-7:2019`/).to_stderr
    end

    it "return nil when year is incorrect" do
      VCR.use_cassette "cen_iso_ts_21003_7" do
        bib = ""
        expect do
          bib = RelatonCen::CenBibliography.get "CEN ISO/TS 21003-7", "2018"
        end.to output(/There was no match for `2018`/).to_stderr
        expect(bib).to be_nil
      end
    end
  end

  it "raise RequestError" do
    agent = double "Mechanize agent"
    expect(agent).to receive(:user_agent_alias=)
    page = double "Mechanize response", code: 500
    expect(agent).to receive(:get).and_raise Mechanize::ResponseCodeError.new(page)
    expect(Mechanize).to receive(:new).and_return agent
    expect do
      RelatonCen::CenBibliography.get "CEN ISO/TS 21003-7"
    end.to raise_error RelatonBib::RequestError
  end

  it "returns nil when document doesn't exist" do
    VCR.use_cassette "not_found" do
      bib = ""
      expect do
        bib = RelatonCen::CenBibliography.get "CEN NOT FOUND"
      end.to output(/\[relaton-cen\] \(CEN NOT FOUND\) No found\./).to_stderr
      expect(bib).to be_nil
    end
  end

  it "returns nil when referense is empty" do
    bib = RelatonCen::CenBibliography.get ""
    expect(bib).to be_nil
  end
end
