# frozen_string_literal: true

shared_examples CMSScanner::Formatter::Buffer do
  describe '#buffer' do
    its(:buffer) { should be_empty }
  end
end
