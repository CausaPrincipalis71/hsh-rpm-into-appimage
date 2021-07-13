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

# Declaration of parameters
PACKAGE=""                      
PLUGINS[6]=""
PLUGINS_COUNT=0                   
APT_CONFIG="/etc/apt/apt.conf"
PATH_TO_HASHER=""

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

 --plugin)  if [ -n "$2" ]
            then   PLUGINS[PLUGINS_COUNT]="$2";
                    PLUGINS_COUNT=$(($PLUGINS_COUNT + 1));
            else echo -e "\tPlease, specify the plugin"; exit 1;
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


