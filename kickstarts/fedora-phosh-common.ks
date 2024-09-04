# fedora-phosh-common.ks
#
# Description:
# - Fedora Disk image Spin with the phosh window manager
#
# Maintainer(s):
# - Kevin Fenzi       <kevin@scrye.com>

%packages
# install env-group to resolve RhBug:1891500
@^phosh-desktop-environment

%end
