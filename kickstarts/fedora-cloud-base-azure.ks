# This is a basic Fedora cloud spin designed to work with Azure.

# Inherit from cloud base
%include fedora-cloud-base.ks

%packages
# Fedora Cloud Base includes the qemu guest agent and it is not
# required for Azure: https://pagure.io/cloud-sig/issue/319
-qemu-guest-agent
WALinuxAgent
%end

%post --erroronfail
cat > /etc/ssh/sshd_config.d/50-client-alive-interval.conf << EOF
ClientAliveInterval 120
EOF

cat >> /etc/chrony.conf << EOF

# Azure's virtual time source:
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/time-sync#check-for-ptp-clock-source
refclock PHC /dev/ptp_hyperv poll 3 dpoll -2 offset 0
EOF
%end
