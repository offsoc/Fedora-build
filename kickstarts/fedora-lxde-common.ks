# fedora-livecd-lxde.ks
#
# Description:
# - Fedora Live Spin with the light-weight LXDE Desktop Environment
#
# Maintainer(s):
# - Christoph Wickert <cwickert@fedoraproject.org>

%packages
### LXDE desktop
# install env-group to resolve RhBug:1891500
@^lxde-desktop-environment

@lxde-apps
@lxde-media
@lxde-office

# pam-fprint causes a segfault in LXDM when enabled
-fprintd-pam


# LXDE has lxpolkit. Make sure no other authentication agents end up in the spin.
-polkit-gnome
-polkit-kde

# make sure xfce4-notifyd is not pulled in
notification-daemon
-xfce4-notifyd

# make sure xfwm4 is not pulled in for firstboot
# https://bugzilla.redhat.com/show_bug.cgi?id=643416
metacity


# dictionaries are big
#-man-pages-*
#-words

# save some space
-@admin-tools
-autofs
-acpid
-gimp-help
-desktop-backgrounds-basic
-PackageKit*                # we switched to dnfdragora, so we don't need this
-foomatic-db-ppds
-foomatic
-stix-fonts
-default-fonts-core-math
-ibus-typing-booster
-xscreensaver-extras
#-wqy-zenhei-fonts           # FIXME: Workaround to save space, do this in comps

# drop some system-config things
#-system-config-language
-system-config-network
-system-config-rootpassword
#-system-config-services
-policycoreutils-gui
-gnome-disk-utility

%end

