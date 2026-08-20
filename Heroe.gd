extends CharacterBody3D

@export var move_speed: float = 5.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera: Camera3D = get_viewport().get_camera_3d()


func _physics_process(delta: float) -> void:
	var move_dir := Vector3.ZERO

	if camera != null:
		var cam_forward := -camera.global_basis.z
		var cam_right := camera.global_basis.x

		# Ignoramos la inclinación vertical de la cámara.
		cam_forward.y = 0.0
		cam_right.y = 0.0

		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()

		if Input.is_physical_key_pressed(KEY_W):
			move_dir += cam_forward

		if Input.is_physical_key_pressed(KEY_S):
			move_dir -= cam_forward

		if Input.is_physical_key_pressed(KEY_A):
			move_dir -= cam_right

		if Input.is_physical_key_pressed(KEY_D):
			move_dir += cam_right

	else:
		# Movimiento básico de respaldo si no se encuentra la cámara.
		if Input.is_physical_key_pressed(KEY_W):
			move_dir.z -= 1.0

		if Input.is_physical_key_pressed(KEY_S):
			move_dir.z += 1.0

		if Input.is_physical_key_pressed(KEY_A):
			move_dir.x -= 1.0

		if Input.is_physical_key_pressed(KEY_D):
			move_dir.x += 1.0

	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()

	velocity.x = move_dir.x * move_speed
	velocity.z = move_dir.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()
