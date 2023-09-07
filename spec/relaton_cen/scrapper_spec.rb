describe RelatonCen::Scrapper do
  it "don't fetch empty ICS code" do
    doc = Nokogiri::HTML <<~HTML
      <tbody>
        <tr>
          <th class="detail" width="35%">ICS</th>
          <td>&nbsp;</td>
        </tr>
      </tbody>
    HTML
    expect(RelatonCen::Scrapper.send(:fetch_ics, doc)).to be_empty
  end
end
