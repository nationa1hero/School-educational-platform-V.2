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
