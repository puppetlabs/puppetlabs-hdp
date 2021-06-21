require 'spec_helper'

describe 'hdp::report_processor' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:pre_condition) { "service { 'pe-puppetserver': }" }

      # rubocop:disable Metrics/LineLength
      context 'with a hdp_url string value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp.example.com/in',
            'pe_console' => 'pe-console.example.com',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{^# managed by puppet hdp module\n---\n'hdp_urls':\n  - 'https://hdp.example.com/in'\n'pe_console': 'pe-console.example.com'\n$}) }
      end

      context 'with a hdp_url array value' do
        let(:params) do
          {
            'hdp_url' => [
              'https://hdp-prod.example.com/in',
              'https://hdp-stage.example.com/in',
            ],
            'pe_console' => 'pe-console.example.com',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{^# managed by puppet hdp module\n---\n'hdp_urls':\n  - 'https://hdp-prod.example.com/in'\n  - 'https://hdp-stage.example.com/in'\n'pe_console': 'pe-console.example.com'\n$}) }
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
