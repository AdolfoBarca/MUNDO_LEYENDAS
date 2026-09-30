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

@onready var panel_objetos_obtenidos: PanelContainer = $PanelObjetosObtenidos
@onready var lista_objetos: VBoxContainer = $PanelObjetosObtenidos/ListaObjetos


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
# HISTORIAL DE OBJETOS
# =========================================================

const DURACION_AVISO: float = 5.0
const MAX_AVISOS: int = 4

const TAMANO_ICONO: Vector2 = Vector2(34, 34)

const MARGEN_IZQUIERDO: int = 12
const MARGEN_DERECHO: int = 12
const MARGEN_SUPERIOR: int = 5
const MARGEN_INFERIOR: int = 5


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:

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
	# SEÑAL DE OBJETO OBTENIDO
	# =====================================================

	if not DatosJugador.objeto_obtenido.is_connected(
		mostrar_objeto_obtenido
	):
		DatosJugador.objeto_obtenido.connect(
			mostrar_objeto_obtenido
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


	# =====================================================
	# HOVER
	# =====================================================

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
# OBJETO OBTENIDO
# =========================================================

func mostrar_objeto_obtenido(
	id_objeto: String,
	cantidad: int
) -> void:

	if cantidad <= 0:
		return


	# =====================================================
	# DATOS DEL OBJETO
	# =====================================================

	var datos: Dictionary = DatosJugador.catalogo_objetos.get(
		id_objeto,
		{}
	)

	var nombre_objeto: String = str(
		datos.get(
			"nombre",
			id_objeto
		)
	)

	var ruta_icono: String = str(
		datos.get(
			"icono",
			""
		)
	)


	# =====================================================
	# MARGEN EXTERIOR
	# =====================================================

	var margen := MarginContainer.new()

	margen.add_theme_constant_override(
		"margin_left",
		MARGEN_IZQUIERDO
	)

	margen.add_theme_constant_override(
		"margin_right",
		MARGEN_DERECHO
	)

	margen.add_theme_constant_override(
		"margin_top",
		MARGEN_SUPERIOR
	)

	margen.add_theme_constant_override(
		"margin_bottom",
		MARGEN_INFERIOR
	)

	margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	lista_objetos.add_child(margen)


	# =====================================================
	# FILA PRINCIPAL
	# =====================================================

	var fila := HBoxContainer.new()

	fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	fila.add_theme_constant_override(
		"separation",
		7
	)

	margen.add_child(fila)


	# =====================================================
	# "HAS OBTENIDO:"
	# =====================================================

	var texto_inicio := Label.new()

	texto_inicio.text = "Has obtenido:"

	texto_inicio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	texto_inicio.add_theme_font_size_override(
		"font_size",
		17
	)

	texto_inicio.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	# No queremos que esta parte se expanda.
	texto_inicio.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	fila.add_child(texto_inicio)


	# =====================================================
	# ICONO
	# =====================================================

	var icono := TextureRect.new()

	icono.custom_minimum_size = TAMANO_ICONO

	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	icono.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	if ruta_icono != "":

		if ResourceLoader.exists(ruta_icono):

			icono.texture = load(ruta_icono)

	fila.add_child(icono)


	# =====================================================
	# CANTIDAD + NOMBRE
	# =====================================================

	var texto_objeto := Label.new()

	texto_objeto.text = "+%d %s" % [
		cantidad,
		nombre_objeto
	]

	texto_objeto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	texto_objeto.add_theme_font_size_override(
		"font_size",
		17
	)

	texto_objeto.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	# Esta parte recibe todo el espacio restante.
	texto_objeto.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Permite usar más de una línea.
	texto_objeto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Importante:
	# ya NO recortamos el texto con puntos suspensivos.
	texto_objeto.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

	fila.add_child(texto_objeto)


	# =====================================================
	# LIMITAR AVISOS
	# =====================================================

	while lista_objetos.get_child_count() > MAX_AVISOS:

		var aviso_antiguo := lista_objetos.get_child(0)

		lista_objetos.remove_child(aviso_antiguo)

		aviso_antiguo.queue_free()


	# =====================================================
	# DESAPARECER AUTOMÁTICAMENTE
	# =====================================================

	eliminar_aviso_despues(
		margen
	)


# =========================================================
# ELIMINAR AVISO
# =========================================================

func eliminar_aviso_despues(
	aviso: Control
) -> void:

	await get_tree().create_timer(
		DURACION_AVISO
	).timeout

	if not is_instance_valid(aviso):
		return


	# =====================================================
	# DESVANECIMIENTO
	# =====================================================

	var tween := create_tween()

	tween.tween_property(
		aviso,
		"modulate:a",
		0.0,
		0.45
	)

	await tween.finished


	# =====================================================
	# BORRAR
	# =====================================================

	if is_instance_valid(aviso):
		aviso.queue_free()


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
			objeto.get(
				"cantidad",
				0
			)
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

func objeto_pertenece_al_filtro(
	objeto: Dictionary
) -> bool:

	if filtro_actual == "Todos":

		return true


	var tipo: String = str(
		objeto.get(
			"tipo",
			""
		)
	)

	var rareza: String = str(
		objeto.get(
			"rareza",
			""
		)
	)


	# =====================================================
	# LEGENDARIOS
	# =====================================================

	if filtro_actual == "Legendario":

		return rareza.to_lower() == "legendario"


	# =====================================================
	# RESTO
	# =====================================================

	return tipo.to_lower() == filtro_actual.to_lower()


# =========================================================
# SEGURIDAD AL SALIR
# =========================================================

func _exit_tree() -> void:

	if get_tree() != null:

		get_tree().paused = false