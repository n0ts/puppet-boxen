require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.mock_framework = :rspec
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.hiera_config = File.join(fixture_path, 'hiera/hiera.yaml')
end

def default_test_facts
  {
    :boxen_home    => '/opt/boxen',
    :boxen_repodir =>  File.join(File.dirname(__FILE__), 'fixtures'),
    :boxen_repo_url_template => "https://github.com/%s",
    :boxen_srcdir  => '~/src',
    :github_login  => 'some-username',
    :homebrew_root => '/opt/boxen/homebrew',
  }
end
