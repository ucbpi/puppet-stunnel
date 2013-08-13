require 'spec_helper'

describe 'stunnel::install' do
  context "=> installs package" do
    it do
      should contain_package('stunnel')
    end
  end
end
