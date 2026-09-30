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
# COLORES DE PESTAÑAS
# =========================================================

var color_pestana_normal := Color(0.08, 0.08, 0.08, 0.78)
var color_pestana_activa := Color(0.25, 0.38, 0.25, 0.95)

var color_borde_normal := Color(0.20, 0.20, 0.20, 0.80)
var color_borde_activo := Color(0.55, 0.85, 0.55, 1.0)


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
	actualizar_estilo_pestanas()


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
	actualizar_estilo_pestanas()

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
	actualizar_estilo_pestanas()

	# Volver al inicio al cambiar de categoría.
	scroll_objetos.scroll_vertical = 0
	scroll_objetos.scroll_horizontal = 0


# =========================================================
# ESTILO DE PESTAÑAS
# =========================================================

func actualizar_estilo_pestanas() -> void:

	aplicar_estilo_pestana(
		boton_todos,
		filtro_actual == "Todos"
	)

	aplicar_estilo_pestana(
		boton_materiales,
		filtro_actual == "Material"
	)

	aplicar_estilo_pestana(
		boton_consumibles,
		filtro_actual == "Consumible"
	)

	aplicar_estilo_pestana(
		boton_equipo,
		filtro_actual == "Equipamiento"
	)

	aplicar_estilo_pestana(
		boton_legendarios,
		filtro_actual == "Legendario"
	)


func aplicar_estilo_pestana(
	boton: Button,
	seleccionado: bool
) -> void:

	var estilo := StyleBoxFlat.new()

	if seleccionado:
		estilo.bg_color = color_pestana_activa
		estilo.border_color = color_borde_activo
		estilo.set_border_width_all(2)

		boton.add_theme_color_override(
			"font_color",
			Color.WHITE
		)

	else:
		estilo.bg_color = color_pestana_normal
		estilo.border_color = color_borde_normal
		estilo.set_border_width_all(1)

		boton.add_theme_color_override(
			"font_color",
			Color(0.85, 0.85, 0.85, 1.0)
		)

	estilo.corner_radius_top_left = 5
	estilo.corner_radius_top_right = 5
	estilo.corner_radius_bottom_left = 5
	estilo.corner_radius_bottom_right = 5

	boton.add_theme_stylebox_override(
		"normal",
		estilo
	)

	# Mantener visible la selección al pasar el mouse.
	if seleccionado:
		var hover_activo := estilo.duplicate()

		hover_activo.bg_color = Color(
			0.30,
			0.45,
			0.30,
			1.0
		)

		boton.add_theme_stylebox_override(
			"hover",
			hover_activo
		)
	else:
		var hover_normal := estilo.duplicate()

		hover_normal.bg_color = Color(
			0.15,
			0.15,
			0.15,
			0.90
		)

		boton.add_theme_stylebox_override(
			"hover",
			hover_normal
		)


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