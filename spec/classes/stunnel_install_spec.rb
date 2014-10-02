require 'spec_helper'

describe 'stunnel::install' do
  context "=> install package on redhat" do
    let(:facts) { { 'osfamily' => 'RedHat' } }
    it do
      should contain_package('stunnel')
      should contain_package('redhat-lsb')
    end
  end

  context "=> install package on debian" do
    let(:facts) { { 'osfamily' => 'Debian' } }
    it do
      should contain_package('stunnel4')
      should contain_package('lsb-base')
    end
  end
end
