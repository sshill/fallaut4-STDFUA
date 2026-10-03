#!/bin/bash
# Запуск наукового тестового сеансу (за замовчуванням 3 хвилини = 180 сек)
DURATION=${1:-180}
python3 /home/hills/Documents/fallaut/run_research_session.py $DURATION
