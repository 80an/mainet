#!/bin/bash
PROJECT_NAME="xpla"
VERSION="v1.7.0"


if [ ! $MONIKER ]; then
    echo ""
    echo -e "\e[1m\e[32m###########################################################################################"
    echo -e "\e[1m\e[32m### Setting $PROJECT_NAME node moniker... \e[0m" && sleep 1
    echo ""
    read -p "Enter node moniker: " MONIKER
    echo 'export MONIKER='\"${MONIKER}\" >> ~/.bash_profile
fi

if [ ! $CHAIN_ID ]; then
    echo 'export CHAIN_ID="dimension_37-1"' >> ~/.bash_profile
fi

if [ ! $WALLET_NAME ]; then
    echo 'export WALLET_NAME="wallet"' >> ~/.bash_profile
fi

if [ ! $RPC_PORT ]; then
    echo 'export RPC_PORT="26657"' >> ~/.bash_profile
fi
source $HOME/.bash_profile


echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Installing dependencies... \e[0m" && sleep 1
echo ""
#update
sudo apt update && \
sudo apt install curl git jq build-essential gcc unzip wget lz4 -y

# Установка Go
cd $HOME
ver="1.23.4"

# Удаление предыдущей установки (если она есть)
sudo rm -rvf /usr/local/go/

# Скачивание Go
wget "https://golang.org/dl/go${ver}.linux-amd64.tar.gz"

# Распаковка Go
sudo tar -C /usr/local -xzf "go${ver}.linux-amd64.tar.gz"

# Удаление архива
rm "go${ver}.linux-amd64.tar.gz"

# Настройка переменных окружения
echo "export GOROOT=/usr/local/go" >> ~/.bash_profile
echo "export GOPATH=$HOME/go" >> ~/.bash_profile
echo "export GO111MODULE=on" >> ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile

# Обновление текущей сессии
source ~/.bash_profile

echo "Go установлен и настроен!"

go version

echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Installing $PROJECT_NAME node... \e[0m" && sleep 1
echo ""
#install binary 
git clone -b $VERSION https://github.com/xpladev/xpla xpla
cd xpla
git checkout $VERSION
make install
xplad version
source $HOME/.bash_profile

#init node
cd $HOME
xplad config chain-id $CHAIN_ID
if [ -n "$1" ] && [ $1 = "test" ]
then
    xplad config keyring-backend test
else
    xplad config keyring-backend os
fi
xplad config node tcp://localhost:$RPC_PORT
xplad init $MONIKER --chain-id $CHAIN_ID

#get genesis
wget -O $HOME/.xpla/config/genesis.json https://snapshots.polkachu.com/genesis/xpla/genesis.json --inet4-only

#get addrbook
#wget -O $HOME/.xpla/config/addrbook.json https://snapshots.polkachu.com/addrbook/xpla/addrbook.json --inet4-only
#curl -Ls https://snapshots.liveraven.net/snapshots/testnet/zero-gravity/addrbook.json > $HOME/.0gchain/config/addrbook.json

#peers, seeds

PEERS=1aee2ab827530e2fe8163581d8fe88ad78401d43@144.76.107.29:26656,e2e9ddf939c230207270ec61dc8676d695299fd0@167.86.116.235:26656,aa94c497380fdcc306b9e04323861057d5dbc620@74.118.136.201:26656,ca757c6e1144cc8c49813f8e71cd925e86e959c3@94.237.93.61:26656,c6bb7f684aeccec412ef54fd635b90f1defc8a65@35.221.91.237:26656
#SEEDS="59df4b3832446cd0f9c369da01f2aa5fe9647248@162.55.65.137:27956" && \
#sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.0gchain/config/config.toml
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.xpla/config/config.toml


#config
EXTERNAL_IP=$(wget -qO- eth0.me) \
PROXY_APP_PORT=26658 \
P2P_PORT=26656 \
PPROF_PORT=6060 \
API_PORT=1317 \
GRPC_PORT=9090 \
GRPC_WEB_PORT=9091

#set port
sed -i \
    -e "s/\(proxy_app = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$PROXY_APP_PORT\"/" \
    -e "s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$RPC_PORT\"/" \
    -e "s/\(pprof_laddr = \"\)\([^:]*\):\([0-9]*\).*/\1localhost:$PPROF_PORT\"/" \
    -e "/\[p2p\]/,/^\[/{s/\(laddr = \"tcp:\/\/\)\([^:]*\):\([0-9]*\).*/\1\2:$P2P_PORT\"/}" \
    -e "/\[p2p\]/,/^\[/{s/\(external_address = \"\)\([^:]*\):\([0-9]*\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/; t; s/\(external_address = \"\).*/\1${EXTERNAL_IP}:$P2P_PORT\"/}" \
    $HOME/.xpla/config/config.toml

sed -i \
    -e "/\[api\]/,/^\[/{s/\(address = \"tcp:\/\/\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$API_PORT\4/}" \
    -e "/\[grpc\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_PORT\4/}" \
    -e "/\[grpc-web\]/,/^\[/{s/\(address = \"\)\([^:]*\):\([0-9]*\)\(\".*\)/\1\2:$GRPC_WEB_PORT\4/}" $HOME/.xpla/config/app.toml

#set pruning
sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.xpla/config/app.toml
sed -i.bak -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.xpla/config/app.toml
sed -i.bak -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" $HOME/.xpla/config/app.toml

#set gas
#sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" $HOME/.xpla/config/app.toml


#echo ""
#echo -e "\e[1m\e[32m###########################################################################################"
#echo -e "\e[1m\e[32m### Downloading $PROJECT_NAME node snapshot... \e[0m" && sleep 1
#echo ""
#shapshot
#cp $HOME/.xpla/data/priv_validator_state.json $HOME/.xpla/priv_validator_state.json.backup
#rm -rf $HOME/.xpla/data
#curl -L http://snapshots.liveraven.net/snapshots/testnet/zero-gravity/zgtendermint_16600-1_latest.tar.lz4 | tar -Ilz4 -xf - -C $HOME/.0gchain
#mv $HOME/.0gchain/priv_validator_state.json.backup $HOME/.0gchain/data/priv_validator_state.json


echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Setting $PROJECT_NAME node service... \e[0m" && sleep 1
echo ""
#service file
sudo tee /etc/systemd/system/xpla.service > /dev/null <<EOF
[Unit]
Description="xpla node"
After=network-online.target
[Service]
User=$USER
Type=simple
ExecStart=$(which xplad) start --home $HOME/.xpla
Restart=on-failure
RestartSec=3
LimitNOFILE=4096
Environment="DAEMON_NAME=xplad"
Environment="DAEMON_HOME=$HOME/.xpla"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF


echo ""
echo -e "\e[1m\e[32m###########################################################################################"
echo -e "\e[1m\e[32m### Starting $PROJECT_NAME node... \e[0m" && sleep 1
echo ""
#start node
sudo systemctl daemon-reload && \
sudo systemctl enable xplad && \
sudo systemctl start xplad


#echo ""
#echo -e "\e[1m\e[32m###########################################################################################"
#echo -e "\e[1m\e[32m### Creating $PROJECT_NAME node comsos wallet... \e[0m" && sleep 1
#echo ""
#echo "Select option:"
#echo "1 - Create a new wallet"
#echo "2 - Import an existing wallet"
#read -p "Enter option: " OPTION
#case $OPTION in
#    2)  #Import wallet
#        0gchaind keys add --recover $WALLET_NAME --eth
#        ;;
#    *)  #Create wallet
#        0gchaind keys add $WALLET_NAME --eth
#        ;;
#esac


#echo ""
#echo -e "\e[1m\e[32m###########################################################################################"
#echo -e "\e[1m\e[32m### Getting $PROJECT_NAME node EVM address... \e[0m" && sleep 1
#echo ""
#get EVM address
#echo "0x$(0gchaind debug addr $(0gchaind keys show $WALLET_NAME -a) | grep hex | awk '{print $3}')"

#get EVM privatekey
#0gchaind keys unsafe-export-eth-key $WALLET_NAME
#echo ""
