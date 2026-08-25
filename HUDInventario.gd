extends CanvasLayer


@onready var fragmentos_label: Label = $PanelInventario/FragmentosLabel


func _ready() -> void:

	print("==============================")
	print("HUD INVENTARIO CARGADO")
	print("Label encontrado: ", fragmentos_label)
	print("==============================")

	DatosJugador.inventario_actualizado.connect(
		actualizar_inventario
	)

	actualizar_inventario()


func actualizar_inventario() -> void:

	print(
		"HUD ACTUALIZANDO FRAGMENTOS: ",
		DatosJugador.fragmentos_esencia
	)

	if fragmentos_label == null:
		print("ERROR: FragmentosLabel no encontrado")
		return

	fragmentos_label.text = "Fragmentos de esencia: %d" % DatosJugador.fragmentos_esencia