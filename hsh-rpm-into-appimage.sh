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

hsh-install $PATH_TO_HASHER wget $PACKAGE 

# End script, if hsh cannot install package
if [[ $? -ne 0 ]]
    then echo -e "\tPackage doesn\`t exist, please, check it out"; exit 1;
fi

# Make an AppDir
hsh-run $PATH_TO_HASHER -- bash -c "mkdir /usr/src/tmp/AppDir && mkdir /usr/src/tmp/AppDir/usr && mkdir /usr/src/tmp/AppDir/usr/bin && mkdir /usr/src/tmp/AppDir/usr/share/ && mkdir /usr/src/tmp/AppDir/usr/share/icons && mkdir /usr/src/tmp/AppDir/usr/share/applications"

# Getting desktop file of package
DESKTOP_FILE=$(hsh-run $PATH_TO_HASHER -- bash -c "rpmquery --list $PACKAGE | grep -e \".desktop\" -m 1")
# Parsing it for executable, icon and name
PACKAGE_NAME=$(hsh-run $PATH_TO_HASHER -- bash -c "cat $DESKTOP_FILE | grep -e \"^Exec\" -m 1 | sed 's/Exec=//g' | cut -d' ' -f1" | sed 's/ /_/g')
PACKAGE_TITLE=$(hsh-run $PATH_TO_HASHER -- bash -c "cat $DESKTOP_FILE | grep -e \"Name\" -m 1 | sed 's/Name=//g'")
ICON_NAME=$(hsh-run $PATH_TO_HASHER -- bash -c "cat $DESKTOP_FILE | grep -e \"Icon\" -m 1 | sed 's/Icon=//g'")
# Finding executable and icon files
EXECUTABLE=$(hsh-run $PATH_TO_HASHER -- bash -c "rpmquery --list $PACKAGE | grep -e \"/bin/$PACKAGE_NAME\" -m 1")
ICON=$(hsh-run $PATH_TO_HASHER -- bash -c "rpmquery --list $PACKAGE | grep -e \"$ICON_NAME.png\" -m 1")

# If icon is not found
if ["$ICON" = ""]
    then
    # Install adwaita icons
    hsh-install $PATH_TO_HASHER icon-theme-adwaita
    # And set is as default
    hsh-run $PATH_TO_HASHER -- bash -c "cp /usr/share/icons/Adwaita/256x256/legacy/user-info.png /usr/src/tmp/AppDir/usr/share/icons/$ICON_NAME.png"
    ICON="/usr/src/tmp/AppDir/usr/share/icons/$ICON_NAME.png"
fi


# If there are no linuxdeploy
if [ ! -d /tmp/linuxdeploy ]
    # Installing linuxdeploy
    then
    cd /tmp && wget -c -N https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && chmod +x ./linuxdeploy-x86_64.AppImage && ./linuxdeploy-x86_64.AppImage --appimage-extract && mv ./squashfs-root ./linuxdeploy && cd -

    # adding plugins in linuxdeploy
    for plugin in ${PLUGINS[*]}
        do
        if [[ "$plugin" = "qt" ]] 
            # Downloading qt plugin and adding it in linuxdeploy 
            then hsh-install $PATH_TO_HASHER qt5-base-devel qt5-declarative-devel
            cd /tmp/linuxdeploy/plugins && wget https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage && chmod +x ./linuxdeploy-plugin-qt-x86_64.AppImage && ./linuxdeploy-plugin-qt-x86_64.AppImage --appimage-extract && mv ./squashfs-root ./linuxdeploy-plugin-qt && cd -
            ln -s /tmp/linuxdeploy/plugins/linuxdeploy-plugin-qt/AppRun /tmp/linuxdeploy/usr/bin/linuxdeploy-plugin-qt
        #elif [[ "$plugin" = "python" ]]
            # Downloading python plugin and adding it in linuxdeploy
            #then
        fi
    done
fi

mv /tmp/linuxdeploy/ $PATH_TO_HASHER/chroot/tmp
echo "/tmp/linuxdeploy/AppRun --appdir /usr/src/tmp/AppDir --executable $EXECUTABLE --desktop-file $DESKTOP_FILE --icon-file $ICON $plugins_with_arguments --output appimage"

hsh-run --mountpoints=/proc $PATH_TO_HASHER -- bash -c "cd /usr/src/tmp && /tmp/linuxdeploy/AppRun --appdir /usr/src/tmp/AppDir --executable $EXECUTABLE --desktop-file $DESKTOP_FILE --icon-file $ICON $plugins_with_arguments --output appimage"

echo -e "Done, you can find your appimage in $PATH_TO_HASHER/chroot/usr/src/tmp/$(hsh-run $PATH_TO_HASHER -- bash -c "ls ~/tmp/ | grep -e \"$PACKAGE_TITLE\" ")"