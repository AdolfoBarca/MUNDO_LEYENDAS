extends Area3D


# =========================================================
# CONFIGURACIÓN DEL OBJETO
# =========================================================

@export var id_objeto: String = "fragmento_esencia"

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
# CONFIGURAR DROP
# =========================================================

func configurar_drop(
	nuevo_id: String,
	nueva_cantidad: int = 1
) -> void:

	id_objeto = nuevo_id

	cantidad = max(1, nueva_cantidad)

	var datos: Dictionary = DatosJugador.catalogo_objetos.get(
		id_objeto,
		{}
	)

	nombre_objeto = str(
		datos.get("nombre", id_objeto)
	)


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

	if not DatosJugador.catalogo_objetos.has(id_objeto):
		push_warning("DROP DESCONOCIDO: " + id_objeto)
		return

	recogido = true

	DatosJugador.agregar_objeto_catalogo(
		id_objeto,
		cantidad
	)

	print("==============================")
	print("OBJETO RECOGIDO: ", nombre_objeto)
	print("Cantidad recogida: ", cantidad)
	print(
		"Total en inventario: ",
		DatosJugador.obtener_cantidad_objeto(id_objeto)
	)
	print("==============================")

	queue_free()