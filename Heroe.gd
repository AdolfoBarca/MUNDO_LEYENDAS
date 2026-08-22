extends CharacterBody3D

@export var move_speed: float = 5.0
@export var attack_cooldown: float = 0.5

@export var color_piel: Color = Color("#C98F65")
@export var color_camisa: Color = Color("#244A73")
@export var color_pantalon: Color = Color("#2F3540")


# =========================================================
# VIDA DEL HÉROE
# =========================================================

@export var vida_maxima: int = 100
@export var regeneracion_por_segundo: int = 2
@export var espera_para_regenerar: float = 5.0

var vida_actual: int
var esta_muerto: bool = false

var temporizador_regeneracion: float = 0.0
var tiempo_desde_ultimo_dano: float = 0.0


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

@onready var barra_vida: ProgressBar = get_node("../Interfaz/BarraVida")
@onready var texto_vida: Label = get_node("../Interfaz/TextoVida")


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	vida_actual = vida_maxima
	esta_muerto = false

	temporizador_regeneracion = 0.0
	tiempo_desde_ultimo_dano = espera_para_regenerar

	color_piel = DatosJugador.color_piel
	color_camisa = DatosJugador.color_camisa
	color_pantalon = DatosJugador.color_pantalon

	aplicar_colores_personaje()

	if nombre_label != null:
		nombre_label.text = DatosJugador.nombre

	actualizar_interfaz_vida()

	print("==============================")
	print("HÉROE CARGADO EN EL MAPA")
	print("Nombre: ", DatosJugador.nombre)
	print("País: ", DatosJugador.pais)
	print("Vida: ", vida_actual, "/", vida_maxima)
	print("==============================")


# =========================================================
# VIDA
# =========================================================

func recibir_dano(cantidad: int) -> void:
	if esta_muerto:
		return

	vida_actual -= cantidad

	if vida_actual < 0:
		vida_actual = 0

	# Reiniciar la espera de regeneración
	tiempo_desde_ultimo_dano = 0.0
	temporizador_regeneracion = 0.0

	actualizar_interfaz_vida()

	print("HÉROE RECIBE ", cantidad, " DE DAÑO")
	print("VIDA: ", vida_actual, "/", vida_maxima)

	if vida_actual <= 0:
		morir()


func regenerar_vida(delta: float) -> void:
	if esta_muerto:
		return

	if vida_actual >= vida_maxima:
		return

	# Contar cuánto tiempo ha pasado desde el último golpe
	tiempo_desde_ultimo_dano += delta

	# Todavía no han pasado los segundos necesarios
	if tiempo_desde_ultimo_dano < espera_para_regenerar:
		return

	# Después de la espera, regenerar cada segundo
	temporizador_regeneracion += delta

	if temporizador_regeneracion >= 1.0:
		vida_actual += regeneracion_por_segundo

		if vida_actual > vida_maxima:
			vida_actual = vida_maxima

		actualizar_interfaz_vida()

		print(
			"HÉROE REGENERA ",
			regeneracion_por_segundo,
			" DE VIDA. VIDA: ",
			vida_actual,
			"/",
			vida_maxima
		)

		temporizador_regeneracion = 0.0


func actualizar_interfaz_vida() -> void:
	if barra_vida != null:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual

	if texto_vida != null:
		texto_vida.text = "%s   %d / %d" % [
			DatosJugador.nombre,
			vida_actual,
			vida_maxima
		]


func morir() -> void:
	if esta_muerto:
		return

	esta_muerto = true
	vida_actual = 0

	actualizar_interfaz_vida()

	print("==============================")
	print("HÉROE DERROTADO")
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
	if esta_muerto:
		return

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
	if esta_muerto:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	regenerar_vida(delta)

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