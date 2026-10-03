#!/bin/bash
# Запуск стріму Chiaki разом із синхронізованим аналітичним трекером на 15 хвилин

echo "======================================================="
echo "   Запуск Chiaki + Автоматичний Аналізатор Сесії"
echo "======================================================="

# Запускаємо фоновий трекер
python3 /home/hills/Documents/fallaut/chiaki_watcher.py &
WATCHER_PID=$!

echo "Аналізатор запущено у фоні (PID: $WATCHER_PID)."
echo "Запуск Chiaki..."

# Запускаємо Chiaki
chiaki

# Коли користувач закриває Chiaki, чекаємо завершення трекера
echo "Chiaki закрито. Завершення аналітичної сесії..."
wait $WATCHER_PID
echo "Усі дані та кадри збережено в: /home/hills/Documents/fallaut/screens/session/"
