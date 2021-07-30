require 'spec_helper'

describe 'hdp::data_processor' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:pre_condition) { "service { 'pe-puppetserver': }" }

      # rubocop:disable Metrics/LineLength
      context 'with a hdp_url string value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp.example.com/in',
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{'hdp_urls':\n  - 'https://hdp.example.com/in'\n'}) }
      end

      context 'with a hdp_url array value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp-prod.example.com/in',
            'extra_hdp_urls' => [
              'https://hdp-stage.example.com/in',
            ],
          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{'hdp_urls':\n  - 'https://hdp-prod.example.com/in'\n  - 'https://hdp-stage.example.com/in'\n}) }
      end

      context 'with a keep_node_re value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp-prod.example.com/in',
            'extra_hdp_urls' => [
              'https://hdp-stage.example.com/in',
            ],
            'keep_node_re' => '^a.*',

          }
        end

        it { is_expected.to compile }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{'hdp_urls':\n  - 'https://hdp-prod.example.com/in'\n  - 'https://hdp-stage.example.com/in'\n'keep_nodes': '\^a\.\*'}) }
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
