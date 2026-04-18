extends CanvasLayer

@onready var scrap_bar: TextureProgressBar = $ScrapBar/ProgressBar
@onready var level_label: Label = $ScrapBar/LevelDisplay/LevelLabel
@onready var power_label: Label = $HealthBar/PowerDisplay/PowerLabel

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.stats_changed.connect(_on_player_stats_changed)

func _on_player_stats_changed(current_scrap, goal_scrap, level, power) -> void:
	scrap_bar.max_value = goal_scrap
	scrap_bar.value = current_scrap
	level_label.text = "LVL " + str(level)
	power_label.text = str(power)
