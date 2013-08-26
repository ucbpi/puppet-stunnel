require 'spec_helper'

describe 'stunnel' do
  context "=> redhat" do
    let(:facts) { { 'osfamily' => 'RedHat' } }

    context "=> install helper script" do
      # make sure we include stunnel::data
      it do
        should contain_stunnel__data
      end

      # install our cert generation script used by the stunnel::tun
      it do
        file_loc = '/usr/local/bin/stunnel-combine-certs'
        params = {
          'owner' => 'root',
          'group' => 'root',
          'mode'  => '0555',
          'ensure' => 'present',
        }

        should contain_file( file_loc ).with( params )
      end
    end
  end
  context "=> Debian/Ubuntu" do
    let(:facts) { { 'osfamily' => 'Debian' } }

    context "=> install helper script" do
      # make sure we include stunnel::data
      it do
        should contain_stunnel__data
      end

      # install our cert generation script used by the stunnel::tun
      it do
        file_loc = '/usr/local/bin/stunnel-combine-certs'
        params = {
          'owner' => 'root',
          'group' => 'root',
          'mode'  => '0555',
          'ensure' => 'present',
        }

        should contain_file( file_loc ).with( params )
      end
    end
  end

  context "=> other OS families" do
    it do
      expect {
        should contain_stunnel__data
      }.to raise_error(Puppet::Error,/unsupported/i)
    end
  end
end
