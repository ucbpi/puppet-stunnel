require 'spec_helper'

describe 'stunnel::config' do
  context "=> redhat os family support" do
    let(:facts) { { 'osfamily' => 'RedHat' } }
    it do
      params = {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0555',
      }
      should contain_file('/etc/stunnel').with(params)
      should contain_file('/etc/stunnel/conf.d').with(params)
      should contain_file('/var/log/stunnel').with(params)
    end
  end
  context "=> Debian os family support" do
    let(:facts) { { 'osfamily' => 'Debian' } }
    it do
      params = {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0555',
      }
      should contain_file('/etc/stunnel').with(params)
      should contain_file('/etc/stunnel/conf.d').with(params)
      should contain_file('/var/log/stunnel4').with(params)
    end
  end
end
