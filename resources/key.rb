property :override_default_keyring, [true, false], default: false
property :pubring_file, String
property :secring_file, String
property :user, String, default: 'root'
property :name_real, String, default: lazy { "Chef Generated Default (#{batch_name})" }
property :name_comment, String, default: 'generated by Chef'
property :name_email, String, default: lazy { "#{node.name}@example.com" }
property :expire_date, String, default: '0'
property :batch_name, String, name_property: true
property :batch_config_file, String, default: lazy { ::File.expand_path("~#{user}/.gpg/gpg_batch_config_#{batch_name}") }
property :user_config_file, String, default: lazy { ::File.expand_path("~#{user}/.gpg/gpg.conf") }
property :agent_config_file, String, default: lazy { ::File.expand_path("~#{user}/.gpg/gpg-agent.conf") }
property :key_type, String, default: '1', equal_to: %w(RSA 1 Elgamal 16 DSA 17 20 )
property :key_length, String, default: '2048', equal_to: %w( 2048 4096 )
property :passphrase, String, sensitive: true
property :key_file, String
property :key_fingerprint, String

action :generate do
  unless key_exists(new_resource)

    config_dir = ::File.dirname(new_resource.batch_config_file)
    unless ::Dir.exist?(config_dir)
      directory config_dir do
        owner new_resource.user
        mode '0600'
        recursive true
      end
    end

    file new_resource.batch_config_file do
      content <<-EOS
Key-Type: #{new_resource.key_type}
Key-Length: #{new_resource.key_length}
Name-Real: #{new_resource.name_real}
Name-Comment: #{new_resource.name_comment}
Name-Email: #{new_resource.name_email}
Expire-Date: #{new_resource.expire_date}
EOS
      if new_resource.override_default_keyring
        content << "%pubring #{new_resource.pubring_file}\n"
        content << "%secring #{new_resource.secring_file}\n"
      end

      content << "Passphrase: #{new_resource.passphrase}" if new_resource.passphrase
      content << "%commit\n"

      mode '0600'
      owner new_resource.user
    end

    # The --with-colons option emits the output in a stable, machine-parseable format,
    # which is intended for use by scripts and other programs

    # --no-tty Make  sure that the TTY (terminal) is never used for any output.
    # This option is needed in  some  cases  because  GnuPG  sometimes
    # prints warnings to the TTY even if --batch is used.

    # --full-gen-key is avilable after 2.0 (Centos 7 default)

    file new_resource.agent_config_file do
      user new_resource.user
      content "allow-loopback-pinentry\n"
      mode '0600'
    end

    cmd = "gpg2 "
    cmd << gpg_opts(new_resource) if new_resource.override_default_keyring
    cmd << ' --batch'
    cmd << ' --no-tty'
    cmd << ' --with-colons'
    cmd << " --pinentry-mode 'loopback'"
    cmd << " --status-fd '2'"
    cmd << " --full-generate-key #{new_resource.batch_config_file}"

    execute 'gpg2: generate' do
      command cmd
      live_stream true
      user new_resource.user
    end
  end
end

action :import do
  execute 'gpg2: import key' do
    command "gpg2 --import #{new_resource.key_file}"
    user new_resource.user
    not_if { key_exists(new_resource) }
  end
end

action :export do
  execute 'gpg2: export key' do
    command "gpg2 --export -a \"#{new_resource.name_real}\" > #{new_resource.key_file}"
    user new_resource.user
    not_if { ::File.exist?(new_resource.key_file) }
  end


end

action :delete_public_key do
  execute 'gpg2: delete key' do
    command "gpg2 --batch --yes --delete-key \"#{new_resource.key_fingerprint}\""
    user new_resource.user
    only_if { key_exists(new_resource) }
  end
end

action :delete_secret_keys do
  execute 'gpg2: delete key' do
    command "gpg2 --batch --yes --delete-secret-keys \"#{new_resource.key_fingerprint}\""
    user new_resource.user
    only_if { key_exists(new_resource) }
  end
end

action_class do
  include Gpg::Helpers
end