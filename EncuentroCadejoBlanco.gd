extends Node3D
## Encuentro narrativo independiente del Cadejo Blanco.
## Añadir a un Node3D llamado EncuentroCadejoBlanco, hijo de Main.

@export var escena_cadejo: PackedScene = preload("res://CadejoBlanco.tscn")
@export var radio_conversacion: float = 3.5

var heroe: Node3D
var cadejo_visual: Node3D
var panel: PanelContainer
var texto: Label
var indicacion: Label
var pagina: int = -1

const DIALOGOS: Array[String] = [
    "CADEJO BLANCO: No temas, viajero. Desde hace siglos protejo a quienes caminan por estas tierras.",
    "CADEJO BLANCO: Muchos me conocen como el Cadejo Blanco, guardián de los caminos y protector de los viajeros.",
    "CADEJO BLANCO: El Tecomate de los Espíritus permite formar vínculos con seres legendarios. Primero debes conseguirlo y equiparlo.",
    "CADEJO BLANCO: Pero el vínculo no se impone. Para que te acompañe, antes tendrás que ganar mi confianza.",
    "CADEJO BLANCO: Regresa pronto. Entonces hablaremos de la prueba que te espera."
]

func _ready() -> void:
    heroe = get_parent().get_node_or_null("Heroe") as Node3D
    if heroe == null:
        push_warning("EncuentroCadejoBlanco: no se encontró Main/Heroe")
        return
    if escena_cadejo == null:
        push_warning("EncuentroCadejoBlanco: falta CadejoBlanco.tscn")
        return
    cadejo_visual = escena_cadejo.instantiate() as Node3D
    if cadejo_visual == null:
        push_warning("EncuentroCadejoBlanco: la escena no tiene raíz Node3D")
        return
    add_child(cadejo_visual)
    cadejo_visual.position = Vector3.ZERO
    # Es un personaje de diálogo, no el compañero invocado.
    cadejo_visual.set_physics_process(false)
    cadejo_visual.set_process(false)
    cadejo_visual.set_process_input(false)
    if cadejo_visual is CollisionObject3D:
        (cadejo_visual as CollisionObject3D).collision_layer = 0
        (cadejo_visual as CollisionObject3D).collision_mask = 0
    var capa := CanvasLayer.new()
    capa.name = "InterfazEncuentro"
    add_child(capa)
    indicacion = Label.new()
    indicacion.text = "E - Hablar con el Cadejo Blanco"
    indicacion.position = Vector2(25, 330)
    indicacion.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
    capa.add_child(indicacion)
    indicacion.hide()
    panel = PanelContainer.new()
    panel.position = Vector2(25, 365)
    panel.custom_minimum_size = Vector2(520, 115)
    capa.add_child(panel)
    var margen := MarginContainer.new()
    margen.add_theme_constant_override("margin_left", 14)
    margen.add_theme_constant_override("margin_right", 14)
    margen.add_theme_constant_override("margin_top", 12)
    margen.add_theme_constant_override("margin_bottom", 12)
    panel.add_child(margen)
    var columna := VBoxContainer.new()
    margen.add_child(columna)
    texto = Label.new()
    texto.custom_minimum_size = Vector2(490, 72)
    texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    columna.add_child(texto)
    var ayuda := Label.new()
    ayuda.text = "E: continuar     ESC: cerrar"
    columna.add_child(ayuda)
    panel.hide()
    print("ENCUENTRO CADEJO BLANCO LISTO")

func _process(_delta: float) -> void:
    if not is_instance_valid(heroe):
        return
    var cerca := Vector2(global_position.x - heroe.global_position.x, global_position.z - heroe.global_position.z).length() <= radio_conversacion
    if not cerca and pagina >= 0:
        cerrar_dialogo()
    if indicacion != null:
        indicacion.visible = cerca and pagina < 0

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode == KEY_ESCAPE and pagina >= 0:
        cerrar_dialogo()
        get_viewport().set_input_as_handled()
        return
    if event.physical_keycode != KEY_E or not is_instance_valid(heroe):
        return
    var distancia := Vector2(global_position.x - heroe.global_position.x, global_position.z - heroe.global_position.z).length()
    if distancia > radio_conversacion:
        return
    pagina += 1
    if pagina >= DIALOGOS.size():
        cerrar_dialogo()
    else:
        texto.text = DIALOGOS[pagina]
        panel.show()
        indicacion.hide()
    get_viewport().set_input_as_handled()

func cerrar_dialogo() -> void:
    pagina = -1
    if panel != null:
        panel.hide()
