extends CanvasLayer
# Autoload: HUDCadejo. Panel visible mientras el compañero esté seleccionado.
# No modifica las escenas ni el combate del Cadejo Blanco.

var panel: PanelContainer
var nivel_label: Label
var xp_label: Label
var estadisticas_label: Label
var barra_xp: ProgressBar
var aviso_label: Label
var aviso_tiempo: float = 0.0
var ultimo_nivel: int = -1
var ultimo_companero: String = ""

func _ready() -> void:
    layer = 20
    _construir_interfaz()
    DatosJugador.progreso_cadejo_actualizado.connect(_al_actualizar_progreso)
    DatosJugador.companero_actualizado.connect(_al_cambiar_companero)
    ultimo_nivel = DatosJugador.nivel_cadejo_blanco
    _actualizar_datos()
    _actualizar_visibilidad()

func _process(delta: float) -> void:
    _actualizar_visibilidad()
    if aviso_tiempo > 0.0:
        aviso_tiempo -= delta
        if aviso_tiempo <= 0.0:
            aviso_label.visible = false

func _construir_interfaz() -> void:
    panel = PanelContainer.new()
    panel.name = "PanelCadejoBlanco"
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -304.0
    panel.offset_right = -12.0
    panel.offset_top = 12.0
    panel.offset_bottom = 152.0
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)

    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.055, 0.09, 0.15, 0.91)
    estilo.border_color = Color(0.55, 0.79, 0.96, 0.9)
    estilo.set_border_width_all(1)
    estilo.set_corner_radius_all(10)
    estilo.set_content_margin_all(10)
    panel.add_theme_stylebox_override("panel", estilo)

    var contenido := VBoxContainer.new()
    contenido.add_theme_constant_override("separation", 5)
    contenido.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(contenido)

    nivel_label = Label.new()
    nivel_label.add_theme_font_size_override("font_size", 16)
    nivel_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
    contenido.add_child(nivel_label)

    xp_label = Label.new()
    xp_label.add_theme_font_size_override("font_size", 13)
    contenido.add_child(xp_label)

    barra_xp = ProgressBar.new()
    barra_xp.custom_minimum_size = Vector2(0, 14)
    barra_xp.show_percentage = false
    barra_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contenido.add_child(barra_xp)

    estadisticas_label = Label.new()
    estadisticas_label.add_theme_font_size_override("font_size", 12)
    contenido.add_child(estadisticas_label)

    aviso_label = Label.new()
    aviso_label.add_theme_font_size_override("font_size", 13)
    aviso_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.67))
    aviso_label.visible = false
    contenido.add_child(aviso_label)

func _actualizar_datos() -> void:
    var nivel: int = DatosJugador.nivel_cadejo_blanco
    var xp: int = DatosJugador.xp_cadejo_blanco
    var maximo: int = DatosJugador.xp_necesaria_cadejo_blanco()
    nivel_label.text = "CADEJO BLANCO  ·  Nivel %d" % nivel
    xp_label.text = "Experiencia: %d / %d XP" % [xp, maximo]
    barra_xp.max_value = maximo
    barra_xp.value = xp
    var vida: int = 300 + (nivel - 1) * 25
    var ataque: int = 15 + (nivel - 1) * 3
    var defensa: int = 8 + (nivel - 1)
    estadisticas_label.text = "Vida: %d  ·  Ataque: %d  ·  Defensa: %d" % [vida, ataque, defensa]

func _al_actualizar_progreso(nivel: int, _xp: int, guardado: bool) -> void:
    _actualizar_datos()
    if guardado:
        if ultimo_nivel >= 0 and nivel > ultimo_nivel:
            _mostrar_aviso("¡SUBIÓ AL NIVEL %d! · Guardado" % nivel)
        else:
            _mostrar_aviso("✓ Progreso guardado")
    ultimo_nivel = nivel

func _al_cambiar_companero(_id_companero: String) -> void:
    _actualizar_visibilidad()

func _actualizar_visibilidad() -> void:
    var activo: String = DatosJugador.obtener_companero_activo()
    panel.visible = activo == "cadejo_blanco"
    if panel.visible and ultimo_companero != activo:
        _actualizar_datos()
        _mostrar_aviso("✓ Progreso recuperado")
    ultimo_companero = activo

func _mostrar_aviso(mensaje: String) -> void:
    aviso_label.text = mensaje
    aviso_label.visible = true
    aviso_tiempo = 3.0
