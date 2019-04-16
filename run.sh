#!/usr/bin/env bash

function Status() {
    if INFO=$($CLICOMMAND getinfo 2>&1); then
        VERSION=$(jq -r .version <<< "$INFO")
        PROTOCOL=$(jq -r .protocolversion <<< "$INFO")
        BLOCKHEIGHT=$(jq -r .blocks <<< "$INFO")
        if STATUS=$($CLICOMMAND masternode status 2>&1); then
            TXHASH=$(jq -r .txhash <<< "$STATUS")
            TXN=$(jq -r .outputidx <<< "$STATUS")
            TX="$TXHASH:$TXN"
            ADDRESS=$(jq -r .addr <<< "$STATUS")
            MESSAGE=$(jq -r .message <<< "$STATUS")
            whiptail --title "$TITLE" --msgbox "Version: $VERSION\nProtocol Version: $PROTOCOL\nBlock Height: $BLOCKHEIGHT\nTX: $TX\nAddress: $ADDRESS\nStatus: $MESSAGE" 20 78
        else
            whiptail --title "$TITLE" --msgbox "Version: $VERSION\nProtocol Version: $PROTOCOL\nBlock Height: $BLOCKHEIGHT\nFailed retriving masternode status.\n$STATUS" 20 78
        fi
    else
        whiptail --title "$TITLE" --msgbox "Failed getting info.\n$INFO" 20 78
    fi
}

function Edit() {
    nano ~/$COINDIR/$CONFFILE
}

function Logs() {
    LOGS=$(tail -50 ~/$COINDIR/debug.log)
    whiptail --title "$TITLE" --msgbox "$LOGS" 50 150
}

function Restart() {
    echo "Restarting..."
    sudo service $DAEMONCOMMAND restart
    until $CLICOMMAND getinfo >/dev/null; do
        sleep 1;
    done
}

function Refresh() {
    sudo service $DAEMONCOMMAND stop
    cd ~/$COINDIR
    rm -rf $FILES
    sudo service $DAEMONCOMMAND start
    until $CLICOMMAND getinfo >/dev/null; do
        sleep 1;
    done
}

function Update() {
    cd /opt/masternode
    sudo git pull
    exec bash /opt/masternode/run.sh
}

function Shell() {
    exit 0
}

function Menu() {
    SEL=$(whiptail --nocancel --title "$CLICOMMAND" --menu "Choose an option" 16 78 8 \
        "Status" "Display masternode status." \
        "Edit" "Edit daemon configuration." \
        "Logs" "Display logs." \
        "Restart" "Restart masternode." \
        "Refresh" "Wipe and reinstall blockchain." \
        "Update" "Update running masternode." \
        "Shell" "Drop to bash shell." \
        3>&1 1>&2 2>&3)
    case $SEL in
        "Status") Status;;
        "Edit") Edit;;
        "Logs") Logs;;
        "Restart") Restart;;
        "Refresh") Refresh;;
        "Update") Update;;
        "Shell") Shell;;
    esac
}

source /opt/masternode/coins/$(cat /etc/masternode/coin).sh

export NEWT_COLORS='
    window=,white
    root=,blue
    border=blue,color8
    title=white,gray
    listbox=brightblue,white
    compactbutton=blue,white
    actsellistbox=white,blue
'

if [ ! -f /etc/masternode/installed ]; then
    sudo service $DAEMONCOMMAND stop 
    cd /opt/masternode
    sudo git pull
    bash /opt/masternode/install.sh
fi

while true; do Menu; done
