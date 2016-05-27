require 'spec_helper'

# This is silly but just hacking around the requirement for a matching class
# name for now.
#
# We'll eventually move to using the Puppet version of concat.
describe 'stdlib' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        let(:precondition) {
          content <<-EOM
            concat_build('concat_test')
            concat_fragment('fragment1+concat_test') {
              content => 'This is my amazing test'
            }
          EOM

          content
        }

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
