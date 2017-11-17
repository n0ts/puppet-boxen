require 'spec_helper'

describe 'boxen::personal' do
  context "username with dash" do
    let(:facts) { default_test_facts }

    it { should contain_class('boxen::config') }
    it { should contain_class('people::some_username') }
  end
end
