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
