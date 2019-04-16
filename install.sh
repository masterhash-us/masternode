#!/usr/bin/env bash

cat << "EOF"
 __  __           _            _    _           _     
|  \/  |         | |          | |  | |         | |    
| \  / | __ _ ___| |_ ___ _ __| |__| | __ _ ___| |__  
| |\/| |/ _` / __| __/ _ \ '__|  __  |/ _` / __| '_ \ 
| |  | | (_| \__ \ ||  __/ |  | |  | | (_| \__ \ | | |
|_|  |_|\__,_|___/\__\___|_|  |_|  |_|\__,_|___/_| |_|
EOF
echo
echo "Welcome to the MasterHash masternode install."
echo
echo "This script will install a masternode for $NAME."
read -rsp 'Please any key to continue, or close this terminal to terminate installation.' -n1 key

cd /tmp

sudo apt-get install jq

echo "Downloading and extracting."
curl -L $URL | tar xz
sudo mv $DAEMONCOMMAND $CLICOMMAND /usr/local/bin
echo "Writing service."
sudo tee /etc/systemd/system/$DAEMONCOMMAND.service > /dev/null << EOL
[Unit]
Description=Coin daemon
After=network-online.target
[Service]
Type=forking
User=$USER
ExecStart=/usr/local/bin/$DAEMONCOMMAND
ExecStop=/usr/local/bin/$CLICOMMAND stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
echo "Enabling service."
sudo systemctl enable $DAEMONCOMMAND

echo "Creating coin directory."
mkdir ~/$COINDIR

cd ~/$COINDIR

RPCUSER=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

while [ "$KEY" == "" ]
do
    KEY=$(whiptail --inputbox "Masternode Privkey" 8 78 --title "$NAME Masternode" --nocancel 3>&1 1>&2 2>&3)
done

echo "Writing config."

echo "daemon=1" > $CONFFILE
echo "masternode=1" >> $CONFFILE
echo "masternodeprivkey=$KEY" >> $CONFFILE
echo "rpcpassword=${RPCPASSWORD}" >> $CONFFILE
echo "rpcuser=${RPCUSER}" >> $CONFFILE
echo "rpcallowip=127.0.0.1" >> $CONFFILE
echo "server=1" >> $CONFFILE

echo "Downloading blockchain."
curl -L $CHAINURL | tar xz

echo "Starting service."
sudo systemctl start $DAEMONCOMMAND

sudo touch /etc/masternode/installed