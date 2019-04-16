#!/usr/bin/env bash

function Status() {
    if STATUS=$($CLICOMMAND masternode status 2>&1); then
        TXHASH=$(jq -r .txhash <<< "$STATUS")
        TXN=$(jq -r .outputidx <<< "$STATUS")
        TX="$TXHASH:$TXN"
        ADDRESS=$(jq -r .addr <<< "$STATUS")
        MESSAGE=$(jq -r .message <<< "$STATUS")
        whiptail --title "$TITLE" --msgbox "TX: $TX\nAddress: $ADDRESS\nStatus: $MESSAGE" 10 78
    else
        whiptail --title "$TITLE" --msgbox "Failed retriving masternode status.\n$STATUS" 10 78
    fi
}

function Restart() {
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
    exec /opt/masternode/run.sh
}

function Shell() {
    exit 0
}

function Menu() {
    SEL=$(whiptail --nocancel --title "$CLICOMMAND" --menu "Choose an option" 16 78 8 \
        "Status" "Display masternode status." \
        "Restart" "Restart masternode." \
        "Refresh" "Wipe and reinstall blockchain." \
        "Update" "Update running masternode." \
        "Shell" "Drop to bash shell." \
        3>&1 1>&2 2>&3)
    case $SEL in
        "Status") Status;;
        "Restart") Restart;;
        "Refresh") Refresh;;
        "Update") Update;;
        "Shell") Shell;;
    esac
}

source /opt/masternode/coins/$(cat /etc/masternode/coin).sh

if [ ! -f /etc/masternode/installed ]; then
    sudo service $DAEMONCOMMAND stop 
    cd /opt/masternode
    sudo git pull
    bash /opt/masternode/install.sh
fi

while true; do Menu; done
