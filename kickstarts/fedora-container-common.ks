# This is the common bits between Fedora Container base image.
#
# To keep this image minimal it only installs English language. You need to change
# dnf configuration in order to enable other languages.
#
# ##  Hacking on this image ###
# This kickstart is processed using Anaconda-in-ImageFactory (via Koji typically),
# but you can run imagefactory locally too.
#
# To do so, testing local changes, first you'll need a TDL file.  I store one here:
# https://pagure.io/fedora-atomic/raw/master/f/fedora-atomic-rawhide.tdl
#
# Then, once you have imagefactory and imagefactory-plugins installed, run:
#
#   ksflatten -c fedora-container-base[-minimal].ks -o fedora-container-base-test.ks
#   imagefactory --debug target_image --template /path/to/fedora-atomic-rawhide.tdl --parameter offline_icicle true --file-parameter install_script $(pwd)/fedora-container-base-test.ks docker
#

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

%packages --excludedocs --instLangs=en --nocore --excludeWeakdeps
fedora-release-container
bash
coreutils
glibc-minimal-langpack
tzdata
rpm
util-linux-core
-kernel
-dosfstools
-e2fsprogs
-fuse-libs
-gnupg2-smime
-libss # used by e2fsprogs
-pinentry
-shared-mime-info
-trousers
-xkeyboard-config
-grubby
-langpacks-en_GB
# https://bugzilla.redhat.com/show_bug.cgi?id=1951111
-util-linux
-sssd-client

%end

%post --erroronfail --log=/root/anaconda-post.log
set -eux

# Set install langs macro so that new rpms that get installed will
# only install langs that we limit it to.
LANG="en_US"
echo "%_install_langs $LANG" > /etc/rpm/macros.image-language-conf

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
%end
