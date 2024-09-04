%include fedora-disk-base.ks

services --enabled=sshd,NetworkManager,chronyd,initial-setup

autopart --noswap

%packages
fedora-release-server
# install the default groups for the server environment since installing the environment is not working
@server-product
@standard
@core
@headless-management
@hardware-support
@networkmanager-submodules

@container-management
@domain-client
@guest-agents
@server-hardware-support
-initial-setup-gui
-generic-release*
%end

%post

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
systemctl set-default multi-user.target
echo .

%end

