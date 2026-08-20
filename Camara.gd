extends Camera3D

@export var target_path: NodePath = NodePath("../Heroe")
@export var offset: Vector3 = Vector3(5.0, 7.0, 5.0)

@onready var target: Node3D = get_node_or_null(target_path) as Node3D

func _ready() -> void:
	make_current()

func _process(_delta: float) -> void:
	if target == null:
		return

	global_position = target.global_position + offset
	look_at(target.global_position, Vector3.UP)