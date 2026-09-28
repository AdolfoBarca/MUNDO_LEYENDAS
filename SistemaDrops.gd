extends Node

# =========================================================
# MUNDO_LEYENDAS
# SISTEMA UNIVERSAL DE DROPS
# =========================================================

@export_group("Escena de recompensas")

@export var escena_drop: PackedScene = preload(
	"res://FragmentoEsencia.tscn"
)


# =========================================================
# CONFIGURACIÓN
# =========================================================

@export_group("Recompensas")

@export var generar_fragmentos: bool = true

@export_range(0.0, 100.0, 1.0)
var probabilidad_ceniza: float = 0.0

@export_range(0.0, 100.0, 1.0)
var probabilidad_sombrero: float = 0.0


# =========================================================
# GENERAR RECOMPENSAS
# =========================================================

func generar_drops(posicion: Vector3) -> void:

	print("==============================")
	print("GENERANDO RECOMPENSAS")
	print("CRIATURA: ", get_parent().name)

	if generar_fragmentos:
		crear_objeto(
			"fragmento_esencia",
			1,
			posicion
		)

	if randf() * 100.0 < probabilidad_ceniza:
		crear_objeto(
			"ceniza_encantada",
			1,
			posicion
		)

	if randf() * 100.0 < probabilidad_sombrero:
		crear_objeto(
			"sombrero_deteriorado",
			1,
			posicion
		)

	print("==============================")


# =========================================================
# CREAR OBJETO EN EL MUNDO
# =========================================================

func crear_objeto(
	id_objeto: String,
	cantidad: int,
	posicion: Vector3
) -> void:

	if escena_drop == null:
		push_warning("No hay escena de drops configurada.")
		return

	if not DatosJugador.catalogo_objetos.has(id_objeto):
		push_warning("Objeto desconocido: " + id_objeto)
		return

	var objeto = escena_drop.instantiate()

	if objeto == null:
		return

	if not objeto.has_method("configurar_drop"):
		objeto.free()
		push_error(
			"La escena no admite configurar_drop."
		)
		return

	objeto.configurar_drop(
		id_objeto,
		cantidad
	)

	var mundo = get_tree().current_scene

	if mundo == null:
		objeto.free()
		return

	mundo.add_child(objeto)

	var desplazamiento = Vector3(
		randf_range(-0.7, 0.7),
		0.0,
		randf_range(-0.7, 0.7)
	)

	objeto.global_position = posicion + desplazamiento

	print(
		"RECOMPENSA GENERADA: ",
		id_objeto
	)