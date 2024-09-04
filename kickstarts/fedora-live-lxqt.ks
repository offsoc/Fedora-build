# fedora-live-lxqt.ks
#
# Description:
# – Fedora Live Spin with the LXQt desktop environment
#
# Maintainer(s):
# – Christian Dersch <lupinix@fedoraproject.org>
#

%include fedora-live-base.ks
%include fedora-live-minimization.ks
%include fedora-lxqt-common.ks

# need a bigger /
part / --size 6000

%packages
dracut-config-generic
%end

%post
# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="lxqt"/' /etc/sysconfig/livesys

%end

