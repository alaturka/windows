# frozen_string_literal: true
# rubocop:disable all

Vagrant.configure('2') do |config|
  config.vm.guest = :windows

  config.vm.provider 'virtualbox' do |virtualbox|
    virtualbox.gui = false
  end

  config.trigger.before :all do |trigger|
    trigger.info   = 'Avoid syncing repository'
    trigger.run    = { inline: 'git config --local sync.type never' }
    trigger.ignore = %i[destroy halt]
  end

  # Main box for development
  config.vm.define 'playground', primary: true do |this|
    this.vm.box   = 'windows/playground'

    this.vm.provision 'shell', inline: <<~'PROVISION'
      [Environment]::SetEnvironmentVariable('Path', $Env:Path + ';C:\vagrant\.local\bin;C:\vagrant\.local\tmp', 'User')
    PROVISION

    linux = '../linux'
    abort "Please make sure the #{linux} directory present" unless Dir.exist? linux
    this.vm.synced_folder "#{linux}/", '/linux'
  end

  # Box for testing an installed machine
  config.vm.define 'classroom', autostart: false do |this|
    this.vm.box   = 'windows/classroom'

    this.vm.provision 'shell', inline: <<~'PROVISION'
      [Environment]::SetEnvironmentVariable('Path', 'C:\vagrant\bin;' + $Env:Path, 'User')
    PROVISION
  end
end

# vim: ft=ruby
