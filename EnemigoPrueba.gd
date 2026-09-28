extends CharacterBody3D


# =========================================================
# ESTADÍSTICAS DEL ENEMIGO
# =========================================================

@export var vida_maxima: int = 100
@export var ataque_base: int = 10

@export var velocidad_movimiento: float = 2.5
@export var distancia_deteccion: float = 7.0
@export var distancia_maxima_persecucion: float = 12.0
@export var distancia_ataque: float = 1.8
@export var tiempo_entre_ataques: float = 1.0

@export var tiempo_respawn: float = 5.0


# =========================================================
# DROP ANTIGUO - COMPATIBILIDAD
# =========================================================

@export var drop_fragmento: PackedScene = preload(
	"res://FragmentoEsencia.tscn"
)


# =========================================================
# SISTEMA UNIVERSAL DE DROPS
# =========================================================

@onready var sistema_drops: Node = get_node_or_null(
	"SistemaDrops"
)


# =========================================================
# VIDA
# =========================================================

var vida_actual: int
var esta_muerto: bool = false


# =========================================================
# REFERENCIAS
# =========================================================

var heroe: CharacterBody3D = null

@onready var vida_label: Label3D = $VidaLabel
@onready var barra_vida: ProgressBar = $ViewportVida/BarraVida


# =========================================================
# MOVIMIENTO / IA
# =========================================================

var posicion_inicial: Vector3
var tiempo_ataque: float = 0.0


enum Estado {
	QUIETO,
	PERSIGUIENDO,
	REGRESANDO
}


var estado_actual: Estado = Estado.QUIETO


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	vida_actual = vida_maxima

	posicion_inicial = global_position

	configurar_interfaz_vida()
	actualizar_interfaz_vida()

	print("ENEMIGO CARGADO")
	print("POSICIÓN INICIAL:", posicion_inicial)

	if sistema_drops != null:
		print("SISTEMA UNIVERSAL DE DROPS ACTIVADO")


# =========================================================
# CONFIGURAR INTERFAZ DE VIDA
# =========================================================

func configurar_interfaz_vida() -> void:

	if barra_vida != null:

		barra_vida.min_value = 0
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual


# =========================================================
# ACTUALIZAR VIDA VISUAL
# =========================================================

func actualizar_interfaz_vida() -> void:

	if vida_label != null:

		vida_label.text = "%d / %d" % [
			vida_actual,
			vida_maxima
		]

	if barra_vida != null:

		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual


# =========================================================
# PROCESO PRINCIPAL
# =========================================================

func _physics_process(delta: float) -> void:

	if esta_muerto:

		velocity = Vector3.ZERO
		return

	if tiempo_ataque > 0:

		tiempo_ataque -= delta

	if heroe == null:

		buscar_heroe()

	if heroe == null:

		velocity = Vector3.ZERO
		return

	var distancia_heroe: float = global_position.distance_to(
		heroe.global_position
	)

	var distancia_origen: float = global_position.distance_to(
		posicion_inicial
	)

	match estado_actual:

		# =================================================
		# QUIETO
		# =================================================

		Estado.QUIETO:

			velocity = Vector3.ZERO

			# IGNORAR HÉROE EN ZONA SEGURA

			if heroe.has_method("esta_en_zona_segura"):

				if heroe.esta_en_zona_segura():

					return

			# DETECTAR HÉROE

			if distancia_heroe <= distancia_deteccion:

				estado_actual = Estado.PERSIGUIENDO

				print("ENEMIGO DETECTÓ AL HÉROE")


		# =================================================
		# PERSIGUIENDO
		# =================================================

		Estado.PERSIGUIENDO:

			# HÉROE EN ZONA SEGURA

			if heroe.has_method("esta_en_zona_segura"):

				if heroe.esta_en_zona_segura():

					estado_actual = Estado.REGRESANDO
					velocity = Vector3.ZERO

					print("HÉROE EN ZONA SEGURA")
					print("ENEMIGO REGRESA A SU ZONA")

					return

			# LÍMITE DE PERSECUCIÓN

			if distancia_origen >= distancia_maxima_persecucion:

				estado_actual = Estado.REGRESANDO
				velocity = Vector3.ZERO

				print("ENEMIGO REGRESA A SU ZONA")

				return

			# PERSEGUIR O ATACAR

			if distancia_heroe > distancia_ataque:

				mover_hacia_heroe()

			else:

				velocity = Vector3.ZERO

				atacar_heroe()


		# =================================================
		# REGRESANDO
		# =================================================

		Estado.REGRESANDO:

			var distancia_a_inicio: float = global_position.distance_to(
				posicion_inicial
			)

			if distancia_a_inicio <= 0.3:

				global_position = posicion_inicial
				velocity = Vector3.ZERO

				estado_actual = Estado.QUIETO

				print("ENEMIGO VOLVIÓ A SU POSICIÓN")

			else:

				mover_hacia_posicion(posicion_inicial)

	move_and_slide()


# =========================================================
# BUSCAR HÉROE
# =========================================================

func buscar_heroe() -> void:

	var posibles_heroes = get_tree().get_nodes_in_group(
		"heroe"
	)

	if posibles_heroes.size() > 0:

		heroe = posibles_heroes[0] as CharacterBody3D


# =========================================================
# MOVER HACIA EL HÉROE
# =========================================================

func mover_hacia_heroe() -> void:

	if heroe == null:
		return

	var direccion: Vector3 = (
		heroe.global_position - global_position
	)

	direccion.y = 0

	if direccion.length() <= 0.001:

		velocity = Vector3.ZERO
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * velocidad_movimiento
	velocity.z = direccion.z * velocidad_movimiento

	look_at(
		Vector3(
			heroe.global_position.x,
			global_position.y,
			heroe.global_position.z
		),
		Vector3.UP
	)


# =========================================================
# MOVER HACIA UNA POSICIÓN
# =========================================================

func mover_hacia_posicion(destino: Vector3) -> void:

	var direccion: Vector3 = destino - global_position

	direccion.y = 0

	if direccion.length() <= 0.001:

		velocity = Vector3.ZERO
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * velocidad_movimiento
	velocity.z = direccion.z * velocidad_movimiento


# =========================================================
# ATAQUE DEL ENEMIGO
# =========================================================

func atacar_heroe() -> void:

	if tiempo_ataque > 0:
		return

	if heroe == null:
		return

	if not heroe.has_method("recibir_dano"):
		return

	if heroe.has_method("esta_en_zona_segura"):

		if heroe.esta_en_zona_segura():

			print(
				"ATAQUE BLOQUEADO: HÉROE EN ZONA SEGURA"
			)

			estado_actual = Estado.REGRESANDO

			return

	heroe.recibir_dano(ataque_base)

	tiempo_ataque = tiempo_entre_ataques


# =========================================================
# RECIBIR DAÑO
# =========================================================

func recibir_dano(cantidad: int) -> void:

	if esta_muerto:
		return

	vida_actual -= cantidad

	if vida_actual < 0:

		vida_actual = 0

	actualizar_interfaz_vida()

	if vida_actual <= 0:

		morir()


# =========================================================
# CREAR DROPS
# =========================================================

func crear_drop() -> void:

	# -----------------------------------------------------
	# NUEVO SISTEMA UNIVERSAL
	# -----------------------------------------------------

	if sistema_drops != null:

		if sistema_drops.has_method("generar_drops"):

			sistema_drops.generar_drops(
				global_position
			)

			print("==============================")
			print("DROPS UNIVERSALES GENERADOS")
			print("ENEMIGO:", name)
			print("==============================")

			return

	# -----------------------------------------------------
	# SISTEMA ANTIGUO
	# -----------------------------------------------------

	if drop_fragmento == null:
		return

	var fragmento = drop_fragmento.instantiate()

	var contenedor_drops = get_tree().current_scene

	if contenedor_drops == null:

		fragmento.free()
		return

	contenedor_drops.add_child(fragmento)

	fragmento.global_position = global_position

	print("==============================")
	print("DROP ANTIGUO GENERADO")
	print("ENEMIGO:", name)
	print("==============================")


# =========================================================
# MUERTE
# =========================================================

func morir() -> void:

	if esta_muerto:
		return

	esta_muerto = true

	velocity = Vector3.ZERO

	print("ENEMIGO DERROTADO")

	# -----------------------------------------------------
	# CREAR RECOMPENSAS
	# -----------------------------------------------------

	crear_drop()

	# -----------------------------------------------------
	# DAR EXPERIENCIA
	# -----------------------------------------------------

	if heroe != null:

		if heroe.has_method("ganar_experiencia"):

			heroe.ganar_experiencia(100)

	print(
		"ENEMIGO REAPARECERÁ EN %.1f SEGUNDOS"
		% tiempo_respawn
	)

	# -----------------------------------------------------
	# OCULTAR ENEMIGO
	# -----------------------------------------------------

	visible = false

	# -----------------------------------------------------
	# DESACTIVAR COLISIONES
	# -----------------------------------------------------

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# -----------------------------------------------------
	# ESPERAR REAPARICIÓN
	# -----------------------------------------------------

	await get_tree().create_timer(
		tiempo_respawn
	).timeout

	reaparecer()


# =========================================================
# REAPARECER
# =========================================================

func reaparecer() -> void:

	global_position = posicion_inicial

	vida_actual = vida_maxima

	tiempo_ataque = 0.0

	estado_actual = Estado.QUIETO

	esta_muerto = false

	actualizar_interfaz_vida()

	# -----------------------------------------------------
	# MOSTRAR ENEMIGO
	# -----------------------------------------------------

	visible = true

	# -----------------------------------------------------
	# REACTIVAR COLISIONES
	# -----------------------------------------------------

	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)

	print("==============================")
	print("ENEMIGO REAPARECIÓ")
	print(
		"VIDA: %d/%d" % [
			vida_actual,
			vida_maxima
		]
	)
	print("POSICIÓN:", global_position)
	print("==============================")