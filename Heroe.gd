extends CharacterBody3D

@export var move_speed: float = 5.0
@export var attack_cooldown: float = 0.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack_timer: float = 0.0

@onready var camera: Camera3D = get_viewport().get_camera_3d()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if attack_timer <= 0.0:
				print("ATAQUE")
				attack_timer = attack_cooldown

				var area_ataque: Area3D = get_node_or_null("AreaAtaque")

				if area_ataque != null:
					for body in area_ataque.get_overlapping_bodies():
						if body.name == "EnemigoPrueba":
							print("GOLPE A ENEMIGO")

							if body.has_method("recibir_dano"):
								body.recibir_dano(20)


func _physics_process(delta: float) -> void:
	var move_dir := Vector3.ZERO

	if camera != null:
		var cam_forward := -camera.global_basis.z
		var cam_right := camera.global_basis.x

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

	if attack_timer > 0.0:
		attack_timer -= delta
