extends Area3D


# =========================================================
# DATOS DEL DROP
# =========================================================

@export var nombre_objeto: String = "Fragmento de esencia"
@export var cantidad: int = 1


# =========================================================
# CONTROL
# =========================================================

var recogido: bool = false


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	body_entered.connect(_on_body_entered)

	print("DROP CREADO: ", nombre_objeto)


# =========================================================
# RECOGER OBJETO
# =========================================================

func _on_body_entered(body: Node3D) -> void:

	if recogido:
		return


	if body == null:
		return


	if not body.is_in_group("heroe"):
		return


	recogido = true


	# =====================================================
	# AGREGAR AL INVENTARIO
	# =====================================================

	DatosJugador.agregar_fragmentos_esencia(
		cantidad
	)


	# =====================================================
	# MOSTRAR INFORMACIÓN
	# =====================================================

	print("==============================")
	print("OBJETO RECOGIDO: ", nombre_objeto)
	print("Cantidad recogida: ", cantidad)
	print(
		"Total de fragmentos: ",
		DatosJugador.fragmentos_esencia
	)
	print("==============================")


	# =====================================================
	# ELIMINAR DROP DEL MAPA
	# =====================================================

	queue_free()