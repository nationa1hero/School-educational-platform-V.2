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
