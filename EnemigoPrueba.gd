extends CharacterBody3D


# =========================================================
# VIDA DEL ENEMIGO
# =========================================================

@export var vida_maxima: int = 100
var vida_actual: int = vida_maxima


# =========================================================
# EXPERIENCIA
# =========================================================

@export var experiencia_otorgada: int = 25


# =========================================================
# MOVIMIENTO Y DETECCIÓN
# =========================================================

@export var velocidad: float = 2.5
@export var distancia_deteccion: float = 8.0
@export var distancia_ataque: float = 2.0


# =========================================================
# ATAQUE DEL ENEMIGO
# =========================================================

@export var dano: int = 10
@export var tiempo_entre_ataques: float = 1.0

var temporizador_ataque: float = 0.0

var heroe: CharacterBody3D
var esta_muerto: bool = false

var gravity: float = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	vida_actual = vida_maxima
	esta_muerto = false

	heroe = get_tree().root.find_child(
		"Heroe",
		true,
		false
	)

	if heroe != null:
		print("ENEMIGO ENCONTRÓ AL HÉROE")
	else:
		print("ENEMIGO NO ENCONTRÓ AL HÉROE")


# =========================================================
# PROCESO
# =========================================================

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return

	if temporizador_ataque > 0.0:
		temporizador_ataque -= delta

	if heroe == null:
		return

	if not is_instance_valid(heroe):
		return

	if heroe.get("esta_muerto") == true:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var distancia: float = global_position.distance_to(
		heroe.global_position
	)

	# =====================================================
	# PERSEGUIR AL HÉROE
	# =====================================================

	if distancia <= distancia_deteccion and distancia > distancia_ataque:
		perseguir_heroe()

	# =====================================================
	# ATACAR
	# =====================================================

	elif distancia <= distancia_ataque:
		velocity.x = 0.0
		velocity.z = 0.0

		atacar_heroe()

	# =====================================================
	# HÉROE FUERA DEL RANGO
	# =====================================================

	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# =====================================================
	# GRAVEDAD
	# =====================================================

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()


# =========================================================
# PERSEGUIR
# =========================================================

func perseguir_heroe() -> void:
	var direccion: Vector3 = (
		heroe.global_position - global_position
	)

	# Solo moverlo sobre el suelo
	direccion.y = 0.0

	if direccion.length() > 0.0:
		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad

		# Hacer que el enemigo mire hacia el héroe
		var objetivo: Vector3 = heroe.global_position
		objetivo.y = global_position.y

		look_at(objetivo, Vector3.UP)


# =========================================================
# ATAQUE
# =========================================================

func atacar_heroe() -> void:
	if esta_muerto:
		return

	if temporizador_ataque > 0.0:
		return

	if heroe == null:
		return

	if not is_instance_valid(heroe):
		return

	if heroe.get("esta_muerto") == true:
		return

	if heroe.has_method("recibir_dano"):
		print("ENEMIGO ATACA AL HÉROE")

		heroe.recibir_dano(dano)

		temporizador_ataque = tiempo_entre_ataques


# =========================================================
# RECIBIR DAÑO
# =========================================================

func recibir_dano(cantidad: int) -> void:
	if esta_muerto:
		return

	vida_actual -= cantidad

	if vida_actual < 0:
		vida_actual = 0

	print(
		"ENEMIGO RECIBE %d DE DANO. VIDA: %d"
		% [cantidad, vida_actual]
	)

	if vida_actual <= 0:
		morir()


# =========================================================
# MUERTE
# =========================================================

func morir() -> void:
	if esta_muerto:
		return

	esta_muerto = true
	vida_actual = 0

	print("ENEMIGO DERROTADO")

	if heroe != null:
		if is_instance_valid(heroe):
			if heroe.has_method("recibir_experiencia"):
				heroe.recibir_experiencia(
					experiencia_otorgada
				)

	queue_free()