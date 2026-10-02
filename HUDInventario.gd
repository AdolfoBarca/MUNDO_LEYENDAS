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
# Ventana de inspección, creada sin modificar la escena.
var capa_detalles: Control
var imagen_detalle: TextureRect
var boton_zoom_restaurar: Button
var nombre_detalle: Label
var informacion_detalle: Label
var zoom_detalle: float = 1.0
var tamano_imagen_base: Vector2 = Vector2(480, 480)
var scroll_detalles: ScrollContainer
var scroll_avisos: ScrollContainer
var panel_detalles: PanelContainer
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
const MAX_AVISOS: int = 30
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
	crear_ventana_detalles()
	configurar_historial_avisos()
# =========================================================
# ENTRADA DE TECLADO
# =========================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE and capa_detalles != null and capa_detalles.visible:
				cerrar_detalles()
				get_viewport().set_input_as_handled()
				return
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
	cerrar_detalles()
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
	lista_objetos.move_child(margen, 0)
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
		var aviso_antiguo := lista_objetos.get_child(lista_objetos.get_child_count() - 1)
		lista_objetos.remove_child(aviso_antiguo)
		aviso_antiguo.queue_free()
	# =====================================================
	# El historial permanece disponible hasta llegar a MAX_AVISOS.
	# Los mensajes nuevos aparecen arriba.
	if scroll_avisos != null:
		scroll_avisos.scroll_vertical = 0

# =========================================================
# HISTORIAL DESPLAZABLE DE RECOMPENSAS
# =========================================================
func configurar_historial_avisos() -> void:
	if panel_objetos_obtenidos == null or lista_objetos == null:
		return
	var padre: Node = lista_objetos.get_parent()
	if padre is ScrollContainer:
		scroll_avisos = padre as ScrollContainer
	else:
		var posicion: int = lista_objetos.get_index()
		padre.remove_child(lista_objetos)
		scroll_avisos = ScrollContainer.new()
		scroll_avisos.name = "ScrollAvisos"
		scroll_avisos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll_avisos.size_flags_vertical = Control.SIZE_EXPAND_FILL
		padre.add_child(scroll_avisos)
		padre.move_child(scroll_avisos, posicion)
		scroll_avisos.add_child(lista_objetos)
	scroll_avisos.custom_minimum_size = Vector2(280, 145)
	scroll_avisos.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_avisos.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	lista_objetos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Si la escena ya tiene tamaño fijo, lo respetamos.
	panel_objetos_obtenidos.custom_minimum_size.y = maxf(panel_objetos_obtenidos.custom_minimum_size.y, 145.0)

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
		slot.objeto_seleccionado.connect(mostrar_detalles)
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
# =========================================================
# INSPECCIÓN DE OBJETOS Y ZOOM
# =========================================================
func crear_ventana_detalles() -> void:
	capa_detalles = Control.new()
	capa_detalles.name = "CapaDetalles"
	capa_detalles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa_detalles.mouse_filter = Control.MOUSE_FILTER_STOP
	capa_detalles.visible = false
	add_child(capa_detalles)

	var fondo := ColorRect.new()
	fondo.color = Color(0.0, 0.0, 0.0, 0.86)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	capa_detalles.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_PASS
	capa_detalles.add_child(centro)

	panel_detalles = PanelContainer.new()
	panel_detalles.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_detalles.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.105, 0.075, 0.15, 1.0)
	estilo.border_color = Color(0.63, 0.38, 0.86, 1.0)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(12)
	estilo.set_content_margin_all(14)
	panel_detalles.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel_detalles)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 8)
	panel_detalles.add_child(columna)

	var encabezado := HBoxContainer.new()
	columna.add_child(encabezado)
	nombre_detalle = Label.new()
	nombre_detalle.text = "Detalles del objeto"
	nombre_detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nombre_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nombre_detalle.add_theme_font_size_override("font_size", 21)
	encabezado.add_child(nombre_detalle)
	var cerrar := Button.new()
	cerrar.text = "X"
	cerrar.custom_minimum_size = Vector2(42, 42)
	cerrar.pressed.connect(cerrar_detalles)
	encabezado.add_child(cerrar)

	scroll_detalles = ScrollContainer.new()
	scroll_detalles.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_detalles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_detalles.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll_detalles.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	columna.add_child(scroll_detalles)

	var contenido := VBoxContainer.new()
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_theme_constant_override("separation", 12)
	scroll_detalles.add_child(contenido)

	var centro_imagen := CenterContainer.new()
	centro_imagen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contenido.add_child(centro_imagen)
	imagen_detalle = TextureRect.new()
	imagen_detalle.custom_minimum_size = tamano_imagen_base
	imagen_detalle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen_detalle.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_detalle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro_imagen.add_child(imagen_detalle)

	var controles_zoom := HBoxContainer.new()
	controles_zoom.alignment = BoxContainer.ALIGNMENT_CENTER
	contenido.add_child(controles_zoom)
	var alejar := Button.new()
	alejar.text = "−"
	alejar.custom_minimum_size = Vector2(52, 40)
	alejar.pressed.connect(func() -> void: cambiar_zoom(-0.25))
	controles_zoom.add_child(alejar)
	boton_zoom_restaurar = Button.new()
	boton_zoom_restaurar.text = "100 %"
	boton_zoom_restaurar.pressed.connect(func() -> void: establecer_zoom(1.0))
	controles_zoom.add_child(boton_zoom_restaurar)
	var acercar := Button.new()
	acercar.text = "+"
	acercar.custom_minimum_size = Vector2(52, 40)
	acercar.pressed.connect(func() -> void: cambiar_zoom(0.25))
	controles_zoom.add_child(acercar)

	informacion_detalle = Label.new()
	informacion_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	informacion_detalle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	informacion_detalle.add_theme_font_size_override("font_size", 16)
	contenido.add_child(informacion_detalle)

	# Tamaño inicial adaptado a la resolución del juego.
	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	panel_detalles.custom_minimum_size = Vector2(
		maxf(300.0, pantalla.x * 0.85),
		maxf(320.0, pantalla.y * 0.88)
	)
	scroll_detalles.custom_minimum_size = Vector2(0.0, maxf(200.0, pantalla.y * 0.70))

func mostrar_detalles(objeto: Dictionary) -> void:
	if capa_detalles == null:
		return
	nombre_detalle.text = str(objeto.get("nombre", "Objeto"))
	var ruta: String = str(objeto.get("icono", ""))
	# La casilla usa la ilustración recortada; la inspección usa la carta completa.
	if nombre_detalle.text == "Carta: Ceniza del Cipitío":
		ruta = "res://iconos/carta_ceniza_cipitio.png"
	imagen_detalle.texture = null
	if ruta != "" and ResourceLoader.exists(ruta):
		imagen_detalle.texture = load(ruta)
	if imagen_detalle.texture != null:
		var dimensiones: Vector2 = imagen_detalle.texture.get_size()
		if dimensiones.x > 0.0 and dimensiones.y > 0.0:
			var pantalla: Vector2 = get_viewport().get_visible_rect().size
			var ancho_maximo: float = pantalla.x * 0.74
			var alto_maximo: float = pantalla.y * 0.65
			var factor: float = minf(ancho_maximo / dimensiones.x, alto_maximo / dimensiones.y)
			tamano_imagen_base = dimensiones * factor
	else:
		tamano_imagen_base = Vector2(360, 360)
	establecer_zoom(1.0)
	var texto: String = "Tipo: %s    |    Rareza: %s\nCantidad: x%d" % [
		str(objeto.get("tipo", "Sin tipo")),
		str(objeto.get("rareza", "Común")),
		int(objeto.get("cantidad", 0))
	]
	var descripcion: String = str(objeto.get("descripcion", ""))
	if descripcion != "":
		texto += "\n\n" + descripcion
	if nombre_detalle.text == "Carta: Ceniza del Cipitío":
		texto += "\n\nTIPO DE HABILIDAD: Magia"
		texto += "\nEfecto: Tormenta de ceniza (ralentización)"
		texto += "\nReducción de velocidad: 55 %"
		texto += "\nDuración: 6 segundos"
		texto += "\nAlcance: 8 metros"
		texto += "\nRecarga: 20 segundos"
		texto += "\nCosto: 30 PE"
		texto += "\nDesbloqueo: 100 cenizas ancestrales (la carta se conserva)"
	informacion_detalle.text = texto
	capa_detalles.visible = true
	if scroll_detalles != null:
		scroll_detalles.scroll_vertical = 0
		scroll_detalles.scroll_horizontal = 0
func cambiar_zoom(cambio: float) -> void:
	establecer_zoom(zoom_detalle + cambio)
func establecer_zoom(nuevo_zoom: float) -> void:
	zoom_detalle = clampf(nuevo_zoom, 0.5, 3.0)
	if imagen_detalle != null:
		imagen_detalle.custom_minimum_size = tamano_imagen_base * zoom_detalle
	if boton_zoom_restaurar != null:
		boton_zoom_restaurar.text = "%d %%" % roundi(zoom_detalle * 100.0)
func cerrar_detalles() -> void:
	if capa_detalles != null:
		capa_detalles.visible = false
