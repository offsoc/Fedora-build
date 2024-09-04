# Filename:
#   fedora-livecd-security.ks
# Description:
#   A fully functional live OS based on Fedora for use in security auditing, 
#   forensics research, and penetration testing.
# Maintainers:
#   Fabian Affolter <fab [AT] fedoraproject <dot> org>
#   Joerg Simon <jsimon [AT] fedoraproject <dot> org>
#   JT Pennington <jt [AT] fedoraproject <dot> org>
# Acknowledgements:
#   Fedora LiveCD Xfce Spin team - some work here was and will be inherited,
#   many thanks, especially to Christoph Wickert!
#   Fedora LXDE Spin - Copied over stuff to make LXDE Default
#   Luke Macken and Adam Miller for the original OpenBox Security ks and all
#   the Security Applications! 
#   Hiemanshu Sharma <hiemanshu [AT] fedoraproject <dot> org>

%include fedora-live-base.ks
%include fedora-live-minimization.ks

# spin was failing to compose due to lack of space, so bumping the size.
part / --size 10240

%packages
# install env-group to resolve RhBug:1891500
@^xfce-desktop-environment

@xfce-apps

# Security tools
@security-lab
security-menus

# unlock default keyring. FIXME: Should probably be done in comps
gnome-keyring-pam

# save some space
-autofs
-acpid
-gimp-help
-desktop-backgrounds-basic
-PackageKit*                # we switched to dnfdragora, so we don't need this
-aspell-*                   # dictionaries are big
-gnumeric
-foomatic-db-ppds
-foomatic
-stix-fonts
-default-fonts-core-math
-ibus-typing-booster
-xfce4-sensors-plugin
-man-pages-*

# drop some system-config things
-system-config-rootpassword
-policycoreutils-gui

# exclude some packages to save some space
# use './fsl-maintenance.py -l' in your security spin git folder to build
-ArpON
-aide
-binwalk
-bkhive
-bonesi
-bro
-cmospwd
-dnstop
-etherape
-hfsutils
-httpie
-httrack
-hydra
-kismon
-labrea
-nebula
-netsed
-onesixtyone
-packETH
-pads
-pdfcrack
-proxychains
-pyrit
-raddump
-rkhunter
-safecopy
-samdump2
-scalpel
-sslstrip
-tcpreen
-tcpreplay
-tripwire
-wipe
-zmap

%end

%post
# xfce configuration

# create /etc/sysconfig/desktop (needed for installation)

cat > /etc/sysconfig/desktop <<EOF
PREFERRED=/usr/bin/startxfce4
DISPLAYMANAGER=/usr/sbin/lightdm
EOF

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="xfce"/' /etc/sysconfig/livesys

%end
