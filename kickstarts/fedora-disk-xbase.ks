%packages
@base-x
@fonts
@input-methods
@multimedia
@printing
-@guest-desktop-agents
initial-setup-gui

# Need aajohan-comfortaa-fonts for the SVG rnotes images
aajohan-comfortaa-fonts

# anaconda needs the locales available to run for different locales
glibc-all-langpacks

%end

%post
# Explicitly set graphical.target as default as this is how initial-setup detects which version to run
systemctl set-default graphical.target

%end
