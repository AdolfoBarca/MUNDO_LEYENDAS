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

@onready var scroll_objetos: ScrollContainer = $PanelInventario/ScrollObjetos
@onready var grid_objetos: GridContainer = $PanelInventario/ScrollObjetos/GridObjetos

@onready var boton_todos: Button = $PanelInventario/Pestanas/BotonTodos
@onready var boton_materiales: Button = $PanelInventario/Pestanas/BotonMateriales
@onready var boton_consumibles: Button = $PanelInventario/Pestanas/BotonConsumibles
@onready var boton_equipo: Button = $PanelInventario/Pestanas/BotonEquipo
@onready var boton_legendarios: Button = $PanelInventario/Pestanas/BotonLegendarios


# =========================================================
# FILTRO ACTUAL
# =========================================================

var filtro_actual: String = "Todos"


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

	# Permite que el inventario siga funcionando
	# mientras el juego está pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS

	panel_inventario.visible = false

	if fragmentos_label != null:
		fragmentos_label.visible = false


	# =====================================================
	# SEÑAL DEL INVENTARIO
	# =====================================================

	if not DatosJugador.inventario_actualizado.is_connected(
		actualizar_inventario
	):
		DatosJugador.inventario_actualizado.connect(
			actualizar_inventario
		)


	# =====================================================
	# BOTÓN CERRAR
	# =====================================================

	if not boton_cerrar.pressed.is_connected(
		cerrar_inventario
	):
		boton_cerrar.pressed.connect(
			cerrar_inventario
		)


	# =====================================================
	# BOTONES DE PESTAÑAS
	# =====================================================

	boton_todos.pressed.connect(
		func() -> void:
			cambiar_filtro("Todos")
	)

	boton_materiales.pressed.connect(
		func() -> void:
			cambiar_filtro("Material")
	)

	boton_consumibles.pressed.connect(
		func() -> void:
			cambiar_filtro("Consumible")
	)

	boton_equipo.pressed.connect(
		func() -> void:
			cambiar_filtro("Equipamiento")
	)

	boton_legendarios.pressed.connect(
		func() -> void:
			cambiar_filtro("Legendario")
	)


	# =====================================================
	# CONFIGURAR CUADRÍCULA
	# =====================================================

	grid_objetos.columns = 6

	actualizar_inventario()


# =========================================================
# ENTRADA DE TECLADO
# =========================================================

func _input(event: InputEvent) -> void:

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_I:

				if panel_inventario.visible:
					cerrar_inventario()
				else:
					abrir_inventario()

				get_viewport().set_input_as_handled()


# =========================================================
# ABRIR INVENTARIO
# =========================================================

func abrir_inventario() -> void:

	filtro_actual = "Todos"

	actualizar_inventario()

	panel_inventario.visible = true

	get_tree().paused = true


# =========================================================
# CERRAR INVENTARIO
# =========================================================

func cerrar_inventario() -> void:

	panel_inventario.visible = false

	get_tree().paused = false


# =========================================================
# CAMBIAR FILTRO
# =========================================================

func cambiar_filtro(nuevo_filtro: String) -> void:

	filtro_actual = nuevo_filtro

	actualizar_inventario()

	# Volver al inicio al cambiar de categoría.
	scroll_objetos.scroll_vertical = 0
	scroll_objetos.scroll_horizontal = 0


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
	# CREAR CASILLAS
	# =====================================================

	for id_objeto in ids_objetos:

		var objeto: Dictionary = DatosJugador.inventario[id_objeto]

		var cantidad: int = int(
			objeto.get("cantidad", 0)
		)

		if cantidad <= 0:
			continue


		# =================================================
		# COMPROBAR PESTAÑA
		# =================================================

		if not objeto_pertenece_al_filtro(objeto):
			continue


		# =================================================
		# CREAR SLOT
		# =================================================

		var slot = SLOT_INVENTARIO.instantiate()

		grid_objetos.add_child(slot)

		slot.configurar(objeto)


# =========================================================
# COMPROBAR FILTRO
# =========================================================

func objeto_pertenece_al_filtro(objeto: Dictionary) -> bool:

	if filtro_actual == "Todos":
		return true

	var tipo: String = str(
		objeto.get("tipo", "")
	)

	var rareza: String = str(
		objeto.get("rareza", "")
	)


	# =====================================================
	# LEGENDARIOS
	# =====================================================

	if filtro_actual == "Legendario":
		return rareza.to_lower() == "legendario"


	# =====================================================
	# RESTO DE CATEGORÍAS
	# =====================================================

	return tipo.to_lower() == filtro_actual.to_lower()


# =========================================================
# SEGURIDAD AL SALIR
# =========================================================

func _exit_tree() -> void:

	if get_tree() != null:
		get_tree().paused = false
