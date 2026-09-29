extends CharacterBody3D

# ==========================================
# MUNDO_LEYENDAS
# CIPITÍO LEGENDARIO
# ==========================================


# ==========================================
# ESTADÍSTICAS
# ==========================================

@export_group("Estadísticas")

@export var vida_maxima: int = 1500
@export var ataque_base: int = 35
@export var defensa: int = 12


# ==========================================
# MOVIMIENTO Y COMBATE
# ==========================================

@export_group("Combate")

@export var velocidad_fase_1: float = 2.8
@export var velocidad_fase_2: float = 4.0

@export var distancia_deteccion: float = 14.0
@export var distancia_ataque: float = 2.5

@export var radio_arena: float = 15.0

@export var tiempo_entre_ataques: float = 1.8


# ==========================================
# CENIZA LEGENDARIA
# ==========================================

@export_group("Ceniza Legendaria")

@export var alcance_ceniza: float = 8.0

@export var duracion_ceniza_fase_1: float = 5.0
@export var duracion_ceniza_fase_2: float = 6.0

@export var reduccion_fase_1: float = 0.40
@export var reduccion_fase_2: float = 0.55

@export var recarga_ceniza_fase_1: float = 10.0
@export var recarga_ceniza_fase_2: float = 7.0


# ==========================================
# ESTADOS
# ==========================================

enum Estado {
	QUIETO,
	PERSIGUIENDO,
	REGRESANDO
}

var estado_actual: Estado = Estado.QUIETO


# ==========================================
# VARIABLES
# ==========================================

var vida_actual: int = 1500

var fase_actual: int = 1

var derrotado: bool = false

var heroe: CharacterBody3D = null

var posicion_inicial: Vector3

var temporizador_ataque: float = 0.0
var temporizador_ceniza: float = 3.0

var velocidad_actual: float = 2.8

const ANCHO_BARRA: float = 2.3


# ==========================================
# REFERENCIAS
# ==========================================

@onready var vida_label: Label3D = $VidaLabel

@onready var barra_relleno: MeshInstance3D = (
	$BarraVidaRelleno
)


# ==========================================
# INICIO
# ==========================================

func _ready() -> void:

	posicion_inicial = global_position

	vida_actual = vida_maxima

	velocidad_actual = velocidad_fase_1

	# Evita modificar recursos compartidos.
	if barra_relleno.mesh != null:
		barra_relleno.mesh = barra_relleno.mesh.duplicate()

	if barra_relleno.material_override != null:
		barra_relleno.material_override = (
			barra_relleno.material_override.duplicate()
		)

	actualizar_interfaz()

	print("==============================")
	print("CIPITÍO LEGENDARIO DESPERTÓ")
	print("VIDA: ", vida_actual)
	print("ATAQUE: ", ataque_base)
	print("DEFENSA: ", defensa)
	print("POSICIÓN: ", posicion_inicial)
	print("==============================")


# ==========================================
# PROCESO PRINCIPAL
# ==========================================

func _physics_process(delta: float) -> void:

	if derrotado:
		return

	temporizador_ataque = maxf(
		0.0,
		temporizador_ataque - delta
	)

	temporizador_ceniza = maxf(
		0.0,
		temporizador_ceniza - delta
	)

	if not is_instance_valid(heroe):
		buscar_heroe()

	if not is_instance_valid(heroe):
		velocity = Vector3.ZERO
		return

	var distancia_heroe: float = (
		distancia_horizontal(
			global_position,
			heroe.global_position
		)
	)

	var distancia_heroe_centro: float = (
		distancia_horizontal(
			posicion_inicial,
			heroe.global_position
		)
	)

	var distancia_jefe_centro: float = (
		distancia_horizontal(
			posicion_inicial,
			global_position
		)
	)

	var heroe_no_disponible: bool = false

	if heroe.get("esta_muerto") == true:
		heroe_no_disponible = true

	if heroe.has_method("esta_en_zona_segura"):
		if heroe.esta_en_zona_segura():
			heroe_no_disponible = true

	match estado_actual:

		Estado.QUIETO:

			velocity = Vector3.ZERO

			if heroe_no_disponible:
				return

			if distancia_heroe_centro > radio_arena:
				return

			if distancia_heroe <= distancia_deteccion:

				estado_actual = Estado.PERSIGUIENDO

				print(
                    "CIPITÍO LEGENDARIO DETECTÓ AL HÉROE"
				)


		Estado.PERSIGUIENDO:

			if (
				heroe_no_disponible
				or distancia_heroe_centro > radio_arena
				or distancia_jefe_centro > radio_arena
			):

				comenzar_regreso()
				return

			if distancia_heroe > distancia_ataque:

				mover_hacia_heroe()

			else:

				velocity.x = 0.0
				velocity.z = 0.0

				atacar_heroe()

			intentar_ceniza(distancia_heroe)


		Estado.REGRESANDO:

			var distancia_regreso: float = (
				distancia_horizontal(
					global_position,
					posicion_inicial
				)
			)

			if distancia_regreso <= 0.35:

				global_position = posicion_inicial

				velocity = Vector3.ZERO

				restaurar_jefe()

				return

			mover_hacia_posicion(posicion_inicial)

	aplicar_gravedad(delta)

	move_and_slide()


# ==========================================
# DISTANCIA HORIZONTAL
# ==========================================

func distancia_horizontal(
	origen: Vector3,
	destino: Vector3
) -> float:

	var diferencia: Vector3 = destino - origen

	diferencia.y = 0.0

	return diferencia.length()


# ==========================================
# GRAVEDAD
# ==========================================

func aplicar_gravedad(delta: float) -> void:

	if not is_on_floor():

		velocity.y -= 9.8 * delta

	else:

		velocity.y = 0.0


# ==========================================
# BUSCAR HÉROE
# ==========================================

func buscar_heroe() -> void:

	var heroes = get_tree().get_nodes_in_group(
        "heroe"
	)

	if heroes.is_empty():
		return

	heroe = heroes[0] as CharacterBody3D


# ==========================================
# PERSEGUIR
# ==========================================

func mover_hacia_heroe() -> void:

	if not is_instance_valid(heroe):
		return

	var direccion: Vector3 = (
		heroe.global_position - global_position
	)

	direccion.y = 0.0

	if direccion.length() <= 0.001:
		return

	direccion = direccion.normalized()

	velocity.x = direccion.x * velocidad_actual
	velocity.z = direccion.z * velocidad_actual

	mirar_hacia(heroe.global_position)


# ==========================================
# MIRAR HACIA OBJETIVO
# ==========================================

func mirar_hacia(objetivo: Vector3) -> void:

	var posicion_objetivo := Vector3(
		objetivo.x,
		global_position.y,
		objetivo.z
	)

	if global_position.distance_to(
		posicion_objetivo
	) <= 0.01:
		return

	look_at(
		posicion_objetivo,
		Vector3.UP
	)


# ==========================================
# ATAQUE FÍSICO
# ==========================================

func atacar_heroe() -> void:

	if temporizador_ataque > 0.0:
		return

	if not is_instance_valid(heroe):
		return

	if not heroe.has_method("recibir_dano"):
		return

	if heroe.has_method("esta_en_zona_segura"):

		if heroe.esta_en_zona_segura():
			comenzar_regreso()
			return

	heroe.recibir_dano(ataque_base)

	temporizador_ataque = tiempo_entre_ataques

	print(
		"CIPITÍO LEGENDARIO ATACÓ: ",
		ataque_base
	)


# ==========================================
# CENIZA LEGENDARIA
# ==========================================

func intentar_ceniza(
	distancia: float
) -> void:

	if temporizador_ceniza > 0.0:
		return

	if distancia > alcance_ceniza:
		return

	if not is_instance_valid(heroe):
		return

	if not heroe.has_method(
        "aplicar_ceniza_magica"
	):
		return

	var duracion: float
	var reduccion: float
	var recarga: float

	if fase_actual == 1:

		duracion = duracion_ceniza_fase_1
		reduccion = reduccion_fase_1
		recarga = recarga_ceniza_fase_1

	else:

		duracion = duracion_ceniza_fase_2
		reduccion = reduccion_fase_2
		recarga = recarga_ceniza_fase_2

	heroe.aplicar_ceniza_magica(
		duracion,
		reduccion
	)

	temporizador_ceniza = recarga

	crear_efecto_ceniza(
		heroe.global_position
	)

	print(
        "CIPITÍO LANZÓ CENIZA LEGENDARIA"
	)


# ==========================================
# EFECTO VISUAL DE CENIZA
# ==========================================

func crear_efecto_ceniza(
	posicion: Vector3
) -> void:

	var escena = get_tree().current_scene

	if escena == null:
		return

	var nube := MeshInstance3D.new()

	var esfera := SphereMesh.new()

	esfera.radius = 1.2
	esfera.height = 2.4

	nube.mesh = esfera

	var material := StandardMaterial3D.new()

	if fase_actual == 1:

		material.albedo_color = Color(
			0.5,
			0.2,
			0.7,
			0.65
		)

	else:

		material.albedo_color = Color(
			0.9,
			0.15,
			0.1,
			0.75
		)

	material.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)

	material.shading_mode = (
		BaseMaterial3D.SHADING_MODE_UNSHADED
	)

	nube.material_override = material

	escena.add_child(nube)

	nube.global_position = (
		posicion + Vector3(0, 1, 0)
	)

	var tween := create_tween()

	tween.tween_property(
		nube,
		"scale",
		Vector3(3.0, 2.0, 3.0),
		0.8
	)

	tween.parallel().tween_property(
		material,
		"albedo_color:a",
		0.0,
		0.8
	)

	tween.finished.connect(
		nube.queue_free
	)


# ==========================================
# RECIBIR DAÑO
# ==========================================

func recibir_dano(cantidad: int) -> void:

	if derrotado:
		return

	var dano_real: int = maxi(
		1,
		cantidad - defensa
	)

	vida_actual = maxi(
		0,
		vida_actual - dano_real
	)

	print(
		"CIPITÍO RECIBIÓ DAÑO: ",
		dano_real,
		" | VIDA: ",
		vida_actual,
		"/",
		vida_maxima
	)

	actualizar_interfaz()

	if vida_actual <= 0:

		morir()
		return

	if (
		fase_actual == 1
		and vida_actual <= vida_maxima / 2
	):

		activar_segunda_fase()


# ==========================================
# ACTUALIZAR BARRA
# ==========================================

func actualizar_interfaz() -> void:

	vida_label.text = (
        "CIPITÍO LEGENDARIO\n"
		+ str(vida_actual)
		+ " / "
		+ str(vida_maxima)
	)

	var porcentaje: float = clampf(
		float(vida_actual) / float(
			maxi(1, vida_maxima)
		),
		0.0,
		1.0
	)

	var caja: BoxMesh = (
		barra_relleno.mesh as BoxMesh
	)

	if caja != null:

		caja.size.x = (
			ANCHO_BARRA * porcentaje
		)

		barra_relleno.position.x = (
			-ANCHO_BARRA
			* (1.0 - porcentaje)
			/ 2.0
		)


# ==========================================
# SEGUNDA FASE
# ==========================================

func activar_segunda_fase() -> void:

	fase_actual = 2

	ataque_base = 50

	velocidad_actual = velocidad_fase_2

	var material: StandardMaterial3D = (
		barra_relleno.material_override
		as StandardMaterial3D
	)

	if material != null:

		material.albedo_color = (
			Color.ORANGE_RED
		)

	print("==============================")
	print("¡SEGUNDA FASE ACTIVADA!")
	print("ATAQUE: ", ataque_base)
	print("VELOCIDAD: ", velocidad_actual)
	print("==============================")


# ==========================================
# REGRESAR A LA ARENA
# ==========================================

func comenzar_regreso() -> void:

	if estado_actual == Estado.REGRESANDO:
		return

	estado_actual = Estado.REGRESANDO

	velocity = Vector3.ZERO

	print(
        "EL CIPITÍO REGRESA AL CENTRO"
	)


func mover_hacia_posicion(
	destino: Vector3
) -> void:

	var direccion: Vector3 = (
		destino - global_position
	)

	direccion.y = 0.0

	if direccion.length() <= 0.001:

		velocity.x = 0.0
		velocity.z = 0.0
		return

	direccion = direccion.normalized()

	velocity.x = (
		direccion.x * velocidad_fase_1
	)

	velocity.z = (
		direccion.z * velocidad_fase_1
	)


# ==========================================
# RESTAURAR JEFE
# ==========================================

func restaurar_jefe() -> void:

	estado_actual = Estado.QUIETO

	fase_actual = 1

	vida_actual = vida_maxima

	ataque_base = 35

	velocidad_actual = velocidad_fase_1

	temporizador_ataque = 0.0
	temporizador_ceniza = 3.0

	var material: StandardMaterial3D = (
		barra_relleno.material_override
		as StandardMaterial3D
	)

	if material != null:

		material.albedo_color = Color.RED

	actualizar_interfaz()

	print(
		"CIPITÍO RESTAURADO: ",
		vida_actual,
		"/",
		vida_maxima
	)


# ==========================================
# MUERTE
# ==========================================

func morir() -> void:

	if derrotado:
		return

	derrotado = true

	velocity = Vector3.ZERO

	print("==============================")
	print("¡CIPITÍO LEGENDARIO DERROTADO!")
	print("==============================")

	queue_free()
