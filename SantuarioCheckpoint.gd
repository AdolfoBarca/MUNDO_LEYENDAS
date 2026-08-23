extends Area3D


# =========================================================
# CONFIGURACIÓN
# =========================================================

@export var nombre_santuario: String = "Santuario"


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	body_entered.connect(_cuando_entra_cuerpo)
	body_exited.connect(_cuando_sale_cuerpo)

	print("SANTUARIO LISTO: ", nombre_santuario)


# =========================================================
# ENTRAR AL SANTUARIO
# =========================================================

func _cuando_entra_cuerpo(body: Node3D) -> void:

	if body.name != "Heroe":
		return

	print("==============================")
	print("HÉROE ENTRÓ AL SANTUARIO")
	print("Santuario: ", nombre_santuario)
	print("==============================")

	if body.has_method("entrar_zona_segura"):
		body.entrar_zona_segura()

	if body.has_method("activar_checkpoint"):
		body.activar_checkpoint(global_position)


# =========================================================
# SALIR DEL SANTUARIO
# =========================================================

func _cuando_sale_cuerpo(body: Node3D) -> void:

	if body.name != "Heroe":
		return

	print("==============================")
	print("HÉROE SALIÓ DEL SANTUARIO")
	print("==============================")

	if body.has_method("salir_zona_segura"):
		body.salir_zona_segura()