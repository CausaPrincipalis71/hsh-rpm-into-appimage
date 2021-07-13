#!/bin/bash

# Print help message
function help()
{
    echo -e '\n\t--package [package.rpm] \t specify the package to repackage'
    echo -e '\t--plugin [plugin]\t\t specify the plugin to use\n\t\t\t\t\t\t available plugins - qt (conda, python, gtk, ncurses, gstreamer) - WIP'
    echo -e '\t--apt-config [file] \t\t specify the apt configuration file for hasher'
    echo -e '\t--path [/path/to/hasher] \t specify path for hasher'
    echo -e '\t--help \t\t\t\t show this message'
}

# Checking if the plugin is correct
function plugin_is_correct()
{
    if [[ $# -eq 1 ]]
    then 
        for plugin in qt conda python gtk ncurses gstreamer
        do 
            if [[ "$1" = "$plugin" ]]
                then echo 1; exit;
            fi
        done
        echo 0; exit;
    else echo 0; exit;
    fi
}

# Declaration of parameters
PACKAGE=""                      
PLUGINS=""
PLUGINS_COUNT=0                   
APT_CONFIG="/etc/apt/apt.conf"
PATH_TO_HASHER="/home/$USER/hasher"

# Close programm without arguments
if [[ $# -eq 0 ]]
then
    echo "There is no parameters"
    help
    exit 1
fi

# Enumerating options
while [ \"$1\" != \"\" ]
do
case "$1" in 
 --package) if [ -n "$2" ]
                then PACKAGE="$2";

                else echo -e "\tPlease, specify the package"; exit 1;
            fi;
            shift;shift;;

 --plugin)  if [ -n "$2" ] && [[ $(plugin_is_correct "$2") = "1" ]]
                then PLUGINS[PLUGINS_COUNT]="$2";
                     PLUGINS_COUNT=$(($PLUGINS_COUNT + 1));

                else echo -e "\tPlease, specify the plugin. $2 is not correct plugin";exit 1;
            fi;            
            shift;shift;;

 --apt-config)  if [ -n "$2" ]
                    then APT_CONFIG="$2";

                    else echo -e "\tPlease, specify the apt config"; exit 1;
                fi;
                shift;shift;;

 --path)    if [ -n "$2" ]
                then PATH_TO_HASHER="$2";

                else echo -e "\tPlease, specify the path to hasher"; exit 1;
            fi;
            shift;shift;;

 --help) help;exit;;

 *) echo -e "$1 is not an option"; exit 1;;
esac
done

# Adding plugins with argument, like --plugin qt
plugins_with_arguments=""
for plugin in ${PLUGINS[*]}
    do plugins_with_arguments+=" --plugin "
       plugins_with_arguments+="${plugin}"
done

# Checking if package exist
if [ \"$PACKAGE\" = \"\" ]
then echo -e "\tPlease, specify the package"; exit 1;
fi

# Checks if the directory exists, if not, then tries to create it
if [ ! -d "$PATH_TO_HASHER" ]
    then mkdir -p "$PATH_TO_HASHER"
    if [[ $? -ne 0 ]]
        then echo -e "\tPath to hasher doesn\`t exist, please create it manually";exit 1;
    fi
fi

# Initialize hasher
hsh --apt-config $APT_CONFIG --initroot-only $PATH_TO_HASHER 

grep -q -e "/proc" "/etc/hasher-priv/system"

if [[ $? -ne 0 ]]
    then echo -e "\tPlease, add allowed_mountpoints=/proc in /etc/hasher-priv/system"; exit 1;
fi

# Searching for nameservers in hasher-chroot
grep -q -e "nameserver" "$PATH_TO_HASHER/chroot/etc/resolv.conf"

# If there are no nameservers, then add 8.8.8.8
if [[ $? -ne 0 ]]
    then hsh-run --rooter $PATH_TO_HASHER -- sh -c "echo nameserver 8.8.8.8 > /etc/resolv.conf"
fi

hsh-install $PATH_TO_HASHER wget $PACKAGE 

# End script, if hsh cannot install package
if [[ $? -ne 0 ]]
    then echo -e "\tPackage doesn\`t exist, please, check it out"; exit 1;
fi

# Installing linuxdeploy
share_network=yes hsh-run --mountpoints=/proc $PATH_TO_HASHER -- bash -c "cd /usr/src/tmp/ && wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && chmod +x ./linuxdeploy-x86_64.AppImage && ./linuxdeploy-x86_64.AppImage --appimage-extract && mv ./squashfs-root ./linuxdeploy"

# Make an AppDir
hsh-run $PATH_TO_HASHER -- bash -c "mkdir /usr/src/tmp/AppDir && mkdir /usr/src/tmp/AppDir/usr && mkdir /usr/src/tmp/AppDir/usr/bin && mkdir /usr/src/tmp/AppDir/usr/share/ && mkdir /usr/src/tmp/AppDir/usr/share/icons && mkdir /usr/src/tmp/AppDir/usr/share/applications"

# Adding stuff in AppDir
hsh-run $PATH_TO_HASHER -- bash -c "cp /usr/bin/$PACKAGE /usr/src/tmp/AppDir/usr/bin/ && cp /usr/share/applications/$PACKAGE.desktop /usr/src/tmp/AppDir/usr/share/applications/ && cp /usr/share/icons/hicolor/64x64/apps/$PACKAGE.png /usr/src/tmp/AppDir/usr/share/icons/"

# adding plugins in linuxdeploy
for plugin in ${PLUGINS[*]}
    do
    if [[ "$plugin" = "qt" ]] 
        # Downloading qt plugin and adding it in linuxdeploy 
        then hsh-install $PATH_TO_HASHER qt5-base-devel
        share_network=1 hsh-run --mountpoints=/proc $PATH_TO_HASHER -- bash -c "cd /usr/src/tmp/linuxdeploy/plugins && wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage && chmod +x ./linuxdeploy-plugin-qt-x86_64.AppImage && ./linuxdeploy-plugin-qt-x86_64.AppImage --appimage-extract && mv ./squashfs-root ./linuxdeploy-plugin-qt"
        hsh-run $PATH_TO_HASHER -- bash -c "ln -s /usr/src/tmp/linuxdeploy/plugins/linuxdeploy-plugin-qt/AppRun /usr/src/tmp/linuxdeploy/usr/bin/linuxdeploy-plugin-qt"
    fi
done

hsh-run --mountpoints=/proc $PATH_TO_HASHER -- bash -c "cd /usr/src/tmp && /usr/src/tmp/linuxdeploy/AppRun --appdir /usr/src/tmp/AppDir --executable /usr/src/tmp/AppDir/usr/bin/$PACKAGE --desktop-file /usr/src/tmp/AppDir/usr/share/applications/$PACKAGE.desktop --icon-file /usr/src/tmp/AppDir/usr/share/icons/$PACKAGE.png $plugins_with_arguments --output appimage"

echo -e "Done, you can find your appimage in $PATH_TO_HASHER/chroot/usr/src/tmp"