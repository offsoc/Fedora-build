# This is a basic Fedora cloud spin designed to work in OpenStack and other
# private cloud environments. It's configured with cloud-init so it will
# take advantage of ec2-compatible metadata services for provisioning ssh
# keys. Cloud-init creates a user account named "fedora" with passwordless
# sudo access. The root password is empty and locked by default.
#
# This kickstart file is designed to be used with ImageFactory (in Koji).
#
# To do a local build, you'll need to install ImageFactory.  See
# http://worknotes.readthedocs.org/en/latest/cloudimages.html for some notes.
#
# For a TDL file, I store one here:
# https://pagure.io/fedora-atomic/raw/master/f/fedora-atomic-rawhide.tdl
# (Koji generates one internally...what we really want is Koji to publish it statically)
#
# Once you have imagefactory and imagefactory-plugins installed, run:
#
#   curl -O https://pagure.io/fedora-atomic/raw/master/f/fedora-atomic-rawhide.tdl
#   tempfile=$(mktemp --suffix=.ks)
#   ksflatten -v F22 -c fedora-cloud-base.ks > ${tempfile}
#   imagefactory --debug base_image --file-parameter install_script ${tempfile} fedora-atomic-rawhide.tdl
#

text # don't use cmdline -- https://github.com/rhinstaller/anaconda/issues/931
lang en_US.UTF-8
keyboard us
timezone --utc Etc/UTC

selinux --enforcing
rootpw --lock --iscrypted locked

firewall --disabled

# We pass net.ifnames=0 because we always want to use eth0 here on all the cloud images.
bootloader --timeout=1 --location=mbr --append="no_timer_check net.ifnames=0 console=tty1 console=ttyS0,115200n8"

services --enabled=sshd,cloud-init,cloud-init-local,cloud-config,cloud-final

# Configure for gpt with bios+uefi
clearpart --all --initlabel --disklabel=gpt
part prepboot  --size=4    --fstype=prepboot
part biosboot  --size=1    --fstype=biosboot
part /boot/efi --size=100  --fstype=efi
part /boot     --size=1000  --fstype=ext4 --label=boot
part btrfs.007 --size=2000 --fstype=btrfs --grow
btrfs none --label=fedora btrfs.007
btrfs /home --subvol --name=home LABEL=fedora
btrfs /     --subvol --name=root LABEL=fedora

%include fedora-repo.ks

reboot

##### begin package list #############################################
%packages --instLangs=en

# Include packages for the cloud-server-environment group
@^cloud-server-environment

# Install the tracer dnf plugin to enable automatic reboots
# IF the user requests package updates
# AND requests a reboot
# AND the packages updated require a reboot.
# https://fedoraproject.org/wiki/Changes/Automatic_Cloud_Reboot_On_Updates
python3-dnf-plugin-tracer

# Don't include the kernel toplevel package since it pulls in
# kernel-modules. We're happy for now with kernel-core.
-kernel
kernel-core

# Don't include dracut-config-rescue. It will have dracut generate a
# "rescue" entry in the grub menu, but that also means there is a
# rescue kernel and initramfs that get created, which (currently) add
# about another 40MiB to the /boot/ partition. Also the "rescue" mode
# is generally not useful in the cloud.
-dracut-config-rescue

# Plymouth provides a graphical boot animation. In the cloud we don't
# need a graphical boot animation. This also means anaconda won't put
# rhgb/quiet on kernel command line
-plymouth

# Install qemu-guest-agent https://pagure.io/cloud-sig/issue/319 To
# improve the integration with OpenStack and other VM management
# systems (oVirt, KubeVirt).
qemu-guest-agent


# No need for firewalld for now. We don't have a firewall on by default.
-firewalld

# Don't include the geolite2 databases, which end up with 66MiB
# in /usr/share/GeoIP
-geolite2-country
-geolite2-city
%end
##### end package list ###############################################


##### begin kickstart post ###########################################
%post --erroronfail

if [ "$(arch)" = "x86_64" ]; then
# Set up legacy BIOS boot if we booted from UEFI
grub2-install --target=i386-pc /dev/vda
fi

# Blivet sets pmbr_boot flag erroneously and we need to purge it
# otherwise it'll fail to boot
parted /dev/vda disk_set pmbr_boot off

# linux-firmware is installed by default and is quite large. As of mid 2020:
#   Total download size: 97 M
#   Installed size: 268 M
# So far we've been fine shipping without it so let's continue.
# More discussion about this in #1234504.
echo "Removing linux-firmware package."
rpm -e linux-firmware

# See the systemd-random-seed.service man page that says:
#   " It is recommended to remove the random seed from OS images intended
#     for replication on multiple systems"
echo "Removing random-seed so it's not the same in every image."
rm -f /var/lib/systemd/random-seed

echo "Import RPM GPG key"
releasever=$(rpm --eval '%{fedora}')
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch

echo "Zeroing out empty space."
# Create zeros file with nodatacow and no compression
touch /var/tmp/zeros
chattr +C /var/tmp/zeros
# This forces the filesystem to reclaim space from deleted files
dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
echo "(Don't worry -- that out-of-space error was expected.)"
# Force sync to disk (Cf. https://pagure.io/cloud-sig/issue/340#comment-743430)
btrfs filesystem sync /
rm -f /var/tmp/zeros
btrfs filesystem sync /

# When we build the image a networking config file gets left behind.
# Let's clean it up.
echo "Cleanup leftover networking configuration"
rm -f /etc/NetworkManager/system-connections/*.nmconnection

# Truncate the /etc/resolv.conf left over from NetworkManager during the
# kickstart. This causes delays in boot with cloud-init because the
# 192.168.122.1 DNS server cannot be reached.
truncate -s 0 /etc/resolv.conf

# Clear machine-id on pre generated images
truncate -s 0 /etc/machine-id

%end
##### end kickstart post ############################################
