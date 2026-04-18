extends Control

@onready var fill_bg = $LargeCircleBG

@export_range(0.0, 1.0) var durability: float = 1.0:
	set(value):
		durability = clamp(value, 0.0, 1.0)
		if fill_bg.material is ShaderMaterial:
			fill_bg.material.set_shader_parameter("fill_level", durability)

func _ready():
	if fill_bg.material is ShaderMaterial:
		fill_bg.material.set_shader_parameter("fill_level", durability)
