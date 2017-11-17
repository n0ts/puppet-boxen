# Public: Set a system config option with the OS X defaults system

define boxen::osx_defaults(
  $ensure      = 'present',
  $host        = undef,
  $domain      = undef,
  $key         = undef,
  $value       = undef,
  $user        = undef,
  $type        = undef,
  $refreshonly = undef,
) {
  $defaults_cmd  = '/usr/bin/defaults'
  $default_cmds  = $host ? {
    'currentHost' => [ $defaults_cmd, '-currentHost' ],
    undef         => [ $defaults_cmd ],
    default       => [ $defaults_cmd, '-host', $host ]
  }

  case $ensure {
    present: {
      if ($domain == undef) or ($key == undef) or ($value == undef) {
        fail('Cannot ensure present without domain, key, and value attributes')
      }

      if (($type == undef) and (($value == true) or ($value == false))) or ($type == 'bool') {
        $type_ = 'bool'
        $value_ = $value

        $checkvalue = $value ? {
          true         => '1',
          /(true|yes)/ => '1',
          default      => '0',
        }
      } else {
        $type_      = $type
        $value_     = $type_ ? {
          /^array$/ => shellquote($value),
          /^dict$/  => inline_template('<%=
            @value.flatten.map{|v| "\"#{v.to_s.shellescape}\"" }.join(" ")
            %>'),
          default   => $value,
        }

        $checkvalue = $type_ ? {
          /^array$/ => inline_template('(<%= @value.join(",") %>)'),
          /^dict$/  => inline_template('{<%=
            @value.map{|k, v|
              if v.is_a?(Hash)
                "#{k}={" + v.map{|kk, vv| "#{kk}=#{vv};" }.join("") + "}"
              else
                "#{k}=#{v};"
              end
            }.join("") %>}'),
          default   => $value,
        }
      }

      $write_cmd_ = $type_ ? {
        /^(array|dict)$/ => shellquote($default_cmds, 'write', $domain, $key, "-${type_}"),
        undef     => shellquote($default_cmds, 'write', $domain, $key, strip("${value} ")),
        default   => shellquote($default_cmds, 'write', $domain, $key, "-${type_}", strip("${value} "))
      }
      $write_cmd =  $type_ ? {
        /^(array|dict)$/ => "${write_cmd_} ${value_}",
        default          => $write_cmd_,
      }

      $read_cmd = shellquote($default_cmds, 'read', $domain, $key)

      $readtype_cmd = shellquote($default_cmds, 'read-type', $domain, $key)
      $checktype = $type_ ? {
        /^bool$/ => 'boolean',
        /^int$/  => 'integer',
        /^dict$/ => 'dictionary',
        default  => $type_,
      }
      $checktype_cmd = $type_ ? {
        undef   => '',
        default => " && (${readtype_cmd} | awk '/^Type is / { exit \$3 != \"${checktype}\" } { exit 1 }')"
      }

      $convert_cmd = $type_ ? {
        /^array$/ => ' | sed -e "s/^ *//g" | tr -d "\"\n"',
        /^dict$/  => ' | sed -e "s/^ *//g" -e "s/ *= */=/g" | tr -d "\"\n"',
        default   => undef,
      }

      $refreshonly_ = $refreshonly ? {
        undef   => false,
        default => true,
      }

      exec { "osx_defaults write ${host} ${domain}:${key}=>${value_}":
        command     => $write_cmd,
        unless      => "${read_cmd} && (${read_cmd}${convert_cmd} | awk '{ exit \$0 != \"${checkvalue}\" }')${checktype_cmd}",
        user        => $user,
        refreshonly => $refreshonly_,
      }
    } # end present

    default: {
      $list_cmd   = shellquote($default_cmds, 'read', $domain)
      $key_search = shellquote('grep', $key)

      exec { "osx_defaults delete ${host} ${domain}:${key}":
        command => shellquote($default_cmds, 'delete', $domain, $key),
        onlyif  => "${list_cmd} | ${key_search}",
        user    => $user,
      }
    } # end default
  }
}
