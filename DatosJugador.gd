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

var fragmentos_esencia: int = 0


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
# AGREGAR FRAGMENTOS DE ESENCIA
# =========================================================

func agregar_fragmentos_esencia(cantidad: int) -> void:

	if cantidad <= 0:
		return


	fragmentos_esencia += cantidad


	# Avisar al HUD que cambió el inventario
	inventario_actualizado.emit()


	print("==============================")
	print("INVENTARIO ACTUALIZADO")
	print("Fragmentos de esencia: ", fragmentos_esencia)
	print("==============================")