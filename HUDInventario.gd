extends CanvasLayer


# =========================================================
# ESCENAS
# =========================================================

const SLOT_INVENTARIO = preload("res://SlotInventario.tscn")


# =========================================================
# NODOS
# =========================================================

@onready var panel_inventario: Control = $PanelInventario
@onready var fragmentos_label: Label = $PanelInventario/FragmentosLabel
@onready var boton_cerrar: Button = $PanelInventario/BotonCerrar
@onready var grid_objetos: GridContainer = $PanelInventario/GridObjetos


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	panel_inventario.visible = false

	# Ya no usaremos el Label antiguo como lista.
	# Lo dejamos oculto por ahora para no borrar nodos.
	if fragmentos_label != null:
		fragmentos_label.visible = false

	DatosJugador.inventario_actualizado.connect(
		actualizar_inventario
	)

	boton_cerrar.pressed.connect(
		cerrar_inventario
	)

	actualizar_inventario()


# =========================================================
# TECLA I
# =========================================================

func _input(event: InputEvent) -> void:

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_I:

				if panel_inventario.visible:
					cerrar_inventario()
				else:
					abrir_inventario()


# =========================================================
# ABRIR INVENTARIO
# =========================================================

func abrir_inventario() -> void:

	actualizar_inventario()

	panel_inventario.visible = true


# =========================================================
# CERRAR INVENTARIO
# =========================================================

func cerrar_inventario() -> void:

	panel_inventario.visible = false


# =========================================================
# ACTUALIZAR INVENTARIO
# =========================================================

func actualizar_inventario() -> void:

	if grid_objetos == null:
		return


	# =====================================================
	# BORRAR CASILLAS ANTERIORES
	# =====================================================

	for hijo in grid_objetos.get_children():

		hijo.queue_free()


	# =====================================================
	# OBTENER OBJETOS
	# =====================================================

	var ids_objetos: Array = DatosJugador.inventario.keys()

	ids_objetos.sort()


	# =====================================================
	# CREAR UNA CASILLA POR OBJETO
	# =====================================================

	for id_objeto in ids_objetos:

		var objeto: Dictionary = DatosJugador.inventario[id_objeto]

		var cantidad: int = int(
			objeto.get("cantidad", 0)
		)


		# No mostrar objetos con cantidad cero
		if cantidad <= 0:
			continue


		# Crear nueva casilla
		var slot = SLOT_INVENTARIO.instantiate()

		grid_objetos.add_child(slot)

		slot.configurar(objeto)