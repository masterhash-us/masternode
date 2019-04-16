cd /tmp
echo "Downloading and extracting."
curl -Lo coin.tar.gz $URL
tar -xvf coin.tar.gz
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

RPCUSER=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

while [ "$KEY" == "" ]
do
    KEY=$(whiptail --inputbox "Masternode Privkey" 8 78 --title "$TITLE" --nocancel 3>&1 1>&2 2>&3)
done

echo "masternode=1" > ~/$COINDIR/$CONFFILE
echo "masternodeprivkey=$KEY" >> ~/$COINDIR/$CONFFILE
echo "rpcpassword=${RPCPASSWORD}"  >> ~/$COINDIR/$CONFFILE
echo "rpcuser=${RPCUSER}"  >> ~/$COINDIR/$CONFFILE
echo "rpcallowip=127.0.0.1" >> ~/$COINDIR/$CONFFILE
echo "server=1" >> ~/$COINDIR/$CONFFILE

echo "Starting service."
sudo systemctl start $DAEMONCOMMAND

sudo touch /etc/masternode/installed