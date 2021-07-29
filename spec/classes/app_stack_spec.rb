require 'spec_helper'

describe 'hdp::app_stack' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to  contain_group('docker').with_ensure('present') }
        it { is_expected.to  contain_class('docker').with_log_driver('journald') }
        it { is_expected.to  contain_class('docker::compose').with_ensure('present') }
        it { is_expected.to  contain_file('/opt/puppetlabs/hdp').with_ensure('directory') }
        it { is_expected.to  contain_file('/opt/puppetlabs/hdp/docker-compose.yaml').with_content(%r{puppet\/hdp-ingest-queue:\d+\.\d+\.\d+(-[a-z]+(\.[0-9]+)?)?"$}) }
        it { is_expected.to  contain_docker_compose('hdp').with_compose_files(['/opt/puppetlabs/hdp/docker-compose.yaml']) }
      end
    end
  end
end
