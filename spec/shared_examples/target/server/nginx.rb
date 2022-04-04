# frozen_string_literal: true

shared_examples CMSScanner::Target::Server::Nginx do
  describe '#server' do
    its(:server) { should eq :Nginx }
  end

  describe '#directory_listing?, #directory_listing_entries' do
    before     { stub_request(:get, target.url(path)).to_return(body: body, status: status) }
    let(:path) { 'somedir' }

    context 'when not a 200' do
      let(:status) { 404 }
      let(:body)   { '' }

      it 'returns false and an empty array' do
        expect(target.directory_listing?(path)).to be false
        expect(target.directory_listing_entries(path)).to eql []
      end
    end

    context 'when 200' do
      let(:status) { 200 }
      let(:body)   { File.read(fixtures.join('directory_listing', 'fanart.html')) }

      it 'returns true and the expected array' do
        expect(target.directory_listing?(path)).to be true
        expect(target.directory_listing_entries(path)).to eql %w[1931/ 720/ down]
      end
    end

    context 'when no files nor folders' do
      let(:status) { 200 }
      let(:body)   { File.read(fixtures.join('directory_listing', 'empty.html')) }

      it 'returns true and the an empty array' do
        expect(target.directory_listing?(path)).to be true
        expect(target.directory_listing_entries(path)).to eql []
      end
    end
  end
end
