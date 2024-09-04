%packages
microdnf
-@standard
-initial-setup-gui
-generic-release*
-glibc-all-langpacks
# recommended by iproute, we don't want it in minimal
-iproute-tc
# recommended by gnutls, we don't want it in minimal
-trousers
glibc-langpack-en
iw
NetworkManager-wifi
%end

%post

# setup systemd to boot to the right runlevel
echo -n "Setting default runlevel to multiuser text mode"
systemctl set-default multi-user.target
echo .

%end
