require 'spec_helper'

describe 'boxen::osx_defaults' do
  let(:title)  { 'example' }
  let(:domain) { 'com.example' }
  let(:key)    { 'testkey' }
  let(:value)  { 'yes' }

  let(:params) {
    { :domain => domain,
      :key    => key,
      :value  => value,
    }
  }

  it do
    should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
      with(:command => "/usr/bin/defaults write #{domain} #{key} #{value}")
  end

  context 'with quoting for shell values' do
    let(:domain) { 'NSGlobalDomain With Space' }
    let(:key)    { 'Key With Spaces' }
    let(:value)  { 'Long String With Spaces' }
    let(:host)   { 'com.example.long/host' }

    let(:default_params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :host   => host
      }
    }
    let(:params) { default_params }

    context 'for writing' do
      it do
        should contain_exec("osx_defaults write #{host} #{domain}:#{key}=>#{value}").
          with(:command => "/usr/bin/defaults -host #{host} write \"#{domain}\" \"#{key}\" \"#{value}\"")
      end
    end

    context 'for deleting' do
      let(:params) { default_params.merge(:ensure => 'delete') }

      it do
        should contain_exec("osx_defaults delete #{host} #{domain}:#{key}").
          with(:command => "/usr/bin/defaults -host #{host} delete \"#{domain}\" \"#{key}\"")
      end
    end
  end

  context 'with a type' do
    let(:value)  { '10' }
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :type   => type,
      }
    }

    context 'specified in full' do
      let(:type) { 'integer' }
      it 'checks the type' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => %Q[/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != "#{value}" }') && (/usr/bin/defaults read-type #{domain} #{key} | awk '/^Type is / { exit $3 != "integer" } { exit 1 }')])
      end
    end

    context 'specified in short form' do
      let(:type)  { 'int' }
      it 'checks the long form of the type' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => %Q[/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != "#{value}" }') && (/usr/bin/defaults read-type #{domain} #{key} | awk '/^Type is / { exit $3 != "integer" } { exit 1 }')])
      end
    end
  end

  context 'without a type' do
    let(:value)  { '10' }
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
      }
    }

    it 'skips checking the type' do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
        with(:unless => %Q[/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != "#{value}" }')])
    end
  end

  context 'with a refreshonly' do
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :refreshonly => true,
      }
    }

    it 'check the refreshonly is true' do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
        with(:refreshonly => true)
    end
  end

  context 'without a refreshonly' do
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
      }
    }

    it 'check the refreshonly is false' do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
        with(:refreshonly => false)
    end
  end

  context 'boolean handling' do
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :type   => 'boolean',
      }
    }
    let(:boolean_typecheck) { %Q[(/usr/bin/defaults read-type #{domain} #{key} | awk '/^Type is / { exit $3 != "boolean" } { exit 1 }')] }

    context 'yes' do
      let(:value) { 'yes' }
      it 'converts yes to 1 for checking' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != \"1\" }') && #{boolean_typecheck}")
      end
    end

    context 'no' do
      let(:value) { 'no' }
      it 'converts no to 0 for checking' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != \"0\" }') && #{boolean_typecheck}")
      end
    end

    context 'true' do
      let(:value) { 'true' }
      it 'converts true to 1 for checking' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != \"1\" }') && #{boolean_typecheck}")
      end
    end

    context 'false' do
      let(:value) { 'false' }
      it 'converts false to 0 for checking' do
        should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").
          with(:unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} | awk '{ exit $0 != \"0\" }') && #{boolean_typecheck}")
      end
    end
  end

  context 'with a boolean value' do
    let(:value) { true }
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value
      }
    }

    it do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value}").with(
        :command => "/usr/bin/defaults write #{domain} #{key} -bool #{value}"
      )
    end
  end

  context 'with a host' do
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :host   => host
      }
    }

    context 'currentHost' do
      let(:host) { 'currentHost' }

      it do
        should contain_exec("osx_defaults write #{host} #{domain}:#{key}=>#{value}").
          with(:command => "/usr/bin/defaults -currentHost write #{domain} #{key} #{value}")
      end
    end

    context 'specific host' do
      let(:host) { 'mybox.example.com' }

      it do
        should contain_exec("osx_defaults write #{host} #{domain}:#{key}=>#{value}").
          with(:command => "/usr/bin/defaults -host #{host} write #{domain} #{key} #{value}")
      end
    end
  end

  context 'with a array value' do
    let(:value) { [ 'val1', 'val2', 'val3' ] }
    let(:value_str) { 'val1 val2 val3' }
    let(:value_check) { '(val1,val2,val3)' }
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :type   => 'array',
      }
    }
    let(:array_typecheck) { %Q[(/usr/bin/defaults read-type #{domain} #{key} | awk '/^Type is / { exit $3 != "array" } { exit 1 }')] }
    let(:convert_cmd) { '| sed -e "s/^ *//g" | tr -d "\"\n"' }

    it do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value_str}").with(
        :command => "/usr/bin/defaults write #{domain} #{key} -array #{value_str}",
        :unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} #{convert_cmd} | awk '{ exit $0 != \"#{value_check}\" }') && #{array_typecheck}")
    end
  end

  context 'with a dict value' do
    let(:value) { { 'key1' => 'val1', 'key2' => 'val2', 'key3' => 'val3' } }
    let(:value_str) { '"key1" "val1" "key2" "val2" "key3" "val3"' }
    let(:value_check) { '{key1=val1;key2=val2;key3=val3;}' }
    let(:params) {
      { :domain => domain,
        :key    => key,
        :value  => value,
        :type   => 'dict',
      }
    }
    let(:dict_typecheck) { %Q[(/usr/bin/defaults read-type #{domain} #{key} | awk '/^Type is / { exit $3 != "dictionary" } { exit 1 }')] }
    let(:convert_cmd) { '| sed -e "s/^ *//g" -e "s/ *= */=/g" | tr -d "\"\n"' }

    it do
      should contain_exec("osx_defaults write  #{domain}:#{key}=>#{value_str}").with(
        :command => "/usr/bin/defaults write #{domain} #{key} -dict #{value_str}",
        :unless => "/usr/bin/defaults read #{domain} #{key} && (/usr/bin/defaults read #{domain} #{key} #{convert_cmd} | awk '{ exit $0 != \"#{value_check}\" }') && #{dict_typecheck}")
    end
  end
end
