# Description:
# - Fedora Live Spin with the Budgie Desktop Environment
# 
# Maintainer(s):
# - Joshua Strobl <joshua@buddiesofbudgie.org>

%include fedora-live-base.ks
%include fedora-budgie-common.ks

part / --size 7750

%post

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="budgie"/' /etc/sysconfig/livesys

%end
