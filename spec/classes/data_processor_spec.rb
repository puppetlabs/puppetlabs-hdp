require 'spec_helper'

describe 'hdp::data_processor' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:pre_condition) { "service { 'pe-puppetserver': }" }

      context 'with a hdp_url string value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp.example.com:9091',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('hdp::resource_collector') }
        it {
          is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml')
            .with_content(%r{'hdp_urls':\n  - 'https://hdp.example.com:9091'\n'})
        }
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
        it { is_expected.to contain_ini_setting('puppetdb_submit_only_server_urls').with_ensure('absent') }
      end

      context 'with a hdp_url array value' do
        let(:params) do
          {
            'hdp_url' => [
              'https://hdp-prod.example.com:9091',
              'https://hdp-stage.example.com:9091',
            ],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml')
            .with_content(%r{'hdp_urls':\n  - 'https://hdp-prod.example.com:9091'\n  - 'https://hdp-stage.example.com:9091'\n})
        }
      end

      context 'with a keep_node_re value' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp-prod.example.com:9091',
            'keep_node_re' => '^a.*',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml')
            .with_content(%r{^'keep_nodes': '\^a\.\*'\n})
        }
      end

      context 'with collection_method set to pdb_submit_only_server_urls' do
        let(:params) do
          {
            'hdp_url' => 'https://hdp-prod.example.com:9091',
            'collection_method' => 'pdb_submit_only_server_urls',
          }
        end

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppet/hdp.yaml')
            .with_ensure('absent')
            .that_notifies('Service[pe-puppetserver]')
        }
        it {
          is_expected.to contain_file('/etc/puppetlabs/hdp/hdp_routes.yaml')
            .with_ensure('absent')
            .that_notifies('Service[pe-puppetserver]')
        }
        it {
          is_expected.to contain_ini_setting('remove routes_file setting from puppet.conf')
            .with_ensure('absent')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_section('master')
            .with_setting('route_file')
            .that_notifies('Service[pe-puppetserver]')
        }

        context 'with a single hdp_url' do
          let(:params) do
            {
              'hdp_url' => 'https://hdp-prod.example.com:9091',
              'collection_method' => 'pdb_submit_only_server_urls',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_ini_setting('puppetdb_submit_only_server_urls')
              .with_path('/etc/puppetlabs/puppet/puppetdb.conf')
              .with_section('main')
              .with_setting('submit_only_server_urls')
              .with_value('https://hdp-prod.example.com:9091')
              .that_notifies('Service[pe-puppetserver]')
          }
        end

        context 'with an array for hdp_url' do
          let(:params) do
            {
              'hdp_url' => [
                'https://hdp-prod.example.com:9091',
                'https://hdp-stage.example.com:9091',
              ],
              'collection_method' => 'pdb_submit_only_server_urls',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_ini_setting('puppetdb_submit_only_server_urls')
              .with_path('/etc/puppetlabs/puppet/puppetdb.conf')
              .with_section('main')
              .with_setting('submit_only_server_urls')
              .with_value('https://hdp-prod.example.com:9091,https://hdp-stage.example.com:9091')
              .that_notifies('Service[pe-puppetserver]')
          }
        end

        context 'with multiple pdb_submit_only_server_urls' do
          let(:params) do
            {
              'hdp_url' => 'https://hdp-prod.example.com:9091',
              'collection_method' => 'pdb_submit_only_server_urls',
              'pdb_submit_only_server_urls' => [
                'https://additional-destination1.example.com',
                'https://additional-destination2.example.com',
              ],
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_ini_setting('puppetdb_submit_only_server_urls')
              .with_path('/etc/puppetlabs/puppet/puppetdb.conf')
              .with_section('main')
              .with_setting('submit_only_server_urls')
              .with_value('https://additional-destination1.example.com,https://additional-destination2.example.com,https://hdp-prod.example.com:9091')
              .that_notifies('Service[pe-puppetserver]')
          }
        end

        context 'with pdb_submit_only_server_urls and duplicate entries' do
          # This validates that the unique function is working as anticipated when combining
          # hdp_url with pdb_submit_only_server_urls
          let(:params) do
            {
              'hdp_url' => 'https://hdp-prod.example.com:9091',
              'collection_method' => 'pdb_submit_only_server_urls',
              'pdb_submit_only_server_urls' => [
                'https://hdp-prod.example.com:9091',
                'https://additional-destination.example.com',
              ],
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_ini_setting('puppetdb_submit_only_server_urls')
              .with_path('/etc/puppetlabs/puppet/puppetdb.conf')
              .with_section('main')
              .with_setting('submit_only_server_urls')
              .with_value('https://hdp-prod.example.com:9091,https://additional-destination.example.com')
              .that_notifies('Service[pe-puppetserver]')
          }
        end
      end
    end
  end
end
