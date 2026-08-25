extends Node


# =========================================================
# SEÑALES
# =========================================================

signal inventario_actualizado


# =========================================================
# DATOS DEL JUGADOR
# =========================================================

var nombre: String = ""
var pais: String = ""

var region: String = ""
var afinidad: String = ""


# =========================================================
# APARIENCIA
# =========================================================

var color_piel: Color = Color("#C98F65")
var color_camisa: Color = Color("#244A73")
var color_pantalon: Color = Color("#2F3540")


# =========================================================
# INVENTARIO
# =========================================================

# Variable antigua que mantenemos por compatibilidad
var fragmentos_esencia: int = 0


# Inventario general del jugador
var inventario: Dictionary = {

	"fragmento_esencia": {
		"nombre": "Fragmento de esencia",
		"tipo": "Material",
		"cantidad": 0,
		"rareza": "Común",
		"icono": "res://iconos/fragmento_esencia.png"
	}

}


# =========================================================
# ASIGNAR REGIÓN Y AFINIDAD
# =========================================================

func asignar_region_y_afinidad() -> void:

	var centroamerica = [
		"El Salvador",
		"Guatemala",
		"Honduras",
		"Nicaragua",
		"Costa Rica",
		"Panamá",
		"Belice"
	]


	if pais in centroamerica:

		region = "Centroamérica"
		afinidad = "Naturaleza"

	else:

		region = ""
		afinidad = ""


	print("==============================")
	print("DATOS DEL JUGADOR")
	print("País: ", pais)
	print("Región: ", region)
	print("Afinidad: ", afinidad)
	print("==============================")


# =========================================================
# AGREGAR OBJETO AL INVENTARIO
# =========================================================

func agregar_objeto(
	id_objeto: String,
	nombre_objeto: String,
	tipo_objeto: String,
	cantidad: int = 1,
	rareza: String = "Común"
) -> void:

	if cantidad <= 0:
		return


	# -----------------------------------------------------
	# SI EL OBJETO YA EXISTE
	# -----------------------------------------------------

	if inventario.has(id_objeto):

		inventario[id_objeto]["cantidad"] += cantidad


	# -----------------------------------------------------
	# SI ES UN OBJETO NUEVO
	# -----------------------------------------------------

	else:

		inventario[id_objeto] = {
			"nombre": nombre_objeto,
			"tipo": tipo_objeto,
			"cantidad": cantidad,
			"rareza": rareza,
			"icono": ""
		}


	# -----------------------------------------------------
	# COMPATIBILIDAD CON EL SISTEMA ACTUAL
	# -----------------------------------------------------

	if id_objeto == "fragmento_esencia":

		fragmentos_esencia = inventario[id_objeto]["cantidad"]


	inventario_actualizado.emit()


# =========================================================
# AGREGAR FRAGMENTOS DE ESENCIA
# =========================================================

func agregar_fragmentos_esencia(cantidad: int) -> void:

	if cantidad <= 0:
		return


	agregar_objeto(
		"fragmento_esencia",
		"Fragmento de esencia",
		"Material",
		cantidad,
		"Común"
	)


# =========================================================
# OBTENER CANTIDAD DE UN OBJETO
# =========================================================

func obtener_cantidad_objeto(id_objeto: String) -> int:

	if not inventario.has(id_objeto):
		return 0


	return int(
		inventario[id_objeto]["cantidad"]
	)


# =========================================================
# OBTENER DATOS DE UN OBJETO
# =========================================================

func obtener_objeto(id_objeto: String) -> Dictionary:

	if not inventario.has(id_objeto):
		return {}


	return inventario[id_objeto]


# =========================================================
# VERIFICAR SI EL JUGADOR TIENE UN OBJETO
# =========================================================

func tiene_objeto(
	id_objeto: String,
	cantidad: int = 1
) -> bool:

	return obtener_cantidad_objeto(id_objeto) >= cantidad