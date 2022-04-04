# frozen_string_literal: true

%i[Generic Apache IIS Nginx].each do |server|
  describe CMSScanner::Target do
    subject(:target) do
      described_class.new(url).extend(described_class::Server.const_get(server))
    end

    let(:url)      { 'http://e.org' }
    let(:fixtures) { FIXTURES.join('target', 'server', server.to_s.downcase) }

    it_behaves_like described_class::Server.const_get(server)
  end
end
