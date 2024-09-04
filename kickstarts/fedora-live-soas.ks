# fedora-livecd-soas.ks
#
# Description:
# - A Sugar environment that you can carry in your pocket
#
# Maintainers:
# - Chihurumnaya Ibiam <ibiam AT sugarlabs DOT org>
# - Alex Perez <aperez AT alexperez DOT com>

%include fedora-live-base.ks
%include fedora-live-minimization.ks
%include fedora-soas-common.ks

%post

# Fix https://bugzilla.redhat.com/show_bug.cgi?id=2239137
cat > /etc/xdg/autostart/xfce-polkit.desktop <<EOF
[Desktop Entry]
Type=Application
Name=xfce-polkit
Exec=/usr/libexec/xfce-polkit
EOF

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="soas"/' /etc/sysconfig/livesys

%end
