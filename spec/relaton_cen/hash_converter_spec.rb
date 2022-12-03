describe RelatonCen::HashConverter do
  it "create bibitem from hash" do
    item = RelatonCen::HashConverter.bib_item(title: ["title"])
    expect(item).to be_instance_of RelatonCen::BibliographicItem
  end
end
