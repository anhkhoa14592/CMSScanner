# frozen_string_literal: true

shared_examples CMSScanner::Target::Platform::PHP do
  before do
    if /\.log\z/i.match?(path)
      expect(target).to receive(:head_or_get_params).and_return(method: :head)

      stub_request(:head, target.url(path)).and_return(status: head_status)

      if head_status == 200
        stub_request(:get, target.url(path))
          .with(headers: { 'Range' => 'bytes=0-700' })
          .to_return(body: body)
      end
    else
      stub_request(:get, target.url(path)).to_return(body: body)
    end
  end

  describe '#debug_log?' do
    let(:path) { 'd.log' }

    context 'when the HEAD status is a 404' do
      let(:head_status) { 404 }

      it 'returns false' do
        expect(target.debug_log?(path)).to be false
      end
    end

    context 'when the HEAD status is a 200' do
      let(:head_status) { 200 }

      context 'when the body matches' do
        %w[debug.log db_error.log].each do |file|
          context "when #{file} body" do
            let(:body) { File.read(fixtures.join('debug_log', file)) }

            it 'returns true' do
              expect(target.debug_log?(path)).to be true
            end
          end
        end
      end

      context 'when the body does not match' do
        let(:body) { '' }

        it 'returns false' do
          expect(target.debug_log?(path)).to be false
        end
      end
    end
  end

  describe '#error_log?' do
    let(:path) { 'error.log' }

    context 'when the HEAD status is a 404' do
      let(:head_status) { 404 }

      it 'returns false' do
        expect(target.error_log?(path)).to be false
      end
    end

    context 'when the HEAD status is a 200' do
      let(:head_status) { 200 }

      context 'when the body matches' do
        %w[error.log].each do |file|
          context "when #{file} body" do
            let(:body) { File.read(fixtures.join('error_log', file)) }

            it 'returns true' do
              expect(target.error_log?(path)).to be true
            end
          end
        end
      end

      context 'when the body does not match' do
        let(:body) { '' }

        it 'returns false' do
          expect(target.error_log?(path)).to be false
        end
      end
    end
  end

  describe '#full_path_disclosure?, #full_path_disclosure_entries' do
    let(:path) { 'p.php' }

    context 'when the body matches a FPD' do
      {
        'wp_rss_functions.php' => %w[/short-path/rss-f.php]
      }.each do |file, expected|
        context "when #{file} body" do
          let(:body) { File.read(fixtures.join('fpd', file)) }

          it 'returns the expected array' do
            expect(target.full_path_disclosure_entries(path)).to eql expected
            expect(target.full_path_disclosure?(path)).to be true
          end
        end
      end
    end

    context 'when no FPD' do
      let(:body) { '' }

      it 'returns an empty array' do
        expect(target.full_path_disclosure_entries(path)).to eq []
        expect(target.full_path_disclosure?(path)).to be false
      end
    end
  end
end
