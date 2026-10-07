extends CharacterBody3D

# =========================================================
# CADEJO BLANCO - PRIMER COMPAÑERO
# =========================================================

@export var velocidad: float = 4.8
@export var distancia_seguimiento: float = 2.4
@export var distancia_maxima: float = 14.0
@export var suavidad_giro: float = 8.0

var heroe: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	print("==============================")
	print("CADEJO BLANCO LISTO")
	print("Estado: compañero protector")
	print("==============================")


func asignar_heroe(nuevo_heroe: Node3D) -> void:
	heroe = nuevo_heroe


func _physics_process(delta: float) -> void:
	if not is_instance_valid(heroe):
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Si el héroe se aleja demasiado, el Cadejo reaparece a su lado.
	var distancia_total: float = global_position.distance_to(heroe.global_position)

	if distancia_total > distancia_maxima:
		global_position = heroe.global_position + Vector3(1.8, 0.2, 1.8)
		velocity = Vector3.ZERO
		return

	var direccion := heroe.global_position - global_position
	direccion.y = 0.0

	var distancia_horizontal := direccion.length()

	if distancia_horizontal > distancia_seguimiento:
		direccion = direccion.normalized()

		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad

		# =====================================================
		# MIRAR HACIA LA DIRECCIÓN DE MOVIMIENTO
		# =====================================================
		# El modelo del Cadejo tiene su cabeza orientada hacia -Z.
		# Sumamos PI (180 grados) para corregir su orientación.
		var angulo_objetivo := atan2(direccion.x, direccion.z) + PI

		rotation.y = lerp_angle(
			rotation.y,
			angulo_objetivo,
			suavidad_giro * delta
		)

	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()