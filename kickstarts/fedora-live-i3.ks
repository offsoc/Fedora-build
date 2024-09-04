# fedora-livecd-i3.ks
#
# Description:
# - Fedora Live Spin with the tiling window manager i3
#
# Maintainer(s):
# - Nasir Hussain    <nasirhm@fedoraproject.org>
# - Eduard Lucena    <x3mboy@fedoraproject.org>
# - Dan Cermak       <defolos@tummy.com>
# - Justin W. Flory  <jwf@fedoraproject.org>

%include fedora-live-base.ks
%include fedora-live-minimization.ks
%include fedora-i3-common.ks

# need a bigger /
part / --size 6000

%post
# i3 configuration

# create /etc/sysconfig/desktop (needed for installation)

cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/i3
DISPLAYMANAGER=/usr/sbin/lightdm
EOF


# Fix https://bugzilla.redhat.com/show_bug.cgi?id=2240823
cat > /etc/xdg/autostart/xfce-polkit.desktop <<EOF
[Desktop Entry]
Type=Application
Name=xfce-polkit
Exec=/usr/libexec/xfce-polkit
EOF

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="i3"/' /etc/sysconfig/livesys

%end

