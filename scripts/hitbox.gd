extends Area2D
class_name Hitbox

func take_damage(damage: int) -> void:
	get_parent().take_damage(damage)
