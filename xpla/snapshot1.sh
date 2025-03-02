#!/bin/bash

PROJECT_NAME="xpla"
XPLAD_CMD="/root/go/bin/xplad"
SERVICE_NAME="xplad.service"
LOG_FILE="$HOME/xpla.log"

# Проверяем, запущена ли нода через systemd
if systemctl list-units --full -all | grep -q "$SERVICE_NAME"; then
    echo -e "\e[1m\e[32mОстановка ноды $PROJECT_NAME (systemd)...\e[0m"
    sudo systemctl stop $SERVICE_NAME
else
    echo -e "\e[1m\e[32mОстановка ноды $PROJECT_NAME (ручной запуск)...\e[0m"
    pkill -9 xplad
fi

sleep 3

# Очистка данных
rm -rf $HOME/.xpla/data/application.db 
sleep 1
cp $HOME/.xpla/data/priv_validator_state.json $HOME/.xpla/priv_validator_state.json.backup
rm -rf $HOME/.xpla/data

# Загрузка снапшота
wget -O latest_snapshot.tar.lz4 https://snapshots.polkachu.com/snapshots/xpla/xpla_13174875.tar.lz4 --inet4-only
lz4 -d -c ./latest_snapshot.tar.lz4 | tar -xf - -C $HOME/.xpla
mv $HOME/.xpla/priv_validator_state.json.backup $HOME/.xpla/data/priv_validator_state.json
rm -f ./latest_snapshot.tar.lz4

sleep 3

# Запуск ноды
if systemctl list-units --full -all | grep -q "$SERVICE_NAME"; then
    echo -e "\e[1m\e[32mЗапуск ноды $PROJECT_NAME (systemd)...\e[0m"
    sudo systemctl restart $SERVICE_NAME
else
    echo -e "\e[1m\e[32mЗапуск ноды $PROJECT_NAME (ручной запуск)...\e[0m"
    nohup $XPLAD_CMD start > $LOG_FILE 2>&1 &
fi

sleep 5

# Проверка работы ноды
if ps aux | grep "$XPLAD_CMD start" | grep -v grep > /dev/null; then
    echo "✅ Нода $PROJECT_NAME успешно запущена!"
else
    echo "❌ Ошибка! Нода $PROJECT_NAME не запустилась."
fi
