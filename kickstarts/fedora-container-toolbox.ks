# Kickstart file for Fedora Toolbox

# See fedora-container-common.ks for details on how to hack on container image kickstarts

text # don't use cmdline -- https://github.com/rhinstaller/anaconda/issues/931
bootloader --disabled
timezone --isUtc Etc/UTC
timesource --ntp-disable
rootpw --lock --iscrypted locked
keyboard us
network --bootproto=dhcp --device=link --activate --onboot=on
reboot

# boot partitions are irrelevant as the final docker image is a tarball
zerombr
clearpart --all
autopart --noboot --nohome --noswap --nolvm

# Install packages
%packages --nocore
acl
bash
bash-completion
bc
bzip2
coreutils
coreutils-common
curl
default-editor
diffutils
dnf
dnf-yum  # https://fedorahosted.org/fesco/ticket/1312#comment:29
dnf-plugins-core
-dosfstools
-e2fsprogs
fedora-release-toolbx
findutils
flatpak-spawn
fpaste
-fuse-libs
gawk
git
-glibc-minimal-langpack
glibc-all-langpacks
gnupg2
gnupg2-smime
grep
-grubby
gvfs-client
gzip
hostname
iproute
iputils
-kernel
keyutils
krb5-libs
less
libcap
-libss
lsof
man-db
man-pages
mesa-dri-drivers
mesa-vulkan-drivers
mtr
nss-mdns
openssh-clients
openssl
p11-kit
pam
passwd
pigz
-pinentry
procps-ng
psmisc
python3
rootfiles
rpm
rsync
sed
shadow-utils
-shared-mime-info
-sssd-client
sudo
# This is a weak dependency of systemd, we do not want
# this in the container; see
#  https://github.com/containers/toolbox/issues/1410
-systemd-resolved
tar # https://bugzilla.redhat.com/show_bug.cgi?id=1409920
tcpdump
time
traceroute
tree
-trousers
tzdata
unzip
util-linux
util-linux-core
vim-minimal
vte-profile
vulkan-loader
wget2-wget
which
whois
words
-xkeyboard-config
xorg-x11-xauth
xz
zip
%end

# Pre-installation commands
%pre
# Copy README.md
cp /README.md /mnt/sysimage/README.md

# Remove macros.image-language-conf file
rm -f /mnt/sysimage/etc/rpm/macros.image-language-conf

# Remove 'tsflags=nodocs' line from dnf.conf
sed -i '/tsflags=nodocs/d' /mnt/sysimage/etc/dnf/dnf.conf
%end

%post --erroronfail --log=/root/anaconda-post.log
set -eux

# https://bugzilla.redhat.com/show_bug.cgi?id=1727489
echo 'LANG="C.UTF-8"' >  /etc/locale.conf

# https://bugzilla.redhat.com/show_bug.cgi?id=1400682
echo "Import RPM GPG key"
releasever=$(rpm --eval '%{?fedora}')

# When building ELN containers, we don't have the %{fedora} macro
if [ -z $releasever ]; then
  releasever=eln
fi

rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-primary

echo "# fstab intentionally empty for containers" > /etc/fstab

# Remove machine-id on pre generated images
rm -f /etc/machine-id
touch /etc/machine-id

echo "# resolv placeholder" > /etc/resolv.conf
chmod 644 /etc/resolv.conf

# https://bugzilla.redhat.com/show_bug.cgi?id=1343138
# Fix /run/lock breakage since it's not tmpfs in docker
# This unmounts /run (tmpfs) and then recreates the files
# in the /run directory on the root filesystem of the container
#
# We ignore the return code of the systemd-tmpfiles command because
# at this point we have already removed the /etc/machine-id and all
# tmpfiles lines with %m in them will fail and cause a bad return
# code. Example failure:
#   [/usr/lib/tmpfiles.d/systemd.conf:26] Failed to replace specifiers: /run/log/journal/%m
#
umount /run
rm -f /run/nologin # https://pagure.io/atomic-wg/issue/316

# Final pruning
rm -rfv /var/cache/* /var/log/* /tmp/*

# Check if specified files exist
declare -a files=(
 # bash
 "/usr/share/man/man1/bash.1*"
 "/usr/share/man/man1/cd.1*"
 "/usr/share/man/man1/export.1*"
 # coreutils-common
 "/usr/share/man/man1/cat.1*"
 "/usr/share/man/man1/cp.1*"
 "/usr/share/man/man1/ls.1*"
 # gnupg2
 "/usr/share/man/man1/gpg2.1*"
 "/usr/share/man/man7/gnupg2.7*"
 # psmisc
 "/usr/share/man/fr/man1/pstree.1*"
 "/usr/share/man/ko/man1/pstree.1*"
 "/usr/share/man/man1/pstree.1*"
 # rpm
 "/usr/share/man/man8/rpm.8*"
 "/usr/share/man/man8/rpm2cpio.8*"
 # shadow-utils
 "/usr/share/man/fr/man8/useradd.8*"
 "/usr/share/man/ja/man8/useradd.8*"
 "/usr/share/man/man8/useradd.8*"
 # util-linux
 "/usr/share/man/man1/cal.1.*"
 "/usr/share/man/man1/getopt.1*"
 "/usr/share/man/man1/hexdump.1*"
 # util-linux-core
 "/usr/share/man/man1/kill.1*"
 "/usr/share/man/man8/mount.8*"
 # xz
 "/usr/share/man/fr/man1/xz.1*"
 "/usr/share/man/ko/man1/xz.1*"
 "/usr/share/man/man1/xz.1*"
)

ret_val=0
for file in "${files[@]}"; do
 if ! compgen -G "$file" >/dev/null; then
   echo "$file: No such file or directory" >&2
   ret_val=1
   break
 fi
done

if [ "$ret_val" -ne 0 ]; then
 false
fi
%end

# Perform any necessary post-installation configurations specific to Fedora Toolbox (nochroot environment)
# Post-installation commands

%post --nochroot --erroronfail --log=/mnt/sysimage/root/anaconda-post-nochroot.log
set -eux

# Clean up dnf cache
dnf clean all

%end
