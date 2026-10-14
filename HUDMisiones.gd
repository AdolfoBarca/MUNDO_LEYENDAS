extends CanvasLayer

# HUD independiente de las escenas y del progreso del Cadejo Blanco.
var raiz: Control
var panel: PanelContainer
var titulo: Label
var objetivo: Label
var recompensa: Label

func _ready() -> void:
	layer = 4
	_crear_panel()
	if not SistemaMisiones.mision_actualizada.is_connected(actualizar_panel):
		SistemaMisiones.mision_actualizada.connect(actualizar_panel)
	actualizar_panel()
	_actualizar_tras_carga.call_deferred()
	print("HUD MISIONES LISTO | Estado: ", SistemaMisiones.estado_mision(SistemaMisiones.MISION_DESPERTAR))

func _crear_panel() -> void:
	raiz = Control.new()
	raiz.name = "RaizHUDMisiones"
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)
	# Establecer el tamaño después de entrar al árbol de la escena.
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	panel = PanelContainer.new()
	panel.name = "PanelMisiones"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	# Debajo del HUD del Cadejo Blanco, con margen visible entre paneles.
	panel.offset_left = -322.0
	panel.offset_top = 265.0
	panel.offset_right = -12.0
	panel.offset_bottom = 420.0

	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.07, 0.10, 0.15, 0.92)
	fondo.border_color = Color(0.55, 0.46, 0.27)
	fondo.set_border_width_all(1)
	fondo.set_corner_radius_all(8)
	fondo.content_margin_left = 14.0
	fondo.content_margin_right = 14.0
	fondo.content_margin_top = 12.0
	fondo.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", fondo)

	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 7)
	panel.add_child(columna)

	var encabezado := Label.new()
	encabezado.text = "MISIÓN PRINCIPAL"
	encabezado.add_theme_font_size_override("font_size", 16)
	encabezado.add_theme_color_override("font_color", Color(0.98, 0.82, 0.44))
	columna.add_child(encabezado)

	titulo = Label.new()
	titulo.text = "El Despertar de las Leyendas"
	titulo.add_theme_font_size_override("font_size", 15)
	columna.add_child(titulo)

	objetivo = Label.new()
	objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objetivo.text = "Encuentra al Cadejo Blanco en el Sendero de los Guardianes."
	objetivo.add_theme_font_size_override("font_size", 13)
	columna.add_child(objetivo)

	recompensa = Label.new()
	recompensa.text = "Recompensa: 50 XP"
	recompensa.add_theme_font_size_override("font_size", 12)
	recompensa.add_theme_color_override("font_color", Color(0.75, 0.82, 0.89))
	columna.add_child(recompensa)

func actualizar_panel() -> void:
	if panel == null:
		return
	var estado: String = SistemaMisiones.estado_mision(SistemaMisiones.MISION_DESPERTAR)
	panel.visible = estado == "activa"
	print("HUD MISIONES | Estado: ", estado, " | Visible: ", panel.visible)

# Reconsulta cuando todos los Autoloads han terminado su _ready().
func _actualizar_tras_carga() -> void:
	await get_tree().process_frame
	actualizar_panel()
