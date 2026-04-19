extends CanvasLayer

@onready var scrap_bar: TextureProgressBar = $ScrapBar/ProgressBar
@onready var level_label: Label = $ScrapBar/LevelDisplay/LevelLabel
@onready var power_label: Label = $HealthBar/PowerDisplay/PowerLabel
@onready var bulbs_node: HBoxContainer = $HealthBar/Bulbs
@onready var bulbs: Array = bulbs_node.get_children().filter(func(node): return node is LightBulbUI)

var prev_health: int = 5

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.stats_changed.connect(_on_player_stats_changed)

func _on_player_stats_changed(current_scrap, goal_scrap, level, L_power, R_power, health) -> void:
	scrap_bar.max_value = goal_scrap
	scrap_bar.value = current_scrap
	level_label.text = "LVL " + str(level)
	#power_label.text = str(power)
	if health < prev_health:
		turn_off_health_bulbs(prev_health, health)
	prev_health = health

func turn_off_health_bulbs(prev_health: int, current_health: int) -> void:
	if current_health <= 0: return
	for idx in range(current_health, prev_health):
		if idx < bulbs.size():
			var tw = bulbs[-1-idx].set_active(false)
			if tw: await tw.finished
