#!/bin/bash

echo "=== Остановка ноды XPLA ==="

# Ищем процесс xplad и убиваем его
PID=$(ps aux | grep "xplad start" | grep -v grep | awk '{print $2}')
if [ -n "$PID" ]; then
    kill -9 "$PID"
    echo "Нода XPLA остановлена."
else
    echo "Нода XPLA не запущена."
fi

sleep 3

echo "=== Очистка места ==="

# Очистка логов XPLA
echo "Очищаем логи XPLA..."
rm -rf ~/.xpla/logs/*

# Очистка systemd логов
echo "Очищаем systemd логи..."
sudo journalctl --vacuum-size=100M

# Очистка Docker (если используется)
echo "Очищаем Docker..."
docker system prune -af
docker volume prune -f

# Автоудаление ненужных пакетов
echo "Удаляем ненужные пакеты..."
sudo apt autoremove -y
sudo apt clean

# Освобождение inode (если диск заполнен не объёмом, а файлами)
echo "Удаляем старые файлы в /var/tmp и /tmp..."
sudo find /var/tmp -type f -delete
sudo find /tmp -type f -delete

sleep 3

echo "=== Перезапуск ноды XPLA ==="
nohup /root/go/bin/xplad start > ~/xpla.log 2>&1 &

sleep 5

# Проверяем, запустилась ли нода
if ps aux | grep "xplad start" | grep -v grep > /dev/null; then
    echo "✅ Нода XPLA успешно запущена!"
else
    echo "❌ Ошибка! Нода XPLA не запустилась."
fi
