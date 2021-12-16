# frozen_string_literal: true

Vagrant.configure('2') do |config|
  config.vm.box = 'windows/playground' # See .local/doc/development.md

  config.vm.provider 'virtualbox' do |virtualbox|
    virtualbox.gui = false

    virtualbox.customize ['modifyvm', :id, '--nested-hw-virt', 'on']
  end

  config.trigger.before :all do |trigger|
    trigger.info   = 'Avoid renews'
    trigger.run    = { inline: 'touch .git/NORENEW' }
    trigger.ignore = %i[destroy halt]
  end
end

# vim: ft=ruby
