require 'spec_helper'

describe "boxen::environment" do
  context "projects from cli" do
    let(:facts) { default_test_facts }

    let(:projects_file){ File.expand_path('../../fixtures/.projects', __FILE__) }

    before do
      File.open(projects_file, 'w+') do |f|
        f.truncate 0
        f.write 'test'
      end
    end

    after do
      FileUtils.rm_f(projects_file)
    end

    it do
      should contain_class("projects::test")
    end
  end
end
