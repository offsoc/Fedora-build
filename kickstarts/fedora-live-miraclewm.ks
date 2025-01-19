# fedora-livecd-miraclewm.ks
#
# Description:
# - Fedora Live Spin with the tiling window manager Miracle
#
# Maintainer(s):
# - Matthew Kosarek <mattkae@fedoraproject.org>
# - Neal Gompa      <ngompa@fedoraproject.org>

%include fedora-live-base.ks
%include fedora-live-minimization.ks
%include fedora-miraclewm-common.ks

%packages
# To be able to show installation instructions on background
nwg-wrapper
%end

%post
# create /etc/sysconfig/desktop (needed for installation)
cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/miraclewm
DISPLAYMANAGER=/bin/sddm
EOF

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="miraclewm"/' /etc/sysconfig/livesys

%end

