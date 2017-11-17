require 'spec_helper'

describe 'boxen::bin' do
  let(:facts) { default_test_facts }

  it { should contain_class('boxen::config') }
  it { should contain_file("#{facts[:boxen_home]}/bin/boxen") }
end
