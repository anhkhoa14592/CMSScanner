# frozen_string_literal: true

describe CMSScanner::Controller do
  subject(:controller) { described_class::Base.new }

  before do
    described_class::Base.option_parser = nil

    CMSScanner::ParsedCli.options = parsed_options
  end

  let(:parsed_options) { { url: 'http://example.com/' } }

  its(:option_parser)         { should be nil }
  its(:formatter)             { should be_a CMSScanner::Formatter::Cli }
  its(:user_interaction?)     { should be true }
  its(:tmp_directory)         { should eql '/tmp/cms_scanner' }
  its(:target)                { should be_a CMSScanner::Target }
  its('target.scope.domains') { should eq [PublicSuffix.parse('example.com')] }

  context 'when output option' do
    let(:parsed_options) { super().merge(output: '/tmp/spec.txt') }

    its(:user_interaction?) { should be false }
  end

  describe '#render' do
    it 'calls the formatter#render' do
      expect(controller.formatter).to receive(:render).with('test', { verbose: nil }, 'base')
      controller.render('test')
    end
  end
end
