describe RelatonCen do
  after { RelatonCen.instance_variable_set :@configuration, nil }

  it "configure" do
    RelatonCen.configure do |conf|
      conf.logger = :logger
    end
    expect(RelatonCen.configuration.logger).to eq :logger
  end
end
