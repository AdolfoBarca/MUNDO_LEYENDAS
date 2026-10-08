
extends CharacterBody3D

const DIALOGOS: Array[String] = [
    "Bienvenido, viajero. Soy Don Aurelio, guardián de las historias de esta aldea.",
    "Nuestros abuelos contaban historias de criaturas que caminaban entre nosotros.",
    "Muchos creían que eran simples cuentos para asustar a los niños.",
    "Pero las leyendas están despertando y los bosques ya no son seguros.",
    "Existe un espíritu protector llamado Cadejo Blanco.",
    "Búscalo en el Sendero de los Guardianes. Él podrá ayudarte a comprender lo que está sucediendo."
]

var heroe_cerca: bool = false
var dialogo_activo: bool = false
var indice_dialogo: int = 0
var mision_entregada: bool = false

var interfaz: CanvasLayer
var panel_dialogo: PanelContainer
var texto_dialogo: Label
var texto_interaccion: Label


func _ready() -> void:
    add_to_group("npc")

    var area: Area3D = $AreaInteraccion
    area.body_entered.connect(_al_entrar)
    area.body_exited.connect(_al_salir)

    _crear_interfaz()

    print("DON AURELIO LISTO")


func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return

    if not event.pressed or event.echo:
        return

    if event.keycode != KEY_E:
        return

    if not heroe_cerca:
        return

    if not dialogo_activo:
        _iniciar_dialogo()
    else:
        _siguiente_dialogo()

    get_viewport().set_input_as_handled()


func _al_entrar(cuerpo: Node3D) -> void:
    if cuerpo.is_in_group("heroe"):
        heroe_cerca = true
        texto_interaccion.visible = true


func _al_salir(cuerpo: Node3D) -> void:
    if cuerpo.is_in_group("heroe"):
        heroe_cerca = false
        texto_interaccion.visible = false
        panel_dialogo.visible = false
        dialogo_activo = false


func _crear_interfaz() -> void:
    interfaz = CanvasLayer.new()
    interfaz.name = "InterfazDonAurelio"
    interfaz.layer = 10
    add_child(interfaz)

    texto_interaccion = Label.new()
    texto_interaccion.text = "Presiona E para hablar con Don Aurelio"
    texto_interaccion.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    texto_interaccion.position = Vector2(-160, -160)
    texto_interaccion.add_theme_font_size_override("font_size", 20)
    texto_interaccion.visible = false
    interfaz.add_child(texto_interaccion)

    panel_dialogo = PanelContainer.new()
    panel_dialogo.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    panel_dialogo.position = Vector2(-350, -190)
    panel_dialogo.custom_minimum_size = Vector2(700, 145)
    panel_dialogo.visible = false
    interfaz.add_child(panel_dialogo)

    var margen := MarginContainer.new()
    margen.add_theme_constant_override("margin_left", 20)
    margen.add_theme_constant_override("margin_right", 20)
    margen.add_theme_constant_override("margin_top", 15)
    margen.add_theme_constant_override("margin_bottom", 15)
    panel_dialogo.add_child(margen)

    var columna := VBoxContainer.new()
    margen.add_child(columna)

    var titulo := Label.new()
    titulo.text = "DON AURELIO"
    titulo.add_theme_font_size_override("font_size", 22)
    columna.add_child(titulo)

    texto_dialogo = Label.new()
    texto_dialogo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texto_dialogo.custom_minimum_size = Vector2(630, 65)
    columna.add_child(texto_dialogo)

    var indicacion := Label.new()
    indicacion.text = "E - Continuar"
    indicacion.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    columna.add_child(indicacion)


func _iniciar_dialogo() -> void:
    dialogo_activo = true
    indice_dialogo = 0
    panel_dialogo.visible = true
    texto_interaccion.visible = false
    texto_dialogo.text = DIALOGOS[indice_dialogo]


func _siguiente_dialogo() -> void:
    indice_dialogo += 1

    if indice_dialogo >= DIALOGOS.size():
        _terminar_dialogo()
        return

    texto_dialogo.text = DIALOGOS[indice_dialogo]


func _terminar_dialogo() -> void:
    dialogo_activo = false
    panel_dialogo.visible = false
    texto_interaccion.visible = heroe_cerca

    if not mision_entregada:
        mision_entregada = true
        print("==============================")
        print("NUEVA MISIÓN: EL DESPERTAR DE LAS LEYENDAS")
        print("OBJETIVO: ENCUENTRA AL CADEJO BLANCO")
        print("==============================")
