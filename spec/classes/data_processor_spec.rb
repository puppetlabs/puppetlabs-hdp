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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('hdp::resource_collector') }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{'hdp_urls':\n  - 'https://hdp.example.com/in'\n'}) }
        it {
          is_expected.to contain_file('/etc/puppetlabs/hdp')
            .with_ensure('directory')
            .with_owner('pe-puppet')
            .with_group('pe-puppet')
        }
        it {
          is_expected.to contain_file('/etc/puppetlabs/hdp/hdp_routes.yaml')
            .with_ensure('file')
            .with_owner('pe-puppet')
            .with_group('pe-puppet')
            .with_content(%r{    terminus: "hdp"})
            .with_content(%r{    cache: "hdp"})
            .that_notifies('Service[pe-puppetserver]')
        }
        it {
          is_expected.to contain_ini_setting('enable hdp_routes.yaml')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_section('master')
            .with_setting('route_file')
            .with_value('/etc/puppetlabs/hdp/hdp_routes.yaml')
            .that_requires('File[/etc/puppetlabs/hdp/hdp_routes.yaml]')
            .that_notifies('Service[pe-puppetserver]')
        }
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

        it { is_expected.to compile.with_all_deps }
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

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml').with_content(%r{'hdp_urls':\n  - 'https://hdp-prod.example.com/in'\n  - 'https://hdp-stage.example.com/in'\n'keep_nodes': '\^a\.\*'}) }
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
