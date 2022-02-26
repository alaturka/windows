Development
==========

### Develop and/or play locally with boot and install

If you don't use a Vagrant box, make sure to wait Windows update finished before attempting the installation.

Use the `play` script in default mode.

- Enter Vagrant box

  ```sh
  vagrant box destroy -f # Reset box
  vagrant up
  vagrant ssh
  ```

- Run "W10Man" and enable "Windows Modules Installer" temporarly

- Bootstrap

  ```ps1
  play boot
  ```

- Reboot, run "W10Man" and disable "Windows Modules Installer"

- Install (after bootstrap)

  ```ps1
  play install # Being inside the C:\vagrant shared folder results unexpected errors
  ```

### Test production

Use the `play` script in production mode.  If you don't use a Vagrant box, make sure to wait Windows update finished
before attempting the installation.

- Enter into the default Vagrant box

  ```sh
  vagrant box destroy -f # Reset box
  vagrant up
  vagrant ssh
  ```

- Run "W10Man" and enable "Windows Modules Installer" temporarly

- Bootstrap

  ```ps1
  play -Mode production boot
  ```

- Reboot, run "W10Man" and disable "Windows Modules Installer"

- Install (after bootstrap)

  ```ps1
  play -Mode production install
  ```

### Play with an already deployed classroom 

- Enter into the `classroom` Vagrant box

  ```sh
  vagrant destroy -f classroom
  vagrant up classroom
  vagrant ssh classroom
  ```

- Install

  ```ps1
  cd ~; play install
  ```

  or to play with the actual installation process

  ```ps1
  cd ~; classroom -Verbose install
  ```

### Adding Vagrant boxes for development

There are boxes each using a different box:

- `playground`: This is the default box to simulate the conditions for a fresh installation:

  ```sh
  vagrant box add windows/playground windows-playground_virtualbox.box # only first time
  vagrant up # or vagrant up playground for explicity
  vagrant ssh
  ```

- `classroom`: This one simulates the conditions for a machine which has classroom installed:

  ```sh
  vagrant box add windows/classroom windows-classroom_virtualbox.box # only first time
  vagrant up classroom
  vagrant ssh clasroom
  ```

### Update sources

Make sure that https://github.com/alaturka/ellipses has been installed:

```sh
gem install ellipses
```

After modifications:

```sh
src update
```

### Taking SVG screenshots


- Install termtosvg on Linux side

  ```sh
  pip install termtosvg
  ```

- Record

  ```sh
  unset TMUX; termtosvg -s tmux /mnt/c/Users/vagrant/screenshot
  ```

- Move screenshots to the host machine

  ```
  robocopy $Env:HOME\\screenshot screenshot
  ```

- Select the most appropriate SVG file

- Edit selected SVG to add paddings around the image
