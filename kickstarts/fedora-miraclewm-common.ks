# fedora-livecd-miraclewm.ks
#
# Description:
# - Fedora Live Spin with the tiling window manager Miracle
#
# Maintainer(s):
# - Matthew Kosarek <mattkae@fedoraproject.org>
# - Neal Gompa      <ngompa@fedoraproject.org>

%packages
fedora-release-miraclewm
@^miraclewm-desktop-environment
@firefox
initial-setup-gui-wayland-miraclewm
%end
