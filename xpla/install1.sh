#!/bin/bash
PROJECT_NAME="xpla"
VERSION="v1.7.0"

# Проверка и задание переменных окружения
if [ -z "$MONIKER" ]; then
    echo ""
    echo -e "\e[1m\e[32m### Установка имени ноды $PROJECT_NAME... \e[0m"
    echo ""
    read -p "Введите имя ноды: " MONIKER
    echo "export MONIKER=\"${MONIKER}\"" >> ~/.bash_profile
fi

export CHAIN_ID="dimension_37-1"
export WALLET_NAME="wallet"
export RPC_PORT="26657"

echo "export CHAIN_ID=\"$CHAIN_ID\"" >> ~/.bash_profile
echo "export WALLET_NAME=\"$WALLET_NAME\"" >> ~/.bash_profile
echo "export RPC_PORT=\"$RPC_PORT\"" >> ~/.bash_profile
source ~/.bash_profile

# Ожидание разблокировки apt
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
    echo "Ожидание разблокировки dpkg..."
    sleep 5
done
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Ожидание разблокировки dpkg (frontend)..."
    sleep 5
done

# Установка зависимостей
echo "\e[1m\e[32m### Установка зависимостей...\e[0m"
sudo apt update && \
sudo apt install curl git jq build-essential gcc unzip wget lz4 make -y

# Установка Go v1.23.4
cd $HOME
ver="1.23.4"
sudo rm -rvf /usr/local/go/
wget "https://golang.org/dl/go${ver}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "go${ver}.linux-amd64.tar.gz"
rm "go${ver}.linux-amd64.tar.gz"

# Настройка окружения Go
echo "export GOROOT=/usr/local/go" >> ~/.bash_profile
echo "export GOPATH=$HOME/go" >> ~/.bash_profile
echo "export GO111MODULE=on" >> ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile

go version

# Установка XPLA node
echo "\e[1m\e[32m### Установка $PROJECT_NAME node...\e[0m"
if [ ! -d "$HOME/xpla" ]; then
    git clone -b $VERSION https://github.com/xpladev/xpla xpla
fi
cd $HOME/xpla
git checkout $VERSION
make install || { echo "Ошибка при сборке xplad"; exit 1; }

if [ -f "$HOME/go/bin/xplad" ]; then
    sudo mv $HOME/go/bin/xplad /usr/local/bin/
else
    echo "Бинарник xplad не найден!"
    exit 1
fi

source ~/.bash_profile

# Инициализация ноды
cd $HOME
xplad config chain-id $CHAIN_ID
xplad config keyring-backend os
xplad config node tcp://localhost:$RPC_PORT
xplad init $MONIKER --chain-id $CHAIN_ID -o

# Получение genesis файла
wget -O $HOME/.xpla/config/genesis.json https://snapshots.polkachu.com/genesis/xpla/genesis.json --inet4-only || echo "Не удалось скачать genesis.json"

# Настройка peers и seeds
PEERS="1aee2ab827530e2fe8163581d8fe88ad78401d43@144.76.107.29:26656,e2e9ddf939c230207270ec61dc8676d695299fd0@167.86.116.235:26656"
SEEDS="59df4b3832446cd0f9c369da01f2aa5fe9647248@162.55.65.137:27956"

if [ -f "$HOME/.xpla/config/config.toml" ]; then
    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" -e "s/^seeds *=.*/seeds = \"$SEEDS\"/" $HOME/.xpla/config/config.toml
else
    echo "Файл config.toml отсутствует! Создайте его вручную."
fi

# Конфигурация портов
EXTERNAL_IP=$(wget -qO- eth0.me)
P2P_PORT=26656
if [ -f "$HOME/.xpla/config/config.toml" ]; then
    sed -i -e "s/^external_address *=.*/external_address = \"$EXTERNAL_IP:$P2P_PORT\"/" $HOME/.xpla/config/config.toml
fi

# Оптимизация pruning
if [ -f "$HOME/.xpla/config/app.toml" ]; then
    sed -i.bak -e "s/^pruning *=.*/pruning = \"custom\"/" \
               -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" \
               -e "s/^pruning-interval *=.*/pruning-interval = \"10\"/" \
               $HOME/.xpla/config/app.toml
else
    echo "Файл app.toml отсутствует! Создайте его вручную."
fi

# Создание systemd сервиса
sudo tee /etc/systemd/system/xpla.service > /dev/null <<EOF
[Unit]
Description=XPLA Node
After=network-online.target

[Service]
User=$(whoami)
Type=simple
ExecStart=/usr/local/bin/xplad start --home $HOME/.xpla
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

# Запуск ноды
sudo systemctl daemon-reload
sudo systemctl enable xpla
sudo systemctl start xpla

echo "\e[1m\e[32m### Установка XPLA завершена! Проверка статуса:\e[0m"
systemctl status xpla --no-pager
