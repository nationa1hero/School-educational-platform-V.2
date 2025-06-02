# School Educational Platform V.2

**Учебная платформа с модулем геймификации**

---

## Описание

Проект представляет собой расширенную версию Django-приложения для образовательной платформы, в котором добавлен модуль геймификации. Цель геймификации — мотивировать пользователей решать больше задач, отслеживать прогресс и получать достижения.

Основные компоненты проекта:
- **Django-бэкенд** (`backend/`) с основными моделями, представлениями и утилитами.
- **Модуль геймификации** (`gamification/`) с классом `GameManager`.
- **JSON-файлы** (`data/`) для хранения задач, пользователей, достижений и порогов рангов.
- **Тесты** (`tests/`) для проверки логики геймификации и других частей приложения.

---

## Клонирование и установка

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/nationa1hero/School-educational-platform-V.2.git
   ```
2. Перейдите в папку проекта:
   ```bash
   cd School-educational-platform-V.2/School_Diplom
   ```
3. Создайте и активируйте виртуальное окружение (рекомендуется Python 3.9+):
   ```bash
   python -m venv venv
   source venv/bin/activate   # Linux/macOS
   venv\Scripts\activate      # Windows (Git Bash или CMD)
   ```
4. Установите зависимости:
   ```bash
   pip install -r requirements.txt
   ```
5. Проверьте настройки в `School_Diplom/settings.py`. В конце файла должны быть переменные:
   ```python
   GAMIFICATION_USERS_JSON        = os.path.join(BASE_DIR, 'data', 'users.json')
   GAMIFICATION_RANKS_JSON        = os.path.join(BASE_DIR, 'data', 'ranks.json')
   GAMIFICATION_ACHIEVEMENTS_JSON = os.path.join(BASE_DIR, 'data', 'achievements.json')
   GAMIFICATION_TASKS_JSON        = os.path.join(BASE_DIR, 'data', 'tasks.json')
   ```

---

## Структура проекта

```
School-educational-platform-V.2/
└── School_Diplom/
    ├── backend/                  # Основное Django-приложение
    │   ├── migrations/
    │   ├── static/
    │   ├── template/
    │   ├── __init__.py
    │   ├── admin.py
    │   ├── apps.py
    │   ├── forms.py
    │   ├── models.py
    │   ├── utils.py             # Утилиты, включая get_task_level()
    │   └── views.py             # Представления, включая solve_task
    ├── data/                     # JSON-хранилища для геймификации
    │   ├── tasks.json            # Список всех задач {id, level}
    │   ├── users.json            # Данные пользователей {points, rank, achievements, tasks_solved}
    │   ├── achievements.json     # Список достижений с условиями
    │   └── ranks.json            # Пороги для рангов
    ├── gamification/             # Код модуля геймификации
    │   ├── __init__.py
    │   ├── gamification.py       # GameManager: начисление очков, ранги, достижения
    │   └── achievements.py       # Проверка условий для достижений
    ├── tests/                    # Юнит-тесты
    │   ├── test_gamification.py
    │   ├── test_achievements.py
    │   └── test_other_modules.py
    ├── School_Diplom/            # Файлы конфигурации Django
    │   ├── __init__.py
    │   ├── asgi.py
    │   ├── settings.py
    │   ├── urls.py
    │   └── wsgi.py
    ├── manage.py                 # Точка входа Django
    └── README.md                 # Этот файл
```

---

## Модуль геймификации

- **GameManager** (`gamification/gamification.py`):
  - Загружает `data/users.json`, `data/ranks.json`, `data/achievements.json`.
  - Метод `calculate_points(level: int) → int` возвращает 1, 2 или 3 очка.
  - Метод `_get_next_rank(points: int) → int` вычисляет текущий ранг по порогам.
  - Метод `update_user_after_task(user_id: str, task_level: int)`:
    1. Увеличивает `tasks_solved` у пользователя.
    2. Начисляет очки за уровень задачи.
    3. Пересчитывает ранг (по `ranks.json`).
    4. Пересчитывает достижения (по `achievements.json`).
    5. Сохраняет обновлённый `users.json`.

- **Achievements** (`gamification/achievements.py`):
  - Функция `check_achievements(user: dict, achievements_list: list) → list[str]`.
  - Проходит по каждому достижению и проверяет `"user[condition_key] >= condition_value"`.

- **JSON-файлы** (`data/`):
  - `tasks.json`: массив объектов `{ "id": N, "level": 1|2|3 }` (368 записей).
  - `users.json`: словарь вида `{ "1": { "name": "...", "points": 0, "rank": 1, "achievements": [], "tasks_solved": 0 }, ... }`.
  - `achievements.json`: массив `{ "name": "...", "condition_key": "points|tasks_solved|rank", "condition_value": X }` (30 записей).
  - `ranks.json`: словарь `{ "1": 0, "2": 50, "3": 120, ..., "30": 18150 }` (30 порогов).

---

## Установка и запуск

1. **Миграции:**  
   > В данном проекте нет новых моделей — геймификация хранит данные в JSON.  
   Если вы добавляли модели в `backend/models.py`, выполните:
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

2. **Тестирование:**  
   Запустите все юнит-тесты:
   ```bash
   pytest
   ```
   Ожидается, что все тесты (`test_gamification.py`, `test_achievements.py` и `test_other_modules.py`) пройдут без ошибок.

3. **Запуск дев-сервера:**  
   ```bash
   python manage.py runserver
   ```
   Сервер запустится по адресу http://127.0.0.1:8000/.

4. **Ручная проверка геймификации:**  
   - Авторизуйтесь под пользователем, чей `id` присутствует в `data/users.json`.  
   - Отправьте POST-запрос на эндпоинт `/backend/solve_task/`:
     ```
     POST http://127.0.0.1:8000/backend/solve_task/
     Content-Type: application/x-www-form-urlencoded
     Body: task_id=<номер_задачи>
     ```
   - В ответе вернётся JSON:
     ```json
     {
       "status": "ok",
       "points": <новое_количество_очков>,
       "rank": <текущий_ранг>,
       "achievements": [ "...список достижений..." ]
     }
     ```
   - Проверьте, что файл `data/users.json` обновился (изменились поля `points`, `rank`, `achievements`, `tasks_solved`).

---

## Пример продвинутого использования

- **Добавление новых достижений:**  
  В `data/achievements.json` добавьте объект:
  ```json
  {
    "name": "Эксперт",
    "condition_key": "points",
    "condition_value": 1000
  }
  ```
  При следующем вызове `update_user_after_task()` пользователь, набравший ≥ 1000 очков, автоматически получит достижение «Эксперт».

- **Изменение порогов рангов:**  
  В `data/ranks.json` измените значение:
  ```json
  "10": 1650,   →   "10": 1200
  ```
  Тогда для достижения 10-го ранга потребуется ≥ 1200 очков (вместо 1650).

- **Расширение логики достижений:**  
  В функции `check_achievements` можно добавить дополнительные ключи (`condition_key`), например `"streak_days"`, `"olymp_wins"` и т. д. Просто убедитесь, что в `data/users.json` у каждого пользователя есть соответствующие поля, и они обновляются в `GameManager.update_user_after_task` или в другом месте.

---

## Полезные команды Git

```bash
# 1) Переходим в папку проекта (где лежит manage.py)
cd "/c/Users/User/Desktop/универ/Диплом/School-educational-platform-V.2/School_Diplom"

# 2) Проверяем статус git
git status

# 3) Добавляем все изменения
git add .

# 4) Делаем коммит
git commit -m "Интеграция геймификации: добавлены data/, gamification/, tests/, обновлены файлы"

# 5) Отправляем сразу в ветку master (или main)
git push origin master
```

---

## Лицензия

В проекте пока не указан файл лицензии. При необходимости добавьте `LICENSE` с требуемыми условиями распространения.
