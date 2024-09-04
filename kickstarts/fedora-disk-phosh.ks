%include fedora-disk-base.ks
%include fedora-disk-xbase.ks
%include fedora-phosh-common.ks

autopart --type=btrfs --noswap
