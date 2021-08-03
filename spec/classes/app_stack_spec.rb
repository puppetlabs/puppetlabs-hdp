require 'spec_helper'

describe 'hdp::app_stack' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) { { 'dns_name' => 'hdp.test.com' } }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to  contain_group('docker').with_ensure('present') }
        it { is_expected.to  contain_class('docker').with_log_driver('journald') }
        it { is_expected.to  contain_class('docker::compose').with_ensure('present') }
        it { is_expected.to  contain_file('/opt/puppetlabs/hdp').with_ensure('directory') }
        it { is_expected.to  contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{NAME=hdp\.test\.com}) }
        it { is_expected.to  contain_docker_compose('hdp').with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml']) }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- "80:80"}) }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').without_content(%r{- "443:443"}) }
      end

      context 'with ui tls enabled' do
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
            'ui_ca_cert_file' => '/tmp/ui-ca.pem',
            'ui_key_file' => '/tmp/ui-cert.key',
            'ui_cert_file' => '/tmp/ui-cert.pem',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to  contain_file('/tmp/ui-ca.pem').that_comes_before('Docker_compose[hdp]') }
        it { is_expected.to  contain_file('/tmp/ui-cert.key').that_comes_before('Docker_compose[hdp]') }
        it { is_expected.to  contain_file('/tmp/ui-cert.pem').that_comes_before('Docker_compose[hdp]') }
        it {
          is_expected.to contain_docker_compose('hdp').that_subscribes_to(
            [
              'File[/tmp/ui-ca.pem]',
              'File[/tmp/ui-cert.key]',
              'File[/tmp/ui-cert.pem]',
              # 'File[/opt/puppetlabs/hdp/docker-compose.yaml]',
            ],
          )
        }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- "80:80"}) }
        it { is_expected.to contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{- "443:443"}) }
      end
    end
  end
end
