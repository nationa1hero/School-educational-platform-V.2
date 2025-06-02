#!/usr/bin/env bash
#
# Скрипт для развёртывания геймификационного модуля
# в уже существующем локальном проекте School-educational-platform-V.2.
#
# Предполагает, что вы уже находитесь в корне проекта (рядом с manage.py).
# Скрипт создаёт папки data/, gamification/, tests/ и вносит правки в settings.py.

set -e

echo "=== 1) Проверка текущей директории ==="
# Проверяем, есть ли manage.py в текущей папке
if [ ! -f "manage.py" ]; then
  echo "Ошибка: в текущей директории не найден manage.py."
  echo "Запустите этот скрипт из корня проекта School-educational-platform-V.2."
  exit 1
fi
echo "Текущая директория выглядит как корень Django-проекта — продолжаем."

echo
echo "=== 2) Создаём директорию data/ и шаблонные JSON-файлы ==="
mkdir -p data

#  — tasks.json (примерная структура; при необходимости замените своими 368 записями)
cat > data/tasks.json << 'EOF'
[
  /* Пример: 368 задач с уровнями сложности (1, 2 или 3). */
  /* Здесь минимальный шаблон. Дублируйте или дополняйте до 368 записей. */
  { "id": 1, "level": 1 },
  { "id": 2, "level": 2 },
  { "id": 3, "level": 3 }
  /* ... продолжайте до 368 ... */
]
EOF

#  — users.json (примерный шаблон)
cat > data/users.json << 'EOF'
{
  "1": { "name": "Alice", "points": 0, "rank": 1, "achievements": [], "tasks_solved": 0 },
  "2": { "name": "Bob",   "points": 0, "rank": 1, "achievements": [], "tasks_solved": 0 }
  /* Добавьте других пользователей по необходимости */
}
EOF

#  — achievements.json (примерный шаблон)
cat > data/achievements.json << 'EOF'
[
  {
    "name": "Новичок",
    "condition_key": "points",
    "condition_value": 10
  },
  {
    "name": "Средний Ученик",
    "condition_key": "points",
    "condition_value": 100
  },
  {
    "name": "Решил 50 задач",
    "condition_key": "tasks_solved",
    "condition_value": 50
  }
  /* Добавьте остальные достижения из вашего списка */
]
EOF

#  — ranks.json (10 рангов и пороги)
cat > data/ranks.json << 'EOF'
{
  "1": 0,
  "2": 50,
  "3": 120,
  "4": 220,
  "5": 360,
  "6": 540,
  "7": 760,
  "8": 1020,
  "9": 1320,
  "10": 1650
}
EOF

echo "Каталог data/ и JSON-файлы созданы."
echo

echo "=== 3) Создаём директорию gamification/ и пишем модули ==="
mkdir -p gamification

#  — gamification/__init__.py
touch gamification/__init__.py

#  — gamification/gamification.py
cat > gamification/gamification.py << 'EOF'
import json
from django.conf import settings
from typing import Dict, Any
from gamification.achievements import check_achievements

class GameManager:
    """
    Класс для управления начислением очков, присвоением рангов и достижений.
    Пути к JSON-файлам берутся из настроек Django (settings.GAMIFICATION_*).
    """

    def __init__(self):
        self.users_path = settings.GAMIFICATION_USERS_JSON
        self.ranks_path = settings.GAMIFICATION_RANKS_JSON
        self.achievements_path = settings.GAMIFICATION_ACHIEVEMENTS_JSON

        with open(self.users_path, 'r', encoding='utf-8') as f:
            self.users: Dict[str, Dict[str, Any]] = json.load(f)

        with open(self.ranks_path, 'r', encoding='utf-8') as f:
            self.ranks: Dict[str, int] = json.load(f)

        with open(self.achievements_path, 'r', encoding='utf-8') as f:
            self.achievements_list = json.load(f)

    @staticmethod
    def calculate_points(level: int) -> int:
        """
        Возвращает количество очков за задачу заданного уровня.
        Уровни: 1 → 1 очко, 2 → 2 очка, 3 → 3 очка.
        """
        if level not in (1, 2, 3):
            raise ValueError("Уровень задачи может быть только 1, 2 или 3")
        return level

    def _get_next_rank(self, current_points: int) -> int:
        """
        Определяет, какой ранг соответствует текущему количеству очков.
        Возвращает наибольший ранг, порог которого <= current_points.
        """
        rank = 1
        for rank_str, threshold in sorted(self.ranks.items(), key=lambda x: int(x[0])):
            if current_points >= threshold:
                rank = int(rank_str)
        return rank

    def update_user_after_task(self, user_id: str, task_level: int) -> None:
        """
        Обновляет данные пользователя, когда он решает задачу.
        1) Инкрементирует user['tasks_solved']
        2) Начисляет очки.
        3) Пересчитывает ранг.
        4) Пересчитывает список достижений.
        5) Сохраняет users.json.
        """
        if user_id not in self.users:
            return

        user = self.users[user_id]

        # 1) Увеличиваем счётчик решённых задач
        user['tasks_solved'] = user.get('tasks_solved', 0) + 1

        # 2) Начисляем очки
        points = self.calculate_points(task_level)
        user['points'] = user.get('points', 0) + points

        # 3) Пересчитываем ранг
        user['rank'] = self._get_next_rank(user['points'])

        # 4) Пересчитываем достижения
        user['achievements'] = check_achievements(user, self.achievements_list)

        # 5) Сохраняем users.json
        self.save_users()

    def save_users(self) -> None:
        """
        Сохраняет текущее состояние self.users в self.users_path.
        """
        with open(self.users_path, 'w', encoding='utf-8') as f:
            json.dump(self.users, f, indent=4, ensure_ascii=False)
EOF

#  — gamification/achievements.py
cat > gamification/achievements.py << 'EOF'
from typing import List, Dict, Any

def check_achievements(user: Dict[str, Any],
                       achievements_list: List[Dict[str, Any]]) -> List[str]:
    """
    Проверяет выполнение условий достижений и возвращает список имён.
    achievements_list — список словарей с ключами:
      - "name": str
      - "condition_key": str  (например, "points" или "tasks_solved")
      - "condition_value": int
    """
    earned = []
    for ach in achievements_list:
        name = ach.get('name')
        key = ach.get('condition_key')
        value = ach.get('condition_value', 0)
        if key in user and isinstance(user[key], (int, float)) and user[key] >= value:
            earned.append(name)
    return earned
EOF

echo "Каталог gamification/ и файлы с кодом созданы."
echo

echo "=== 4) Создаём директорию tests/ и пишем тесты ==="
mkdir -p tests

#  — tests/test_gamification.py
cat > tests/test_gamification.py << 'EOF'
import json
import pytest
from pathlib import Path

from gamification.gamification import GameManager

@pytest.fixture
def sample_data(tmp_path):
    users = {
        "1": {"name": "TestUser", "points": 0, "rank": 1, "achievements": [], "tasks_solved": 0}
    }
    ranks = {"1": 0, "2": 5, "3": 10}
    achievements = [
        {"name": "Новичок", "condition_key": "points", "condition_value": 5},
        {"name": "Задачник", "condition_key": "tasks_solved", "condition_value": 1}
    ]

    u_path = tmp_path / "users.json"
    r_path = tmp_path / "ranks.json"
    a_path = tmp_path / "achievements.json"
    u_path.write_text(json.dumps(users, ensure_ascii=False))
    r_path.write_text(json.dumps(ranks, ensure_ascii=False))
    a_path.write_text(json.dumps(achievements, ensure_ascii=False))
    return str(u_path), str(r_path), str(a_path)

def test_calculate_points():
    assert GameManager.calculate_points(1) == 1
    assert GameManager.calculate_points(2) == 2
    assert GameManager.calculate_points(3) == 3
    with pytest.raises(ValueError):
        GameManager.calculate_points(5)

def test_update_user_after_task(sample_data):
    users_path, ranks_path, achievements_path = sample_data
    from django.conf import settings
    settings.GAMIFICATION_USERS_JSON = users_path
    settings.GAMIFICATION_RANKS_JSON = ranks_path
    settings.GAMIFICATION_ACHIEVEMENTS_JSON = achievements_path

    gm = GameManager()

    # До решения первой задачи
    assert gm.users["1"]["points"] == 0
    assert gm.users["1"]["rank"] == 1
    assert gm.users["1"]["achievements"] == []

    # Решаем задачу уровня 3
    gm.update_user_after_task("1", 3)
    assert gm.users["1"]["points"] == 3
    assert gm.users["1"]["rank"] == 1  # порог для rank=2 = 5

    # Решаем задачу уровня 2
    gm.update_user_after_task("1", 2)  # points: 3+2 = 5
    assert gm.users["1"]["points"] == 5
    assert gm.users["1"]["rank"] == 2
    achs = gm.users["1"]["achievements"]
    assert "Новичок" in achs
    assert "Задачник" in achs

def test_save_users(sample_data):
    users_path, ranks_path, achievements_path = sample_data
    from django.conf import settings
    settings.GAMIFICATION_USERS_JSON = users_path
    settings.GAMIFICATION_RANKS_JSON = ranks_path
    settings.GAMIFICATION_ACHIEVEMENTS_JSON = achievements_path

    gm = GameManager()
    gm.update_user_after_task("1", 1)
    with open(users_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    assert data["1"]["points"] == 1
    assert data["1"]["rank"] == 1
    assert data["1"]["achievements"] == []
EOF

#  — tests/test_achievements.py
cat > tests/test_achievements.py << 'EOF'
from gamification.achievements import check_achievements

def test_check_achievements():
    user = {"points": 10, "tasks_solved": 2}
    ach_list = [
        {"name": "Новичок", "condition_key": "points", "condition_value": 5},
        {"name": "Решил 5 задач", "condition_key": "tasks_solved", "condition_value": 5},
        {"name": "Про100 ед", "condition_key": "points", "condition_value": 100}
    ]
    earned = check_achievements(user, ach_list)
    assert "Новичок" in earned
    assert "Решил 5 задач" not in earned
    assert "Про100 ед" not in earned
EOF

#  — tests/test_other_modules.py (шаблон, дополняйте под свой backend)
cat > tests/test_other_modules.py << 'EOF'
# Здесь вы можете добавить тесты для остальных разделов вашего Django-проекта.
# Например, тестирование backend/utils.py и backend/views.py.
#
# Пример (раскомментируйте и адаптируйте под свою логику):
#
# import json
# from pathlib import Path
# import pytest
# from backend.utils import load_tasks
#
# def test_load_tasks(tmp_path, monkeypatch):
#     # Создаём временный файл tasks.json
#     sample_tasks = [{"id": 1, "level": 1}, {"id": 2, "level": 2}]
#     tasks_file = tmp_path / "tasks.json"
#     tasks_file.write_text(json.dumps(sample_tasks, ensure_ascii=False))
#
#     # Мокаем путь к нему
#     monkeypatch.setenv("DJANGO_SETTINGS_MODULE", "School_Educational_Platform.settings")
#     from django.conf import settings
#     settings.GAMIFICATION_TASKS_JSON = str(tasks_file)
#
#     tasks = load_tasks()
#     assert isinstance(tasks, list)
#     assert tasks[0]["id"] == 1
#     assert tasks[1]["level"] == 2
#
# Далее добавляйте свои тесты:
# - test_user_registration
# - test_solve_task_api
# - test_command_handlers
# и т. д.
EOF

echo "Каталог tests/ и файлы-тесты созданы."
echo

echo "=== 5) Вносим правки в School_Educational_Platform/settings.py ==="
SETTINGS_PATH="School_Educational_Platform/settings.py"

if grep -q "GAMIFICATION_USERS_JSON" "${SETTINGS_PATH}"; then
  echo "- Похоже, что переменные GAMIFICATION_* уже есть в settings.py. Пропускаем этот шаг."
else
  cat >> "${SETTINGS_PATH}" << 'EOF'

# ===== Настройки для модуля геймификации =====
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
GAMIFICATION_USERS_JSON        = os.path.join(BASE_DIR, 'data', 'users.json')
GAMIFICATION_RANKS_JSON        = os.path.join(BASE_DIR, 'data', 'ranks.json')
GAMIFICATION_ACHIEVEMENTS_JSON = os.path.join(BASE_DIR, 'data', 'achievements.json')
GAMIFICATION_TASKS_JSON        = os.path.join(BASE_DIR, 'data', 'tasks.json')
# =============================================
EOF
  echo "- В settings.py добавлены четыре переменные с путями к JSON."
fi

echo
echo "=== Скрипт выполнил основные операции ==="
echo
echo "Теперь вручную поправьте следующие файлы, вставив указанные блоки кода:"
echo

echo "1) backend/utils.py"
echo "   Добавьте (или найдите) функцию get_task_level, например:"
echo "   ---------------------------------------------------------------"
echo "   from django.conf import settings"
echo "   import json"
echo ""
echo "   def get_task_level(task_id):"
echo "       \"\"\"Читает data/tasks.json и возвращает уровень задачи (1, 2 или 3).\"\"\""
echo "       tasks_path = settings.GAMIFICATION_TASKS_JSON"
echo "       with open(tasks_path, 'r', encoding='utf-8') as f:"
echo "           tasks = json.load(f)"
echo "       for t in tasks:"
echo "           if t['id'] == int(task_id):"
echo "               return t['level']"
echo "       return 1  # или бросайте исключение, если не нашли"
echo "   ---------------------------------------------------------------"
echo

echo "2) backend/views.py (или тот файл, где обрабатывается решение задачи)"
echo "   Найдите view (например, solve_task) и добавьте внутри неё после проверки правильности решения:"
echo "   ---------------------------------------------------------------"
echo "   from gamification.gamification import GameManager"
echo "   from backend.utils import get_task_level"
echo ""
echo "   def solve_task(request):"
echo "       user_id = str(request.user.id)"
echo "       task_id = request.POST.get('task_id')"
echo "       # ... ваша логика проверки решения ..."
echo "       success = mark_task_solved(user_id, task_id)"
echo "       if not success:"
echo "           return JsonResponse({'status': 'error'})"
echo ""
echo "       level = get_task_level(task_id)"
echo "       gm = GameManager()"
echo "       gm.update_user_after_task(user_id, level)"
echo ""
echo "       return JsonResponse({"
echo "           'status': 'ok',"
echo "           'points': gm.users[user_id]['points'],"
echo "           'rank': gm.users[user_id]['rank'],"
echo "           'achievements': gm.users[user_id]['achievements']"
echo "       })"
echo "   ---------------------------------------------------------------"
echo

echo "3) Проверьте, что в data/users.json у каждого пользователя есть ключи:"
echo "   'points', 'rank', 'achievements', 'tasks_solved'."
echo

echo "После этого:"
echo "  • Установите зависимости: pip install -r requirements.txt"
echo "  • Запустите тесты: pytest"
echo "  • Запустите сервер: python manage.py runserver"
echo
echo "Готово!"

exit 0
