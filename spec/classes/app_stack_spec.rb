require 'spec_helper'

describe 'hdp::app_stack' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { 'dns_name' => 'hdp.test.com' } }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_group('docker').with_ensure('present') }
        it { is_expected.to contain_class('docker').with_log_driver('journald') }
        it { is_expected.to contain_class('docker::compose').with_ensure('present') }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp').with_ensure('directory') }
        it {
          is_expected.to contain_docker_compose('hdp')
            .with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml'])
            .that_requires('File[/opt/puppetlabs/hdp/docker-compose.yaml]')
            .that_subscribes_to('File[/opt/puppetlabs/hdp/docker-compose.yaml]')
        }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_owner('root')
            .with_group('docker')
            .with_content(%r{NAME=hdp\.test\.com})
            .with_content(%r{- "80:80"})
            .with_content(%r{- "443:443"})
        }
        dir_list = [
          '/opt/puppetlabs/hdp',
          '/opt/puppetlabs/hdp/minio',
          '/opt/puppetlabs/hdp/minio/config',
          '/opt/puppetlabs/hdp/minio/data',
          '/opt/puppetlabs/hdp/minio/data/facts',
          '/opt/puppetlabs/hdp/redis',
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

        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/elastic')
            .with_ensure('directory')
            .with_owner('1000')
            .with_group('1000')
        }
      end

      context 'with ui tls enabled' do
        let(:pre_condition) do
          <<-EOS
            file { "/tmp/ui-cert.key": ensure => present }
            file { "/tmp/ui-cert.pem": ensure => present }
          EOS
        end

        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'ui_use_tls' => true,
            'ui_cert_files_puppet_managed' => true,
            'ui_key_file' => '/tmp/ui-cert.key',
            'ui_cert_file' => '/tmp/ui-cert.pem',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_docker_compose('hdp')
            .with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml'])
            .that_requires(
              [
                'File[/tmp/ui-cert.key]',
                'File[/tmp/ui-cert.pem]',
                'File[/opt/puppetlabs/hdp/docker-compose.yaml]',
              ],
            )
            .that_subscribes_to(
              [
                'File[/tmp/ui-cert.key]',
                'File[/tmp/ui-cert.pem]',
                'File[/opt/puppetlabs/hdp/docker-compose.yaml]',
              ],
            )
        }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{- "80:80"})
            .with_content(%r{- "443:443"})
        }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- "80:80"}) }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- "443:443"}) }

        context 'with ui_ca_cert_file specified' do
          let(:pre_condition) do
            <<-EOS
              file { "/tmp/ui-ca.pem": ensure => present }
              file { "/tmp/ui-cert.key": ensure => present }
              file { "/tmp/ui-cert.pem": ensure => present }
            EOS
          end

          let(:params) do
            {
              'dns_name' => 'hdp.test.com',
              'ui_use_tls' => true,
              'ui_cert_files_puppet_managed' => true,
              'ui_ca_cert_file' => '/tmp/ui-ca.pem',
              'ui_key_file' => '/tmp/ui-cert.key',
              'ui_cert_file' => '/tmp/ui-cert.pem',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_docker_compose('hdp')
              .with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml'])
              .that_requires(
                [
                  'File[/tmp/ui-ca.pem]',
                  'File[/tmp/ui-cert.key]',
                  'File[/tmp/ui-cert.pem]',
                  'File[/opt/puppetlabs/hdp/docker-compose.yaml]',
                ],
              )
              .that_subscribes_to(
                [
                  'File[/tmp/ui-ca.pem]',
                  'File[/tmp/ui-cert.key]',
                  'File[/tmp/ui-cert.pem]',
                  'File[/opt/puppetlabs/hdp/docker-compose.yaml]',
                ],
              )
          }
        end

        context 'with host cert' do
          let(:pre_condition) do
            <<-EOS
              file { "/tmp/ui-ca.pem": ensure => present }
              file { "/tmp/ui-cert.key": ensure => present }
              file { "/tmp/ui-cert.pem": ensure => present }
            EOS
          end
          let(:trusted_facts) { { 'certname' => 'true.hdp' } }
          let(:node) { 'true.hdp' }
          let(:params) do
            {
              'dns_name' => 'true.hdp',
              'ui_use_tls' => true,
              'ui_cert_files_puppet_managed' => false,
              'ui_ca_cert_file' => '/tmp/ui-ca.pem',
            }
          end

          it { is_expected.to compile.with_all_deps }
          it {
            is_expected.to contain_docker_compose('hdp')
              .with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml'])
          }
          it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- \"/etc/puppetlabs/puppet/ssl/private_keys/true\.hdp\.pem:/etc/ssl/key\.pem:ro\"}) }
          it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- \"/etc/puppetlabs/puppet/ssl/certs/true\.hdp\.pem:/etc/ssl/cert\.pem:ro\"}) }
        end
      end

      context 'with seperate versions' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'image_repository' => 'hub.docker.com',
            'image_prefix' => '',
            'hdp_version' => 'foo',
            'ui_version' => 'bar',
            'frontend_version' => 'baz',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_owner('root')
            .with_group('docker')
            .with_content(%r{hub.docker.com/data-ingestion:foo})
            .with_content(%r{hub.docker.com/ui:bar})
            .with_content(%r{hub.docker.com/ui-frontend:baz})
        }
      end

      context 'with same versions' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'image_repository' => 'hub.docker.com',
            'image_prefix' => '',
            'hdp_version' => 'foo',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_owner('root')
            .with_group('docker')
            .with_content(%r{hub.docker.com/data-ingestion:foo})
            .with_content(%r{hub.docker.com/ui:foo})
            .with_content(%r{hub.docker.com/ui-frontend:foo})
        }
      end

      context 'set username + password' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'hdp_query_username' => 'super-user',
            'hdp_query_password' => sensitive('admin-password'),
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{- "HDP_HTTP_QUERY_USER=super-user"})
            .with_content(%r{- "HDP_HTTP_QUERY_PASSWORD=admin-password"})
        }
      end

      context 'set prometheus namespace' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'prometheus_namespace' => 'foo',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{- "HDP_ADMIN_PROMETHEUS_NAMESPACE=foo"})
        }
      end

      context 'set extra hosts' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'prometheus_namespace' => 'foo',
            'extra_hosts' => { 'foo' => '127.0.0.1', 'bar' => '1.1.1.1' },
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{extra_hosts:})
        }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{foo:127\.0\.0\.1})
        }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .with_content(%r{bar:1\.1\.1\.1})
        }
      end

      context 'no extra hosts' do
        let(:params) do
          {
            'dns_name' => 'hdp.test.com',
            'prometheus_namespace' => 'foo',
            'extra_hosts' => {},
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml')
            .without_content(%r{extra_hosts:})
        }
      end
    end
  end
end
