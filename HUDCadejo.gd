extends CanvasLayer
# HUD del Cadejo Blanco: XP, vida real, descanso y agotamiento.
# No cambia combate ni guardado.

var panel: PanelContainer
var nivel_label: Label
var xp_label: Label
var estadisticas_label: Label
var barra_xp: ProgressBar
var vida_label: Label
var barra_vida: ProgressBar
var estado_label: Label
var detalle_label: Label
var aviso_label: Label
var aviso_tiempo: float = 0.0
var ultimo_nivel: int = -1
var ultimo_companero: String = ""
var tiempo_actualizacion: float = 0.0
var cadejo_en_escena: Node3D = null
var inventario_abierto: bool = false

func _ready() -> void:
    layer = 20
    process_mode = Node.PROCESS_MODE_ALWAYS
    _construir_interfaz()
    DatosJugador.progreso_cadejo_actualizado.connect(_al_actualizar_progreso)
    DatosJugador.companero_actualizado.connect(_al_cambiar_companero)
    DatosJugador.tecomate_actualizado.connect(_al_cambiar_tecomate)
    ultimo_nivel = DatosJugador.nivel_cadejo_blanco
    _actualizar_datos()
    _actualizar_visibilidad()
    _actualizar_estado()

func _process(delta: float) -> void:
    if aviso_tiempo > 0.0:
        aviso_tiempo -= delta
        if aviso_tiempo <= 0.0:
            aviso_label.visible = false
    tiempo_actualizacion += delta
    if tiempo_actualizacion >= 0.25:
        tiempo_actualizacion = 0.0
        _actualizar_visibilidad()
        if panel.visible:
            _actualizar_datos()
            _actualizar_estado()

func _construir_interfaz() -> void:
    panel = PanelContainer.new()
    panel.name = "PanelCadejoBlanco"
    panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -324.0
    panel.offset_right = -12.0
    panel.offset_top = 12.0
    panel.offset_bottom = 245.0
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(panel)

    var estilo := StyleBoxFlat.new()
    estilo.bg_color = Color(0.055, 0.09, 0.15, 0.94)
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
    xp_label.add_theme_font_size_override("font_size", 12)
    contenido.add_child(xp_label)

    barra_xp = ProgressBar.new()
    barra_xp.custom_minimum_size = Vector2(0, 12)
    barra_xp.show_percentage = false
    barra_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contenido.add_child(barra_xp)

    vida_label = Label.new()
    vida_label.add_theme_font_size_override("font_size", 12)
    vida_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.88))
    contenido.add_child(vida_label)

    barra_vida = ProgressBar.new()
    barra_vida.custom_minimum_size = Vector2(0, 14)
    barra_vida.show_percentage = false
    barra_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contenido.add_child(barra_vida)

    var estilo_vida := StyleBoxFlat.new()
    estilo_vida.bg_color = Color(0.22, 0.72, 0.40)
    estilo_vida.set_corner_radius_all(4)
    barra_vida.add_theme_stylebox_override("fill", estilo_vida)

    estado_label = Label.new()
    estado_label.add_theme_font_size_override("font_size", 13)
    contenido.add_child(estado_label)

    detalle_label = Label.new()
    detalle_label.add_theme_font_size_override("font_size", 11)
    detalle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    detalle_label.add_theme_color_override("font_color", Color(0.70, 0.79, 0.90))
    contenido.add_child(detalle_label)

    estadisticas_label = Label.new()
    estadisticas_label.add_theme_font_size_override("font_size", 12)
    contenido.add_child(estadisticas_label)

    aviso_label = Label.new()
    aviso_label.add_theme_font_size_override("font_size", 12)
    aviso_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.67))
    aviso_label.visible = false
    contenido.add_child(aviso_label)

func _actualizar_datos() -> void:
    var nivel: int = DatosJugador.nivel_cadejo_blanco
    var xp: int = DatosJugador.xp_cadejo_blanco
    var maximo_xp: int = DatosJugador.xp_necesaria_cadejo_blanco()
    nivel_label.text = "CADEJO BLANCO  ·  Nivel %d" % nivel
    xp_label.text = "Experiencia: %d / %d XP" % [xp, maximo_xp]
    barra_xp.max_value = maxi(1, maximo_xp)
    barra_xp.value = xp
    var ataque: int = 15 + (nivel - 1) * 3
    var defensa: int = 8 + (nivel - 1)
    estadisticas_label.text = "Ataque: %d  ·  Defensa: %d" % [ataque, defensa]

func _buscar_cadejo_en_escena() -> Node3D:
    if is_instance_valid(cadejo_en_escena) and not cadejo_en_escena.is_queued_for_deletion():
        return cadejo_en_escena
    cadejo_en_escena = null
    var escena: Node = get_tree().current_scene
    if escena == null:
        return null
    # La instancia tiene como raíz la escena CadejoBlanco.tscn.
    for nodo in escena.find_children("*", "", true, false):
        if nodo is Node3D and nodo.scene_file_path == "res://CadejoBlanco.tscn" and not nodo.is_queued_for_deletion():
            cadejo_en_escena = nodo as Node3D
            return cadejo_en_escena
    return null

func _actualizar_estado() -> void:
    var vida_maxima: int = DatosJugador.vida_maxima_cadejo_blanco()
    var vida_minima: int = DatosJugador.vida_minima_invocacion_cadejo()
    var activo: bool = DatosJugador.obtener_companero_activo() == "cadejo_blanco"
    barra_vida.max_value = maxi(1, vida_maxima)

    if activo:
        var instancia: Node3D = _buscar_cadejo_en_escena()
        if is_instance_valid(instancia):
            var vida_actual: int = clampi(int(instancia.get("vida_actual")), 0, vida_maxima)
            barra_vida.value = vida_actual
            vida_label.text = "Vida espiritual: %d / %d HP" % [vida_actual, vida_maxima]
            estado_label.text = "Cadejo Blanco invocado"
            estado_label.add_theme_color_override("font_color", Color(0.48, 0.95, 0.65))
            detalle_label.text = "El Cadejo está acompañando al héroe."
        else:
            vida_label.text = "Vida espiritual: preparando invocación"
            barra_vida.value = 0
            estado_label.text = "Invocando Cadejo Blanco"
            detalle_label.text = "Esperando a que aparezca el compañero."
        return

    cadejo_en_escena = null
    DatosJugador.actualizar_descanso_cadejo()
    var vida_actual: int = DatosJugador.vida_guardada_cadejo
    if vida_actual < 0:
        vida_actual = vida_maxima
    vida_actual = clampi(vida_actual, 0, vida_maxima)
    barra_vida.value = vida_actual
    vida_label.text = "Vida espiritual: %d / %d HP" % [vida_actual, vida_maxima]

    var agotamiento: int = DatosJugador.segundos_agotamiento_restantes()
    if agotamiento > 0:
        estado_label.text = "Agotamiento espiritual: %d s" % agotamiento
        estado_label.add_theme_color_override("font_color", Color(1.0, 0.73, 0.38))
        detalle_label.text = "Descansando en el Tecomate. Necesita %d HP para invocarse." % vida_minima
    elif vida_actual < vida_minima:
        estado_label.text = "Recuperándose en el Tecomate"
        estado_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.38))
        detalle_label.text = "Vida necesaria: %d HP (50%%). Recupera 5%% cada 10 segundos." % vida_minima
    else:
        estado_label.text = "Cadejo Blanco disponible"
        estado_label.add_theme_color_override("font_color", Color(0.48, 0.95, 0.65))
        detalle_label.text = "Pulsa R para invocarlo."

func _al_actualizar_progreso(nivel: int, _xp: int, guardado: bool) -> void:
    _actualizar_datos()
    if guardado and ultimo_nivel >= 0 and nivel > ultimo_nivel:
        _mostrar_aviso("¡SUBIÓ AL NIVEL %d! · Guardado" % nivel)
    ultimo_nivel = nivel

func _al_cambiar_companero(_id_companero: String) -> void:
    _actualizar_visibilidad()
    if panel.visible:
        _actualizar_estado()

func _al_cambiar_tecomate() -> void:
    _actualizar_visibilidad()
    if panel.visible:
        _actualizar_estado()

func establecer_inventario_abierto(abierto: bool) -> void:
    inventario_abierto = abierto
    _actualizar_visibilidad()

func _inventario_esta_visible() -> bool:
    # Busca el panel real en el árbol de escenas, aunque el HUD
    # del inventario no esté registrado como autoload.
    var paneles: Array[Node] = get_tree().root.find_children(
        "PanelInventario", "Control", true, false
    )
    for nodo: Node in paneles:
        var control: Control = nodo as Control
        if control != null and control.is_visible_in_tree():
            return true
    return false


func _actualizar_visibilidad() -> void:
    var disponible: bool = (
        DatosJugador.tecomate_esta_equipado()
        and DatosJugador.companero_esta_desbloqueado("cadejo_blanco")
    )
    # La visibilidad real del inventario tiene prioridad sobre
    # las señales, incluso si se abre por otro script.
    panel.visible = disponible and not inventario_abierto and not _inventario_esta_visible()
    ultimo_companero = DatosJugador.obtener_companero_activo()

func _mostrar_aviso(mensaje: String) -> void:
    aviso_label.text = mensaje
    aviso_label.visible = true
    aviso_tiempo = 3.0
