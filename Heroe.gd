extends CharacterBody3D

@export var move_speed: float = 5.0
@export var attack_cooldown: float = 0.5

@export var color_piel: Color = Color("#C98F65")
@export var color_camisa: Color = Color("#244A73")
@export var color_pantalon: Color = Color("#2F3540")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var attack_timer: float = 0.0


# =========================================================
# NODOS
# =========================================================

@onready var camera: Camera3D = get_viewport().get_camera_3d()

@onready var cabeza: MeshInstance3D = $Cabeza
@onready var brazo_izquierdo: MeshInstance3D = $BrazoIzquierdo
@onready var brazo_derecho: MeshInstance3D = $BrazoDerecho

@onready var cuerpo: MeshInstance3D = $Cuerpo

@onready var pierna_izquierda: MeshInstance3D = $PiernaIzquierda
@onready var pierna_derecha: MeshInstance3D = $PiernaDerecha

@onready var nombre_label: Label3D = $NombreHeroe


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	# Cargar la apariencia elegida en CrearHeroe
	color_piel = DatosJugador.color_piel
	color_camisa = DatosJugador.color_camisa
	color_pantalon = DatosJugador.color_pantalon

	aplicar_colores_personaje()

	# Mostrar el nombre elegido sobre el héroe
	if nombre_label != null:
		nombre_label.text = DatosJugador.nombre

	print("==============================")
	print("HÉROE CARGADO EN EL MAPA")
	print("Nombre: ", DatosJugador.nombre)
	print("País: ", DatosJugador.pais)
	print("==============================")


# =========================================================
# APLICAR APARIENCIA
# =========================================================

func aplicar_colores_personaje() -> void:
	aplicar_color_piel()
	aplicar_color_camisa()
	aplicar_color_pantalon()


func aplicar_color_piel() -> void:
	var partes_piel = [
		cabeza,
		brazo_izquierdo,
		brazo_derecho
	]

	for parte in partes_piel:
		if parte != null:
			var material = parte.get_surface_override_material(0)

			if material != null:
				material.albedo_color = color_piel


func aplicar_color_camisa() -> void:
	if cuerpo != null:
		var material = cuerpo.get_surface_override_material(0)

		if material != null:
			material.albedo_color = color_camisa


func aplicar_color_pantalon() -> void:
	var piernas = [
		pierna_izquierda,
		pierna_derecha
	]

	for pierna in piernas:
		if pierna != null:
			var material = pierna.get_surface_override_material(0)

			if material != null:
				material.albedo_color = color_pantalon


# =========================================================
# ATAQUE
# =========================================================

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


# =========================================================
# MOVIMIENTO
# =========================================================

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