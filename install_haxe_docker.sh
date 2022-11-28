#!/bin/bash

BLACK="[30m"
RED="[31m"
GREEN="[32m"
YELLOW="[33m"
BLUE="[34m"
PURPLE="[35m"
TEAL="[36m"
WHITE="[37m"
WARN="[38m"

# >>>>>> HELPER FUNCTIONS
function echoSection {
    #local color="${2:-$YELLOW}"
    echo -en "\e$YELLOW\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n--------------------------------------------------------------------------------\e[$WHITE\n\n"          
} 
function echoLine {
    local color="${2:-$YELLOW}"
    echo -en "\e$color\n-- " $1 "\e$WHITE"
}
function echoWarn {
    echo -en "\e$WARN\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n--------------------------------------------------------------------------------\e$WHITE\n"
}
function echoFail {
    echo -en "\e$RED\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n--------------------------------------------------------------------------------\e$WHITE\n"
}
function echoConfirm {
    echo -en "\n\e$PURPLE------------------------------------------------------------------------------------\n--\n"
    echo -en "--  $1?\n"
    read -p "[Y/n] " -n 1 -r
    echo -en "\n--\n-----------------------------------------------------------------------------------\e$WHITE\n"          
}
#END HELPER FUNCTIONS <<<<<<<<

INSTALL=1
TAGNAME="4.2.5-bullseye"

# Get the options
while getopts ":dtl:" option; do
   case $option in
      l);; #use tag in this script
      d) INSTALL=0;;
      t) # Enter a name
         # echo $OPTARG
         TAGNAME=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done


#echo $0
DOCKER='/usr/bin/docker'

if [ "$#" -lt 1 ]; then
    echo -en "\nUsage: -t TAGNAME | -d | -l \ni.e. : \e[3m $0 -t $TAGNAME\n\e[0m"
    echo -en "or     \e[3m $0 -l \e[0m ( use tag $TAGNAME defined in this script) \n\e[0m"
    echo -en "or     \e[3m $0 -d \e[0m ( don't install haxe )  \n\e[0m"
    
    exit 0;
fi


if test -f "$DOCKER" 
then
    echoSection "Ok you have docker installed, let's get going" $GREEN
else
    echoConfirm "hmmm Docker is not installed yet, would you like to install (needs reboot)"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        curl -sSL https://get.docker.com | sh
        sudo usermod -aG docker pi
        echoSection "Docker is now installed, but you need to reboot and run this script again."
        exit 0;
    else
        echoWarn "Ok, not running this script any further"
        exit 0;
    fi
fi

mkdir -p ./docker_haxe/
sudo mkdir -p /usr/local/share/haxe/
#sudo mkdir -p /usr/local/share/haxe/std

echoSection "running/getting docker image ${TAGNAME}";
docker run haxe:${TAGNAME}

echoLine "getting CONTAINERID"

CONTAINERID=`docker ps -aq --latest`

echoLine "copying from container: $CONTAINERID"
docker cp $CONTAINERID:/usr/local/bin/haxe ./docker_haxe/
docker cp $CONTAINERID:/usr/local/bin/haxelib ./docker_haxe/
docker cp $CONTAINERID:/usr/local/share/haxe/std  ./docker_haxe/

echoLine "creative haxe-binaries.tgz archive for future use"
tar zcf haxe-binaries.tgz ./docker_haxe

if [ $INSTALL -eq 1 ] 
then
    cd ./docker_haxe/
    echoSection "copying haxe and haxelib binaries to /usr/local/bin/"
    sudo cp haxe /usr/local/bin/
    sudo cp haxelib /usr/local/bin/

    echoSection "copying haxe std lib to to /usr/local/share/haxe/std"
    sudo cp -R std /usr/local/share/haxe/

    echoSection "adding HAXE_STD_PATH to ~/.baschrc"
    if [ `grep 'export HAXE_STD_PATH' ~/.bashrc | wc -l` -eq 0 ]; then
    echo -e "\nexport HAXE_STD_PATH=\"/usr/local/share/haxe/std\"" >> ~/.bashrc
    fi

    echoSection "installing neko"
    sudo apt install neko

    echoSection "installing some dependencies so we can compile lime"
    sudo apt install libdrm-dev libgbm-dev libx11-dev libxext-dev libgles2-mesa-dev libasound2-dev libudev-dev
    sudo apt install -y libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libdbus-1-dev

    echoConfirm "Would you like to setup a Development directory for haxe and haxelib?\n--  ~/Development/haxe/dev and ~/Development/haxe/lib"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        mkdir -p ~/Development/haxe/{dev,lib}
        haxelib setup ~/Development/haxe/lib
    fi
fi

echoSection "All Done"
haxe -v