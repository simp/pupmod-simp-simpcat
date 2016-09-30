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

        let(:pre_condition) {
          content =  <<-EOM
            simpcat_build { 'simpcat_test':
              target => '/tmp/foo/bar.baz'
            }
            simpcat_fragment { 'fragment1+simpcat_test':
              content => 'This is my amazing test'
            }
            $foo = simpcat_fragmentdir('simpcat_test')
            notify { $foo: }
          EOM

          content
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_simpcat_fragment('fragment1+simpcat_test') }
        it { is_expected.to contain_simpcat_build('simpcat_test') }
        it { is_expected.to contain_notify('/var/lib/puppet/simpcat/fragments/simpcat_test') }
      end
    end
  end
end
