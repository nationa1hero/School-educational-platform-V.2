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
