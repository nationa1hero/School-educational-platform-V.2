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
