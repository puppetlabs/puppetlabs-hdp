require 'spec_helper'

describe 'hdp::proxy' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          'dns_name' => 'hdp.test.com',
          'token' => sensitive('token-town-usa'),
          'hdp_address' => 'https://hdp.com',
        }
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_group('docker').with_ensure('present') }
        it { is_expected.to contain_class('docker').with_log_driver('journald') }
        it { is_expected.to contain_class('docker::compose').with_ensure('present') }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp').with_ensure('directory') }
        it {
          is_expected.to contain_docker_compose('hdp-proxy')
            .with_compose_files(['/opt/puppetlabs/hdp/proxy/docker-compose.yaml'])
            .that_requires('File[/opt/puppetlabs/hdp/proxy/docker-compose.yaml]')
            .that_subscribes_to('File[/opt/puppetlabs/hdp/proxy/docker-compose.yaml]')
        }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
            .with_owner('root')
            .with_group('docker')
            .with_content(%r{NAME=hdp\.test\.com})
            .with_content(%r{- "9091:9091"})
            .with_content(%r{- "HDP_BACKENDS_HDP_ADDRESS=https://hdp\.com"})
        }
        dir_list = [
          '/opt/puppetlabs/hdp',
          '/opt/puppetlabs/hdp/ssl',
        ]

        dir_list.each do |d|
          it {
            is_expected.to contain_file(d)
              .with_ensure('directory')
              .with_owner('11223')
              .with_group('11223')
          }
        end
      end

      context 'with specific version' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'image_repository' => 'hub.docker.com',
            'image_prefix' => '',
            'version' => 'foo',
            'token' => sensitive('test-token'),
            'hdp_address' => 'https://hdp.com',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
            .with_owner('root')
            .with_group('docker')
            .with_content(%r{hub.docker.com/data-ingestion:foo})
        }
      end

      context 'hdp admin config options' do
        context 'set prometheus namespace' do
          let(:params) do
            {
              'dns_name' => 'hdp.test.com',
              'token' => sensitive('test-token'),
              'hdp_address' => 'https://hdp.com',
              'prometheus_namespace' => 'foo',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
              .with_content(%r{- "HDP_ADMIN_PROMETHEUS_NAMESPACE=foo"})
          }
        end
      end

      context 'extra hosts' do
        context 'set extra hosts' do
          let(:params) do
            {
              'dns_name' => 'hdp.test.com',
              'token' => sensitive('test-token'),
              'hdp_address' => 'https://hdp.com',
              'prometheus_namespace' => 'foo',
              'extra_hosts' => { 'foo' => '127.0.0.1', 'bar' => '1.1.1.1' },
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
              .with_content(%r{extra_hosts:})
          }
          it {
            is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
              .with_content(%r{foo:127\.0\.0\.1})
          }
          it {
            is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
              .with_content(%r{bar:1\.1\.1\.1})
          }
        end

        context 'no extra hosts' do
          let(:params) do
            {
              'dns_name' => 'hdp.test.com',
              'token' => sensitive('test-token'),
              'hdp_address' => 'https://hdp.com',
              'prometheus_namespace' => 'foo',
              'extra_hosts' => {},
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
              .without_content(%r{extra_hosts:})
          }
        end
      end

      context 'token, org, and region' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'organization' => 'puppet',
            'region' => 'PDX',
            'token' => sensitive('$1$tokencity'),
            'hdp_address' => 'https://hdp.com',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/proxy/docker-compose.yaml')
            .with_content(%r{- "HDP_BACKENDS_HDP_ORGANIZATION=puppet"})
            .with_content(%r{- "HDP_BACKENDS_HDP_REGION=PDX"})
            .with_content(%r{- "HDP_BACKENDS_HDP_TOKEN=\$\$1\$\$tokencity"})
        }
      end
    end
  end
end
