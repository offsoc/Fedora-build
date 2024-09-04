# fedora-livecd-lxde.ks
#
# Description:
# - Fedora Live Spin with the light-weight LXDE Desktop Environment
#
# Maintainer(s):
# - Christoph Wickert <cwickert@fedoraproject.org>

%include fedora-live-base.ks
%include fedora-live-minimization.ks
%include fedora-lxde-common.ks

%post
# LXDE and LXDM configuration

# create /etc/sysconfig/desktop (needed for installation)
cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/startlxde
DISPLAYMANAGER=/usr/sbin/lxdm
EOF

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="lxde"/' /etc/sysconfig/livesys

%end

