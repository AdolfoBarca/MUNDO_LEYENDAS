extends Node

signal mision_actualizada

const ARCHIVO_MISIONES: String = "user://misiones.save"
const MISION_DESPERTAR: String = "despertar_leyendas"

var misiones: Dictionary = {}

func _ready() -> void:
	cargar_misiones()

func iniciar_mision(id: String) -> bool:
	if id != MISION_DESPERTAR or misiones.has(id):
		return false
	misiones[id] = "activa"
	guardar_misiones()
	mision_actualizada.emit()
	DatosJugador.avisar_evento("Nueva misión: El Despertar de las Leyendas", "info")
	return true

func estado_mision(id: String) -> String:
	return str(misiones.get(id, "no_iniciada"))

func completar_mision(id: String, heroe: Node) -> bool:
	if id != MISION_DESPERTAR or estado_mision(id) != "activa":
		return false
	if heroe == null or not heroe.has_method("recibir_experiencia"):
		return false
	misiones[id] = "completada"
	guardar_misiones()
	heroe.recibir_experiencia(50)
	mision_actualizada.emit()
	DatosJugador.avisar_evento("Misión completada: +50 XP", "exito")
	return true

func guardar_misiones() -> void:
	var archivo := FileAccess.open(ARCHIVO_MISIONES, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo guardar las misiones: " + str(FileAccess.get_open_error()))
		return
	archivo.store_var(misiones)
	archivo.close()

func cargar_misiones() -> void:
	if not FileAccess.file_exists(ARCHIVO_MISIONES):
		return
	var archivo := FileAccess.open(ARCHIVO_MISIONES, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo cargar las misiones: " + str(FileAccess.get_open_error()))
		return
	var datos: Variant = archivo.get_var()
	archivo.close()
	if datos is Dictionary:
		misiones = datos.duplicate(true)
