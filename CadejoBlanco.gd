extends CharacterBody3D

# =========================================================
# CADEJO BLANCO - COMPAÑERO PROTECTOR
# =========================================================

# ---------------------------------------------------------
# SEGUIMIENTO DEL HÉROE
# ---------------------------------------------------------

@export var velocidad: float = 4.8
@export var distancia_seguimiento: float = 2.4
@export var distancia_maxima: float = 14.0
@export var suavidad_giro: float = 8.0


# ---------------------------------------------------------
# COMBATE
# ---------------------------------------------------------

@export var dano_ataque: int = 15
@export var distancia_deteccion_enemigo: float = 7.0
@export var distancia_ataque: float = 1.5
@export var tiempo_entre_ataques: float = 1.2

# El Cadejo no perseguirá enemigos demasiado lejos del héroe.
@export var distancia_maxima_combate_heroe: float = 10.0


# ---------------------------------------------------------
# REFERENCIAS
# ---------------------------------------------------------

var heroe: Node3D = null
var enemigo_objetivo: Node3D = null

var gravity: float = ProjectSettings.get_setting(
	"physics/3d/default_gravity"
)

var tiempo_ataque: float = 0.0


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	print("==============================")
	print("CADEJO BLANCO LISTO")
	print("Estado: compañero protector")
	print("Daño: ", dano_ataque)
	print("==============================")


func asignar_heroe(nuevo_heroe: Node3D) -> void:
	heroe = nuevo_heroe


# =========================================================
# PROCESO PRINCIPAL
# =========================================================

func _physics_process(delta: float) -> void:

	if tiempo_ataque > 0.0:
		tiempo_ataque = maxf(
			0.0,
			tiempo_ataque - delta
		)

	if not is_instance_valid(heroe):
		enemigo_objetivo = null
		velocity = Vector3.ZERO

		aplicar_gravedad(delta)
		move_and_slide()
		return


	# -----------------------------------------------------
	# TELETRANSPORTE DE SEGURIDAD
	# -----------------------------------------------------

	var distancia_total: float = global_position.distance_to(
		heroe.global_position
	)

	if distancia_total > distancia_maxima:
		global_position = (
			heroe.global_position
			+ Vector3(1.8, 0.2, 1.8)
		)

		enemigo_objetivo = null
		velocity = Vector3.ZERO
		return


	# -----------------------------------------------------
	# VALIDAR OBJETIVO ACTUAL
	# -----------------------------------------------------

	if not objetivo_es_valido(enemigo_objetivo):
		enemigo_objetivo = null


	# -----------------------------------------------------
	# BUSCAR ENEMIGO
	# -----------------------------------------------------

	if enemigo_objetivo == null:
		enemigo_objetivo = buscar_enemigo_cercano()


	# -----------------------------------------------------
	# COMBATIR O SEGUIR
	# -----------------------------------------------------

	if enemigo_objetivo != null:
		procesar_combate()
	else:
		seguir_heroe()


	aplicar_gravedad(delta)
	move_and_slide()


# =========================================================
# BUSCAR ENEMIGO CERCANO
# =========================================================

func buscar_enemigo_cercano() -> Node3D:

	if not is_instance_valid(heroe):
		return null

	var mejor_enemigo: Node3D = null
	var mejor_distancia: float = INF

	var escena_actual := get_tree().current_scene

	if escena_actual == null:
		return null

	var candidatos: Array[Node] = []

	_recolectar_enemigos(
		escena_actual,
		candidatos
	)

	for candidato in candidatos:

		if not objetivo_es_valido(candidato):
			continue

		var enemigo := candidato as Node3D

		var distancia_al_heroe: float = (
			enemigo.global_position.distance_to(
				heroe.global_position
			)
		)

		# Solo defender al héroe de enemigos cercanos.
		if distancia_al_heroe > distancia_deteccion_enemigo:
			continue

		var distancia_al_cadejo: float = (
			global_position.distance_to(
				enemigo.global_position
			)
		)

		if distancia_al_cadejo < mejor_distancia:
			mejor_distancia = distancia_al_cadejo
			mejor_enemigo = enemigo

	return mejor_enemigo


# =========================================================
# RECOLECTAR POSIBLES ENEMIGOS
# =========================================================

func _recolectar_enemigos(
	nodo: Node,
	resultado: Array[Node]
) -> void:

	for hijo in nodo.get_children():

		# -------------------------------------------------
		# NUNCA considerar al héroe como enemigo.
		# -------------------------------------------------

		if hijo == heroe:
			_recolectar_enemigos(
				hijo,
				resultado
			)
			continue


		# -------------------------------------------------
		# NUNCA considerar al propio Cadejo.
		# -------------------------------------------------

		if hijo == self:
			continue


		# -------------------------------------------------
		# POSIBLE ENEMIGO
		# -------------------------------------------------

		if (
			hijo is Node3D
			and hijo.has_method("recibir_dano")
			and "esta_muerto" in hijo
		):
			resultado.append(hijo)


		_recolectar_enemigos(
			hijo,
			resultado
		)


# =========================================================
# VALIDAR OBJETIVO
# =========================================================

func objetivo_es_valido(objetivo: Node) -> bool:

	if not is_instance_valid(objetivo):
		return false


	# -----------------------------------------------------
	# PROTECCIÓN ABSOLUTA DEL HÉROE
	# -----------------------------------------------------

	if objetivo == heroe:
		return false


	# -----------------------------------------------------
	# EL CADEJO TAMPOCO PUEDE ATACARSE A SÍ MISMO
	# -----------------------------------------------------

	if objetivo == self:
		return false


	# -----------------------------------------------------
	# NO ATACAR NODOS DEL GRUPO HÉROE
	# -----------------------------------------------------

	if objetivo.is_in_group("heroe"):
		return false


	if not objetivo is Node3D:
		return false


	if not objetivo.has_method("recibir_dano"):
		return false


	if not ("esta_muerto" in objetivo):
		return false


	if objetivo.esta_muerto:
		return false


	if not objetivo.visible:
		return false


	return true


# =========================================================
# COMBATE
# =========================================================

func procesar_combate() -> void:

	if not objetivo_es_valido(enemigo_objetivo):
		enemigo_objetivo = null
		return

	var enemigo := enemigo_objetivo as Node3D


	# -----------------------------------------------------
	# NO ALEJARSE DEMASIADO DEL HÉROE
	# -----------------------------------------------------

	var distancia_enemigo_heroe: float = (
		enemigo.global_position.distance_to(
			heroe.global_position
		)
	)

	if distancia_enemigo_heroe > distancia_maxima_combate_heroe:

		print(
			"CADEJO BLANCO ABANDONA OBJETIVO: "
			+ "demasiado lejos del héroe"
		)

		enemigo_objetivo = null

		velocity.x = 0.0
		velocity.z = 0.0

		return


	# -----------------------------------------------------
	# DISTANCIA AL ENEMIGO
	# -----------------------------------------------------

	var direccion: Vector3 = (
		enemigo.global_position
		- global_position
	)

	direccion.y = 0.0

	var distancia: float = direccion.length()


	# -----------------------------------------------------
	# PERSEGUIR ENEMIGO
	# -----------------------------------------------------

	if distancia > distancia_ataque:

		if distancia > 0.001:

			direccion = direccion.normalized()

			velocity.x = direccion.x * velocidad
			velocity.z = direccion.z * velocidad

			mirar_direccion(direccion)

		return


	# -----------------------------------------------------
	# ATACAR
	# -----------------------------------------------------

	velocity.x = 0.0
	velocity.z = 0.0

	if distancia > 0.001:
		mirar_direccion(
			direccion.normalized()
		)

	atacar_enemigo()


# =========================================================
# ATAQUE DEL CADEJO
# =========================================================

func atacar_enemigo() -> void:

	if tiempo_ataque > 0.0:
		return


	if not objetivo_es_valido(enemigo_objetivo):
		enemigo_objetivo = null
		return


	# Protección adicional:
	# aunque algo falle arriba, jamás atacar al héroe.
	if enemigo_objetivo == heroe:
		enemigo_objetivo = null
		return


	if enemigo_objetivo.is_in_group("heroe"):
		enemigo_objetivo = null
		return


	enemigo_objetivo.recibir_dano(
		dano_ataque
	)


	print(
		"CADEJO BLANCO ATACÓ A ",
		enemigo_objetivo.name,
		" | DAÑO: ",
		dano_ataque
	)


	tiempo_ataque = tiempo_entre_ataques


	# -----------------------------------------------------
	# ENEMIGO DERROTADO
	# -----------------------------------------------------

	if not objetivo_es_valido(enemigo_objetivo):

		print(
			"CADEJO BLANCO PROTEGIÓ AL HÉROE"
		)

		enemigo_objetivo = null


# =========================================================
# SEGUIR AL HÉROE
# =========================================================

func seguir_heroe() -> void:

	if not is_instance_valid(heroe):

		velocity.x = 0.0
		velocity.z = 0.0

		return


	var direccion: Vector3 = (
		heroe.global_position
		- global_position
	)

	direccion.y = 0.0

	var distancia_horizontal: float = direccion.length()


	if distancia_horizontal > distancia_seguimiento:

		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad

		mirar_direccion(direccion)

	else:

		velocity.x = 0.0
		velocity.z = 0.0


# =========================================================
# ORIENTACIÓN
# =========================================================

func mirar_direccion(direccion: Vector3) -> void:

	if direccion.length_squared() <= 0.0001:
		return


	# El modelo visual del Cadejo mira hacia -Z.
	# Conservamos la corrección de 180 grados ya probada.
	var angulo_objetivo: float = (
		atan2(
			direccion.x,
			direccion.z
		)
		+ PI
	)


	rotation.y = lerp_angle(
		rotation.y,
		angulo_objetivo,
		suavidad_giro
		* get_physics_process_delta_time()
	)


# =========================================================
# GRAVEDAD
# =========================================================

func aplicar_gravedad(delta: float) -> void:

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0