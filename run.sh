#!/usr/bin/env bash

function Status() {
    if INFO=$($CLICOMMAND getinfo 2>&1); then
        VERSION=$(jq -r .version <<< "$INFO")
        PROTOCOL=$(jq -r .protocolversion <<< "$INFO")
        BLOCKHEIGHT=$(jq -r .blocks <<< "$INFO")
        PEERS=$(jq -r .connections <<< "$INFO")
        if STATUS=$($CLICOMMAND masternode status 2>&1); then
            TXHASH=$(jq -r .txhash <<< "$STATUS")
            TXN=$(jq -r .outputidx <<< "$STATUS")
            TX="$TXHASH:$TXN"
            ADDRESS=$(jq -r .addr <<< "$STATUS")
            MESSAGE=$(jq -r .message <<< "$STATUS")
            whiptail --title "$NAME Masternode" --msgbox "Version: $VERSION\nProtocol Version: $PROTOCOL\nBlock Height: $BLOCKHEIGHT\nPeer Count: $PEERS\n\nTX: $TX\nAddress: $ADDRESS\nStatus: $MESSAGE" 20 78
        else
            whiptail --title "$NAME Masternode" --msgbox "Version: $VERSION\nProtocol Version: $PROTOCOL\nBlock Height: $BLOCKHEIGHT\nPeer Count: $PEERS\n\nFailed retriving masternode status.\n$STATUS" 20 78
        fi
    else
        whiptail --title "$NAME Masternode" --msgbox "Failed getting info.\n$INFO" 20 78
    fi
}

function Edit() {
    nano ~/$COINDIR/$CONFFILE
}

function Logs() {
    LOGS=$(tail -50 ~/$COINDIR/debug.log)
    whiptail --title "$NAME Masternode" --msgbox "$LOGS" 50 150
}

function Restart() {
    clear
    echo "Restarting..."
    sudo service $DAEMONCOMMAND restart
    until $CLICOMMAND getinfo >/dev/null; do
        sleep 1;
    done
}

function Refresh() {
    clear
    echo "Refreshing node..."
    sudo service $DAEMONCOMMAND stop
    cd ~/$COINDIR
    rm -rf $FILES
    curl -L $CHAINURL | tar xz
    sudo service $DAEMONCOMMAND start
    until $CLICOMMAND getinfo >/dev/null; do
        sleep 1;
    done
}

function Update() {
    clear
    echo "Updating..."
    cd /opt/masternode
    sudo git pull
    exec bash /opt/masternode/run.sh
}

function Shell() {
    clear
    exit 0
}

function Menu() {
    SEL=$(whiptail --nocancel --title "$NAME Masternode" --menu "Choose an option" 16 78 8 \
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
    root=,color236
    listbox=color26,
    title=color26,
    actsellistbox=white,color26
    border=blue,
'
export TERM='xterm-256color'

if [ ! -f /etc/masternode/installed ]; then
    cd /opt/masternode
    sudo git pull
    bash /opt/masternode/install.sh
fi

while true; do Menu; done
