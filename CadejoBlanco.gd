extends CharacterBody3D

# Avisar al héroe cuando el compañero agota su energía espiritual.

signal agotamiento_espiritual

# =========================================================

# CADEJO BLANCO - COMPAÑERO PROTECTOR

# =========================================================

# =========================================================

# SEGUIMIENTO DEL HÉROE

# =========================================================

@export var velocidad: float = 4.8

@export var distancia_seguimiento: float = 2.4

@export var distancia_maxima: float = 14.0

@export var suavidad_giro: float = 8.0

# =========================================================

# COMBATE

# =========================================================

@export var dano_ataque: int = 15

@export var distancia_deteccion_enemigo: float = 7.0

@export var distancia_ataque: float = 1.5

@export var tiempo_entre_ataques: float = 1.2

# El Cadejo no perseguirá enemigos demasiado lejos del héroe.

@export var distancia_maxima_combate_heroe: float = 10.0

# =========================================================

# REFERENCIAS

# =========================================================

var heroe: Node3D = null

var enemigo_objetivo: Node3D = null

var gravity: float = ProjectSettings.get_setting(

    "physics/3d/default_gravity"

)

var tiempo_ataque: float = 0.0

# =========================================================

# INICIO

# =========================================================

# VIDA Y DEFENSA DEL COMPAÑERO

@export var vida_maxima: int = 300

@export var defensa: int = 8

@export_range(0.0, 1.0, 0.01) var reduccion_dano: float = 0.20

var vida_actual: int = 300

var agotado: bool = false

var barra_vida: Node3D

var relleno_vida: MeshInstance3D

var material_relleno: StandardMaterial3D

func crear_barra_vida() -> void:

	barra_vida = Node3D.new()

	barra_vida.name = "BarraVidaCadejo"

	barra_vida.position = Vector3(0, 2.12, 0)

	add_child(barra_vida)

	var fondo := MeshInstance3D.new()

	var malla_fondo := BoxMesh.new()

	malla_fondo.size = Vector3(1.16, 0.16, 0.025)

	fondo.mesh = malla_fondo

	var material_fondo := StandardMaterial3D.new()

	material_fondo.albedo_color = Color(0.08, 0.10, 0.14)

	material_fondo.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	fondo.material_override = material_fondo

	barra_vida.add_child(fondo)

	relleno_vida = MeshInstance3D.new()

	var malla_relleno := BoxMesh.new()

	malla_relleno.size = Vector3(1.10, 0.105, 0.035)

	relleno_vida.mesh = malla_relleno

	relleno_vida.position.z = 0.018

	material_relleno = StandardMaterial3D.new()

	material_relleno.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	relleno_vida.material_override = material_relleno

	barra_vida.add_child(relleno_vida)

	actualizar_barra_vida()

func actualizar_barra_vida() -> void:

	if not is_instance_valid(relleno_vida):

		return

	var porcentaje: float = clampf(float(vida_actual) / maxf(float(vida_maxima), 1.0), 0.0, 1.0)

	relleno_vida.scale.x = maxf(porcentaje, 0.001)

	relleno_vida.position.x = -0.55 * (1.0 - porcentaje)

	if porcentaje > 0.5:

		material_relleno.albedo_color = Color(0.15, 0.9, 0.3)

	elif porcentaje > 0.25:

		material_relleno.albedo_color = Color(1.0, 0.8, 0.12)

	else:

		material_relleno.albedo_color = Color(1.0, 0.2, 0.2)

func recibir_dano(cantidad: int) -> void:

	if agotado:

		return

	var dano_real: int = maxi(1, roundi(float(cantidad) * (1.0 - reduccion_dano)))

	vida_actual = maxi(0, vida_actual - dano_real)

	actualizar_barra_vida()

	print("CADEJO BLANCO RECIBE ", dano_real, " DAÑO | VIDA: ", vida_actual, "/", vida_maxima)

	if vida_actual == 0:

		agotado = true

		enemigo_objetivo = null

		velocity = Vector3.ZERO

		print("CADEJO BLANCO: AGOTAMIENTO ESPIRITUAL")

		agotamiento_espiritual.emit()

func _process(_delta: float) -> void:

	if not is_instance_valid(barra_vida):

		return

	var camara := get_viewport().get_camera_3d()

	if is_instance_valid(camara):

		barra_vida.global_rotation = camara.global_rotation

func _ready() -> void:

	vida_actual = vida_maxima

	crear_barra_vida()

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

	if agotado:

		velocity = Vector3.ZERO

		return

	# -----------------------------------------------------

	# RECARGA DEL ATAQUE

	# -----------------------------------------------------

	if tiempo_ataque > 0.0:

		tiempo_ataque = maxf(

			0.0,

			tiempo_ataque - delta

		)

	# -----------------------------------------------------

	# COMPROBAR HÉROE

	# -----------------------------------------------------

	if not is_instance_valid(heroe):

		enemigo_objetivo = null

		velocity.x = 0.0

		velocity.z = 0.0

		aplicar_gravedad(delta)

		move_and_slide()

		return

	# =====================================================

	# ZONA SEGURA - MODO PASIVO

	# =====================================================

	#

	# Si el héroe entra al Santuario:

	#

	# - El Cadejo cancela cualquier enemigo.

	# - No busca nuevos enemigos.

	# - No ataca.

	# - Regresa junto al héroe.

	#

	# Al salir del Santuario volverá automáticamente

	# a funcionar como protector.

	# =====================================================

	if heroe.has_method("esta_en_zona_segura"):

		if heroe.esta_en_zona_segura():

			enemigo_objetivo = null

			seguir_heroe()

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

	# COMBATIR O SEGUIR AL HÉROE

	# -----------------------------------------------------

	if enemigo_objetivo != null:

		procesar_combate()

	else:

		seguir_heroe()

	# -----------------------------------------------------

	# GRAVEDAD

	# -----------------------------------------------------

	aplicar_gravedad(delta)

	move_and_slide()

# =========================================================

# BUSCAR ENEMIGO CERCANO

# =========================================================

#

# PRIORIDAD:

#

# 1. Enemigo que está persiguiendo al héroe.

# 2. Si nadie lo persigue, enemigo cercano al héroe.

#

# =========================================================

func buscar_enemigo_cercano() -> Node3D:

	if not is_instance_valid(heroe):

		return null

	# -----------------------------------------------------

	# SEGURIDAD EXTRA:

	# NO BUSCAR ENEMIGOS DENTRO DEL SANTUARIO

	# -----------------------------------------------------

	if heroe.has_method("esta_en_zona_segura"):

		if heroe.esta_en_zona_segura():

			return null

	var escena_actual := get_tree().current_scene

	if escena_actual == null:

		return null

	var candidatos: Array[Node] = []

	_recolectar_enemigos(

		escena_actual,

		candidatos

	)

	# =====================================================

	# PRIORIDAD 1

	# ENEMIGO QUE ESTÁ PERSIGUIENDO AL HÉROE

	# =====================================================

	# Prioridad especial: proteger al héroe del Cadejo Negro.
	for candidato in candidatos:
		if not is_instance_valid(candidato):
			continue
		if candidato.name != "CadejoNegro":
			continue
		if not objetivo_es_valido(candidato):
			continue
		var jefe: Node3D = candidato as Node3D
		if jefe.global_position.distance_to(heroe.global_position) <= distancia_maxima_combate_heroe:
			print("CADEJO BLANCO PROTEGE CONTRA: CADEJO NEGRO")
			return jefe

	var enemigo_agresor: Node3D = null

	var distancia_agresor: float = INF

	for candidato in candidatos:

		if not objetivo_es_valido(candidato):

			continue

		var enemigo := candidato as Node3D

		var distancia_al_heroe: float = (

			enemigo.global_position.distance_to(

				heroe.global_position

			)

		)

		# No perseguir amenazas demasiado lejos.

		if distancia_al_heroe > distancia_maxima_combate_heroe:

			continue

		# -------------------------------------------------

		# EnemigoPrueba utiliza:

		#

		# 0 = QUIETO

		# 1 = PERSIGUIENDO

		# 2 = REGRESANDO

		#

		# Si está en 1 significa que actualmente

		# está persiguiendo al héroe.

		# -------------------------------------------------

		if "estado_actual" in enemigo:

			if int(enemigo.estado_actual) == 1:

				if distancia_al_heroe < distancia_agresor:

					distancia_agresor = distancia_al_heroe

					enemigo_agresor = enemigo

	# -----------------------------------------------------

	# SI EXISTE UNA AMENAZA ACTIVA, TIENE PRIORIDAD

	# -----------------------------------------------------

	if enemigo_agresor != null:

		print(

			"CADEJO BLANCO PROTEGE CONTRA: ",

			enemigo_agresor.name

		)

		return enemigo_agresor

	# =====================================================

	# PRIORIDAD 2

	# ENEMIGO CERCANO AL HÉROE

	# =====================================================

	var mejor_enemigo: Node3D = null

	var mejor_distancia: float = INF

	for candidato in candidatos:

		if not objetivo_es_valido(candidato):

			continue

		var enemigo := candidato as Node3D

		var distancia_al_heroe: float = (

			enemigo.global_position.distance_to(

				heroe.global_position

			)

		)

		# Solo reaccionar si está dentro del radio protector.

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

		# NUNCA CONSIDERAR AL HÉROE COMO ENEMIGO

		# -------------------------------------------------

		if hijo == heroe:

			_recolectar_enemigos(

				hijo,

				resultado

			)

			continue

		# -------------------------------------------------

		# NUNCA CONSIDERAR AL PROPIO CADEJO

		# -------------------------------------------------

		if hijo == self:

			continue

		# -------------------------------------------------

		# POSIBLE ENEMIGO

		# -------------------------------------------------

		if (

			hijo is Node3D

			and hijo.has_method("recibir_dano")

			and (hijo.has_method("esta_muerto") or "derrotado" in hijo or "esta_muerto" in hijo)

		):

			resultado.append(hijo)

		# -------------------------------------------------

		# CONTINUAR BUSCANDO EN LOS HIJOS

		# -------------------------------------------------

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

	# SI EL HÉROE ESTÁ EN ZONA SEGURA,

	# NO EXISTE NINGÚN OBJETIVO VÁLIDO

	# -----------------------------------------------------

	if is_instance_valid(heroe):

		if heroe.has_method("esta_en_zona_segura"):

			if heroe.esta_en_zona_segura():

				return false

	# -----------------------------------------------------

	# NUNCA ATACAR AL HÉROE

	# -----------------------------------------------------

	if objetivo == heroe:

		return false

	# -----------------------------------------------------

	# NUNCA ATACARSE A SÍ MISMO

	# -----------------------------------------------------

	if objetivo == self:

		return false

	# -----------------------------------------------------

	# PROTECCIÓN ADICIONAL POR GRUPO

	# -----------------------------------------------------

	if objetivo.is_in_group("heroe"):

		return false

	# -----------------------------------------------------

	# DEBE SER UN NODE3D

	# -----------------------------------------------------

	if not objetivo is Node3D:

		return false

	# -----------------------------------------------------

	# DEBE PODER RECIBIR DAÑO

	# -----------------------------------------------------

	if not objetivo.has_method("recibir_dano"):

		return false

	# -----------------------------------------------------

	# DEBE TENER ESTADO DE MUERTE

	# -----------------------------------------------------

	if not (objetivo.has_method("esta_muerto") or "esta_muerto" in objetivo or "derrotado" in objetivo):

		return false

	# -----------------------------------------------------

	# NO ATACAR ENEMIGOS MUERTOS

	# -----------------------------------------------------

	if ("derrotado" in objetivo and objetivo.get("derrotado") == true) or (objetivo.has_method("esta_muerto") and objetivo.call("esta_muerto") == true):

		return false

	# -----------------------------------------------------

	# NO ATACAR ENEMIGOS OCULTOS

	# -----------------------------------------------------

	if not objetivo.visible:

		return false

	return true

# =========================================================

# PROCESAR COMBATE

# =========================================================

func procesar_combate() -> void:

	# -----------------------------------------------------

	# SEGURIDAD DEL SANTUARIO

	# -----------------------------------------------------

	if is_instance_valid(heroe):

		if heroe.has_method("esta_en_zona_segura"):

			if heroe.esta_en_zona_segura():

				enemigo_objetivo = null

				velocity.x = 0.0

				velocity.z = 0.0

				return

	# -----------------------------------------------------

	# VALIDAR OBJETIVO

	# -----------------------------------------------------

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

	# DIRECCIÓN HACIA EL ENEMIGO

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

	# YA ESTÁ A DISTANCIA DE ATAQUE

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

	# -----------------------------------------------------

	# NO ATACAR DENTRO DEL SANTUARIO

	# -----------------------------------------------------

	if is_instance_valid(heroe):

		if heroe.has_method("esta_en_zona_segura"):

			if heroe.esta_en_zona_segura():

				enemigo_objetivo = null

				return

	# -----------------------------------------------------

	# RECARGA

	# -----------------------------------------------------

	if tiempo_ataque > 0.0:

		return

	# -----------------------------------------------------

	# VALIDAR ENEMIGO

	# -----------------------------------------------------

	if not objetivo_es_valido(enemigo_objetivo):

		enemigo_objetivo = null

		return

	# -----------------------------------------------------

	# PROTECCIÓN ABSOLUTA DEL HÉROE

	# -----------------------------------------------------

	if enemigo_objetivo == heroe:

		enemigo_objetivo = null

		return

	if enemigo_objetivo.is_in_group("heroe"):

		enemigo_objetivo = null

		return

	# -----------------------------------------------------

	# APLICAR DAÑO

	# -----------------------------------------------------

	enemigo_objetivo.recibir_dano(

		dano_ataque

	)

	print(

		"CADEJO BLANCO ATACÓ A ",

		enemigo_objetivo.name,

		" | DAÑO: ",

		dano_ataque

	)

	# -----------------------------------------------------

	# INICIAR RECARGA

	# -----------------------------------------------------

	tiempo_ataque = tiempo_entre_ataques

	# -----------------------------------------------------

	# COMPROBAR SI LO DERROTÓ

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

	# -----------------------------------------------------

	# ACERCARSE AL HÉROE

	# -----------------------------------------------------

	if distancia_horizontal > distancia_seguimiento:

		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad

		velocity.z = direccion.z * velocidad

		mirar_direccion(direccion)

	# -----------------------------------------------------

	# QUEDARSE JUNTO AL HÉROE

	# -----------------------------------------------------

	else:

		velocity.x = 0.0

		velocity.z = 0.0

# =========================================================

# ORIENTACIÓN

# =========================================================

func mirar_direccion(direccion: Vector3) -> void:

	if direccion.length_squared() <= 0.0001:

		return

	# -----------------------------------------------------

	# El modelo visual del Cadejo mira hacia -Z.

	#

	# + PI conserva la corrección de orientación

	# que ya probamos anteriormente.

	# -----------------------------------------------------

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
