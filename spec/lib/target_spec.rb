# frozen_string_literal: true

describe CMSScanner::Target do
  subject(:target) { described_class.new(url) }
  let(:url)        { 'http://e.org' }
  let(:fixtures)   { FIXTURES.join('target') }

  describe '#interesting_findings' do
    before do
      expect(CMSScanner::Finders::InterestingFindings::Base).to receive(:find).and_return(stubbed)
    end

    context 'when no findings' do
      let(:stubbed) { [] }

      its(:interesting_findings) { should eq stubbed }
    end

    context 'when findings' do
      let(:stubbed) { ['yolo'] }

      it 'allows findings to be added with <<' do
        expect(target.interesting_findings).to eq stubbed

        target.interesting_findings << 'other-finding'

        expect(target.interesting_findings).to eq(stubbed << 'other-finding')
      end
    end
  end

  describe '#vulnerable' do
    it 'raises an error' do
      expect { target.vulnerable? }.to raise_error(NotImplementedError)
    end
  end

  describe '#url_pattern' do
    its(:url_pattern) { should eql %r{https?:\\?/\\?/e\.org\\?/}i }
    its(:url_pattern) { should match 'https:\/\/e.org\/' }

    context 'when already https protocol' do
      let(:url) { 'htTpS://ex.com/' }

      its(:url_pattern) { should eql %r{https?:\\?/\\?/ex\.com\\?/}i }
    end
  end

  describe '#xpath_pattern_from_page' do
    # Handled in #comments_from_page & #javascripts_from_page
  end

  describe '#comments_from_page' do
    let(:fixture) { fixtures.join('comments.html') }
    let(:page)    { Typhoeus::Response.new(body: File.read(fixture)) }

    context 'when the pattern does not match anything' do
      it 'returns an empty array' do
        expect(target.comments_from_page(/none/, page)).to eql([])
      end
    end

    context 'when the pattern matches' do
      let(:pattern) { /all in one seo pack/i }
      let(:s1) { 'All in One SEO Pack 2.2.5.1 by Michael Torbert of Semper Fi Web Design' }
      let(:s2) { '/all in one seo pack' }

      context 'when no block given' do
        it 'returns the expected matches' do
          results = target.comments_from_page(pattern, page)

          [s1, s2].each_with_index do |s, i|
            expect(results[i].first).to eql s.match(pattern)
            expect(results[i].last.to_s).to eql "<!-- #{s} -->"
          end
        end
      end

      # The below doesn't work, dunno why
      # Would need to find a way to ensure the MatchData and XML::Comment are correct
      context 'when block given' do
        it 'yield the MatchData' do
          expect { |b| target.comments_from_page(pattern, page, &b) }
            .to yield_successive_args(
              [MatchData, Nokogiri::XML::Comment],
              [MatchData, Nokogiri::XML::Comment]
            )
        end
      end
    end

    context 'when invalid byte sequence' do
      let(:page) { Typhoeus::Response.new(body: "<!-- \xEB -->") }

      it 'does not raise an error' do
        expect { target.comments_from_page(/none/, page) }.to_not raise_error
      end
    end
  end

  describe '#javascripts_from_page' do
    let(:fixture) { fixtures.join('javascripts.html') }
    let(:page)    { Typhoeus::Response.new(body: File.read(fixture)) }

    context 'when the pattern does not match anything' do
      it 'returns an empty array' do
        expect(target.javascripts_from_page(/none/, page)).to eql([])
      end
    end

    context 'when the pattern matches' do
      let(:pattern) { /_version =/i }
      let(:s)       { "var _version = '1.2.4';" }

      context 'when no block given' do
        it 'returns the expected matches' do
          results = target.javascripts_from_page(pattern, page)

          expect(results[0].first).to eql s.match(pattern)
          expect(results[0].last.text.to_s).to eql s
        end
      end

      # The below doesn't work, dunno why
      # # Would need to find a way to ensure the MatchData and XML::Element are correct
      context 'when block given' do
        it 'yield the MatchData' do
          expect { |b| target.javascripts_from_page(pattern, page, &b) }
            .to yield_successive_args(
              [MatchData, Nokogiri::XML::Element]
            )
        end
      end
    end
  end

  describe '#uris_from_page' do
    let(:page) { Typhoeus::Response.new(body: File.read(fixtures.join('uris_from_page.html'))) }

    context 'when block given' do
      it 'yield the url' do
        expect { |b| target.uris_from_page(page, &b) }
          .to yield_successive_args(
            [Addressable::URI.parse('http://e.org/f.txt'), Nokogiri::XML::Element],
            [Addressable::URI.parse('https://cdn.e.org/f2.js'), Nokogiri::XML::Element],
            [Addressable::URI.parse('http://e.org/script/s.js'), Nokogiri::XML::Element],
            [Addressable::URI.parse('http://wp-lamp/feed.xml'), Nokogiri::XML::Element],
            [Addressable::URI.parse('http://g.com/img.jpg'), Nokogiri::XML::Element],
            [Addressable::URI.parse('http://g.org/logo.png'), Nokogiri::XML::Element]
          )
      end
    end

    context 'when no block given' do
      it 'returns the expected array' do
        expect(target.uris_from_page(page)).to eql(
          %w[
            http://e.org/f.txt https://cdn.e.org/f2.js http://e.org/script/s.js
            http://wp-lamp/feed.xml http://g.com/img.jpg http://g.org/logo.png
          ].map { |url| Addressable::URI.parse(url) }
        )
      end

      context 'when xpath argument given' do
        it 'returns the expected array' do
          xpath = '//link[@rel="alternate" and @type="application/rss+xml"]/@href'

          expect(target.uris_from_page(page, xpath)).to eql([Addressable::URI.parse('http://wp-lamp/feed.xml')])
        end
      end
    end
  end
end
