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
            concat_build { 'concat_test':
              target => '/tmp/foo/bar.baz'
            }
            concat_fragment { 'fragment1+concat_test':
              content => 'This is my amazing test'
            }
            $foo = fragmentdir('concat_test')
            notify { $foo: }
          EOM

          content
        }
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_concat_fragment('fragment1+concat_test') }
        it { is_expected.to contain_concat_build('concat_test') }
        it { is_expected.to contain_notify('/var/lib/puppet/concat/fragments/concat_test') }
      end
    end
  end
end
