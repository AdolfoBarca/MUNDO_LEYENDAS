extends Node

var nombre: String = ""
var pais: String = ""

var region: String = ""
var afinidad: String = ""

var color_piel: Color = Color("#C98F65")
var color_camisa: Color = Color("#244A73")
var color_pantalon: Color = Color("#2F3540")

func asignar_region_y_afinidad() -> void:
	var paises_centro = ["El Salvador", "Guatemala", "Honduras", "Nicaragua", "Costa Rica", "Panamá", "Belice"]
	if pais in paises_centro:
		region = "Centroamérica"
		afinidad = "Naturaleza"