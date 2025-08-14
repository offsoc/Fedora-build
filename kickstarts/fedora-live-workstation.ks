# Maintained by the Fedora Workstation WG:
# http://fedoraproject.org/wiki/Workstation
# mailto:desktop@lists.fedoraproject.org

%include fedora-live-base.ks
%include fedora-workstation-common.ks
#
# Disable this for now as packagekit is causing compose failures
# by leaving a gpg-agent around holding /dev/null open.
#
#include snippets/packagekit-cached-metadata.ks

part / --size 8576

%packages
gnome-initial-setup
anaconda-webui
gnome-shell-extension-launch-new-instance
gnome-shell-extension-appindicator                  
gnome-shell-extension-apps-menu                              
gnome-shell-extension-netspeed
gnome-shell-extension-pidgin                   
gnome-shell-extension-caffeine                      
gnome-shell-extension-dash-to-dock                                
gnome-shell-extension-screenshot-window-sizer                   
gnome-shell-extension-status-icons                        
gnome-shell-extension-system-monitor                
gnome-shell-extension-frippery-panel-favorites      
gnome-shell-extension-vertical-workspaces                                           
gnome-shell-extension-workspace-indicator
gnome-shell-extension-gsconnect
-libreoffice*
-unoconv
-gnome-boxes
-gnome-clocks 
-gnome-maps 
-gnome-weather 
-gnome-contacts 
-gnome-characters 
-rhythmbox
%end

%post

# set livesys session type
sed -i 's/^livesys_session=.*/livesys_session="gnome"/' /etc/sysconfig/livesys

%end
