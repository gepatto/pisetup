#!/bin/bash

##########################################
#  Gepatto 2023                          #
#  find me on openfl or haxe discord     #
##########################################

### Color  Variables ###
BLACK="\e[30m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
PURPLE="\e[35m"
TEAL="\e[36m"
WHITE="\e[37m"
WARN="\e[38m"
CLEAR='\e[0m'

# >>>>>> HELPER FUNCTIONS
Section() {
    local color="${2:-$YELLOW}";echo -en "$color\n--------------------------------------------------------------------------------\n* \n* "$1"\n* \n--------------------------------------------------------------------------------$WHITE\n"          
} 

Line() {
    local color="${2:-$YELLOW}";echo -en "$color\n*  "$1"$WHITE\n"
}

Done() {
    echo -en "$GREEN\n--------------------------------------------------------------------------------\n* \n* "$1"\n* \n--------------------------------------------------------------------------------$WHITE\n"          
}

Warn() {
    echo -en "$WARN\n--------------------------------------------------------------------------------\n* \n* "$1"\n* \n--------------------------------------------------------------------------------$WHITE\n"          
}

Fail() {
    echo -en "$RED\n--------------------------------------------------------------------------------\n* \n* "$1"\n* \n--------------------------------------------------------------------------------$WHITE\n"          
}

Confirm() {
    echo -en "\n$PURPLE--------------------------------------------------------------------------------\n* $1?$WHITE "
    read -p "[Y/n] " -n 1 -r
    echo -en "\n$PURPLE--------------------------------------------------------------------------------\n$WHITE"          
}

ColorGreen(){
    echo -en $GREEN$1$CLEAR
}
ColorBlue(){
    echo -en $BLUE$1$CLEAR
}
ColorPurple(){
    echo -en $PURPLE$1$CLEAR
}
#END HELPER FUNCTIONS <<<<<<<<

DEFAULTTAGNAME="4.3.1-bullseye"
DOCKER='/usr/bin/docker'

function installDocker {
    
    Section "Installing Docker"

    if test -f "$DOCKER";
    then
        DOCKERVERSION=$(docker -v)
        Done "Docker $DOCKERVERSION is already installed"
    else
        Confirm "Docker is not installed yet, would you like to install (needs reboot)"
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            curl -sSL https://get.docker.com | sh
            sudo usermod -aG docker $USER
            Section "Docker is now installed, but you need to reboot and run this script again."
            exit 0;
        else
            Warn "Ok, not running this script any further"
            exit 0;
        fi
    fi

}

function installHaxeFromDocker {

    INSTALL=0

    if test -f "$DOCKER";
    then
        Section "Installing haxe from docker" 
    else
        Warn "Installing docker first ..."
        installDocker
    fi

    if test -f "/usr/local/bin/haxe";
    then
        HAXEVERSION=$(haxe --version)
        Confirm "It seems Haxe $HAXEVERSION is already installed, would you like to overwrite it"
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            INSTALL=1
        fi
    else
        INSTALL=1
    fi

    if [ $INSTALL -eq 1 ];
    then
        mkdir -p ./docker_haxe/
        sudo mkdir -p /usr/local/share/haxe/

        echo -en "\n$PURPLE>> "
        read -p "Please enter the haxe docker tagname to install [$DEFAULTTAGNAME]: " dockertagname
        TAGNAME=${dockertagname:-$DEFAULTTAGNAME}
        echo -en $WHITE"\n"

        Line "running/getting docker image ${TAGNAME}";
        docker run haxe:${TAGNAME}

        Line "getting CONTAINERID"

        CONTAINERID=`docker ps -aq --latest`

        Line "copying from container: $CONTAINERID"
        docker cp $CONTAINERID:/usr/local/bin/haxe ./docker_haxe/
        docker cp $CONTAINERID:/usr/local/bin/haxelib ./docker_haxe/
        docker cp $CONTAINERID:/usr/local/share/haxe/std  ./docker_haxe/

        sleep 2

        # create archive of binaries for future use
        HAXEVERSION=$(haxe --version)
        Line "creative haxe-binaries-$HAXEVERSION.tgz archive for future use"
        tar zcf haxe-binaries-$HAXEVERSION.tgz ./docker_haxe

        installHaxeFromDir "docker_haxe"

    fi
}

function installHaxeFromDir {

    if [[ $# -ne 1 ]]; then
        Section "Installing haxe from a directory" 
        echo -en "\n$PURPLE>> "
        read -p "Enter the path to the local dir with the haxe binaries [docker_haxe]: " dirname
        SOURCEDIR=${dirname:-docker_haxe}
        echo -en $WHITE
    else
       SOURCEDIR=$1
    fi

    if test -d $SOURCEDIR;
    then

        cd $SOURCEDIR
        if test -f haxe;
        then
            Line "copying haxe and haxelib binaries from $SOURCEDIR to /usr/local/bin/"
            sudo cp haxe /usr/local/bin/
            sudo cp haxelib /usr/local/bin/

            Line "copying haxe std lib to to /usr/local/share/haxe/std"
            sudo cp -R std /usr/local/share/haxe/
        else
            Fail "No haxe binaries found in dir $SOURCEDIR"
        fi

    else
        Fail "Sorry can't find the directory $SOURCEDIR"
    fi

    HAXEVERSION=$(haxe --version)

    # if HAXE_STD_PATH is not already in bashrc
    if [ `grep 'export HAXE_STD_PATH' ~/.bashrc | wc -l` -eq 0 ]; then
        Line "adding HAXE_STD_PATH to ~/.bashrc"
        echo -e "\nexport HAXE_STD_PATH=\"/usr/local/share/haxe/std\"" >> ~/.bashrc
    fi

    if test -f /usr/bin/neko;
    then
        Line "Good neko is already installed"
    else
        Line "installing neko"
        sudo apt install -y neko
    fi


    # setup haxelib

    Line "Setting up haxelib"
    haxelib setup
    haxelib --global update haxelib
    Done "Haxe $HAXEVERSION is installed"

}

function installOpenFL {

    Section "Installing OpenFL"

    haxelib install format
    haxelib install hxp
    haxelib install hxcpp
    haxelib install openfl
    if [ ! -f /usr/local/bin/openfl ]; then
        haxelib run openfl setup
    fi

    haxelib install flixel-tools

    if [ ! -f /usr/bin/flixel ]; then
      haxelib run flixel-tools setup
    fi
}

function installLimeGit {

    INSTALL=0
    Section "Installing Lime fron Git" 

    Line "installing some dependencies so we can compile lime"
    sudo apt install -y build-essential git
    sudo apt install -y libdrm-dev libgbm-dev libx11-dev libxext-dev libgles2-mesa-dev libasound2-dev libudev-dev
    sudo apt install -y libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libdbus-1-dev libpulse-dev

    echo -en "\n$PURPLE>> "
    read -p "Enter a path to install lime [~/Development/haxe/dev]: " dirname
    installdir=${dirname:-~/Development/haxe/dev}
    Line "creating $installdir"
    mkdir -p $installdir
    cd $installdir

    if test -d "$installdir/lime";
    then
        Confirm "There already is a lime directory at $installdir/lime.\n*  Would you like to rename it and continue "
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            DATEPOSTFIX=$(date +%F)
            mv $installdir/lime "$installdir/lime_$DATEPOSTFIX"
            INSTALL=1
        fi
    else
        INSTALL=1
    fi

    if [ $INSTALL -eq 1 ];
    then
        echo -en '\n'$PURPLE
        read -p "Enter the Branch you want to checkout [8.2.0-Dev]: " branchname
        branch=${branchname:-8.2.0-Dev}
        Line "Checking out branch $branch"
        echo -en $WHITE
        git clone --recursive https://github.com/openfl/lime -b $branch

        Line "Rebuilding lime for Raspberry Pi"
        haxelib dev lime lime
        cd 'lime'
        lime rebuild lime linux -rpi -v
    fi
}

function enableHxcppCompileCache {
    Line "checking for /home/$USER/.hxcpp_config.xml"
    if test -f /home/$USER/.hxcpp_config.xml
    then
        if [ `grep 'HXCPP_COMPILE_CACHE' ~/.hxcpp_config.xml | wc -l` -eq 0 ]; then
            MATCH="<!-- If you want to control how many compilers get spawned"
            PATCH="    <set name=\"HXCPP_COMPILE_CACHE\" value=\"\/home\/$USER\/.hxcpp_cache\" \/>\n"
            sed -e "/$MATCH/i\ $PATCH" ~/.hxcpp_config.xml > ~/.hxcpp_config_new.xml
            cp ~/.hxcpp_config.xml ~/.hxcpp_config_old.xml
            mv ~/.hxcpp_config_new.xml ~/.hxcpp_config.xml

            Done "HXCPP_COMPILE_CACHE with value /home/$USER/.hxcpp_cache has been added to /home/$USER/.hxcpp_config.xml"
        fi
    else
        Warn "There is no .hxcpp_config.xml file yet"
    fi
}

function about {
    Section "This script was created to setup Haxe,Lime and OpenFL on a Raspberry Pi 3B+ or 4B  running piOS (Raspbian Bullseye) \n* Your Raspberry Pi needs to have the (F)KMS driver overlay enabled\n* Lime applications build for native (hxcpp) can run from the commandline and on X11\n*\n* Gepatto 2023 - Find me on haxe or openfl discord"
}

function menu(){
    Section "Menu for installing Docker, Haxe, OpenFL or Lime"
    echo -ne \
"$(ColorGreen '1)') Install Docker (needed for installing haxe)
$(ColorGreen '2)') Install Haxe from Docker
$(ColorGreen '3)') Install and setup openFL
$(ColorGreen '4)') Install Lime from Github
$(ColorGreen '-- optional')
$(ColorGreen '5)') Install Haxe from a Directory ( archived binaries from previous docker installed haxe )
$(ColorGreen '6)') Enable Hxcpp Compile Cache (Experimental)
$(ColorGreen '7)') About
$(ColorGreen '0)') Exit
$(ColorPurple '>>  Choose an option:') "
        read a
        case $a in
            1) clear -x;installDocker ; menu ;;
            2) clear -x;installHaxeFromDocker ; menu ;;
            3) clear -x;installOpenFL ; menu ;;
            4) clear -x;installLimeGit ; menu ;;
            5) clear -x;installHaxeFromDir; menu ;;
            6) clear -x;enableHxcppCompileCache ; menu ;;
            7) clear -x;about ; menu ;;
        0) exit 0 ;;
        *) clear -x;echo -e $RED" Wrong option: "$a$CLEAR; menu;;
        esac
}

# LET'S START THE MENU
clear -x;
menu
