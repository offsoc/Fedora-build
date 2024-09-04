%packages
fedora-release-budgie

# Exclude unwanted groups that fedora-live-base.ks pulls in
-@dial-up
-@input-methods
-@standard

# Install budgie environment
@^budgie-desktop-environment

# recommended apps
@budgie-desktop-apps
@libreoffice
libreoffice-draw
libreoffice-math
thunderbird

# Exclude unwanted packages from @anaconda-tools group
-gfs2-utils
-reiserfs-utils

%end
