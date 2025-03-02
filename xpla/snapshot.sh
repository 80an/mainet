#!/bin/bash
PROJECT_NAME="xpla"

echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Stopping $PROJECT_NAME node... \e[0m" && sleep 1
echo ''
sudo systemctl stop xplad

echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Downloading $PROJECT_NAME node snapshot... \e[0m" && sleep 1
echo ''
rm -rf $HOME/.xpla/data/application.db 
sleep 1
cp $HOME/.xpla/data/priv_validator_state.json $HOME/.xpla/priv_validator_state.json.backup
rm -rf $HOME/.xpla/data

if [ -n "$1" ]
then
    if [ $1 = "polkachu" ]
    then
        wget -O latest_snapshot.tar.lz4 https://snapshots.polkachu.com/snapshots/xpla/xpla_13174875.tar.lz4 --inet4-only
    fi
fi


sudo apt install lz4
# wget -O xpla_13174875.tar.lz4 https://snapshots.polkachu.com/snapshots/xpla/xpla_13174875.tar.lz4 --inet4-only
# sudo service xpla stop

# Back up priv_validator_state.json if needed
# cp ~/.xpla/data/priv_validator_state.json  ~/.xpla/priv_validator_state.json

# Reset node state
#xplad tendermint unsafe-reset-all --home $HOME/.xpla --keep-addr-book

# lz4 -c -d xpla_13174875.tar.lz4  | tar -x -C $HOME/.xpla

# Replace with the backed-up priv_validator_state.json
# cp ~/.xpla/priv_validator_state.json  ~/.xpla/data/priv_validator_state.json

# sudo service xpla start
# rm -v xpla_13174875.tar.lz4

lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.xpla
mv $HOME/.xpla/priv_validator_state.json.backup $HOME/.xpla/data/priv_validator_state.json
rm -f ./latest_snapshot.tar.lz4

#rm -rf $HOME/.evmosd/data/snapshots
#cp $HOME/.evmosd/data/priv_validator_state.json $HOME/.evmosd/priv_validator_state.json.backup
#evmosd tendermint unsafe-reset-all --home $HOME/.evmosd --keep-addr-book
#wget -O latest_snapshot.tar.lz4 https://rpc-zero-gravity-testnet.trusted-point.com/latest_snapshot.tar.lz4
#lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.evmosd
#mv $HOME/.evmosd/priv_validator_state.json.backup $HOME/.evmosd/data/priv_validator_state.json
#rm -f ./latest_snapshot.tar.lz4

echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Restarting $PROJECT_NAME node... \e[0m" && sleep 1
echo ''
sudo systemctl restart xplad
