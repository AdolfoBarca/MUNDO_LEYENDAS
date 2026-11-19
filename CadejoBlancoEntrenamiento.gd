extends CharacterBody3D
# Cadejo Blanco del claro: NPC de entrenamiento, NO es el compañero invocado.
# Interacción E; el ataque del héroe lo detecta mediante AreaAtaque.

const MISION: String = "pacto_guardian_blanco"
const VIDA_MAXIMA: int = 300
const VIDA_FIN_PRUEBA: int = 60
const RADIO_INTERACCION: float = 4.0
const RADIO_INICIO_AUTOMATICO: float = 4.0
# Ajuste de orientacion de la malla original (Godot mira hacia -Z).
const GIRO_MODELO: float = 0.0
const RADIO_PERSECUCION: float = 10.0
const VELOCIDAD: float = 3.2
const TIEMPO_ATAQUE: float = 1.7

var vida_actual: int = VIDA_MAXIMA
var heroe: Node3D
var dialogo_abierto: bool = false
var linea: int = 0
var espera_ataque: float = 0.0
var primer_encuentro_activado: bool = false
var visual_cadejo: Node3D
var panel: PanelContainer
var texto: Label
var indicacion: Label3D

const DIALOGOS: Array[String] = [
    "CADEJO BLANCO: Detente, viajero. Este claro protege a los espíritus que aún conservan su luz. ¿Qué buscas aquí?",
    "HÉROE: Quiero comprender a las criaturas de estas tierras. No deseo que todas sean mis enemigas.",
    "CADEJO BLANCO: Entonces recuerda: algunas criaturas aceptarán acompañarte, pero otras cargan almas corrompidas que primero necesitan un ritual de purificación.",
    "HÉROE: ¿Cómo puedo establecer un vínculo con ellas?",
    "CADEJO BLANCO: Mediante un Tecomate de los Espíritus. El mío es básico, pero basta para sellar un pacto conmigo. No lo entregaré sin conocer tu corazón.",
    "HÉROE: ¿Qué debo hacer?",
    "CADEJO BLANCO: Enfréntame en una prueba de entrenamiento. No pelearemos hasta la muerte. Quiero comprobar tu valor y tu capacidad de contener la fuerza.",
    "HÉROE: Acepto. Lucharé con honor."
]
const FINAL: Array[String] = [
    "CADEJO BLANCO: Basta. Has demostrado valor sin dejarte dominar por la violencia. Has superado mi prueba.",
    "CADEJO BLANCO: Toma este Tecomate Básico de los Espíritus. Es tuyo, sin azar ni condiciones ocultas.",
    "CADEJO BLANCO: Acércalo a mí y aceptaré voluntariamente nuestro pacto. No es una prisión: es una promesa de protección mutua.",
    "CADEJO BLANCO: Mi antiguo rival, el Cadejo Negro, custodia un Tecomate mejorado. Al derrotarlo existe apenas un 5 % de posibilidad de obtenerlo.",
    "CADEJO BLANCO: Aun con esa reliquia, no podrás capturarlo hasta purificar su alma mediante un ritual. Recuerda: primero se libera el espíritu; después se establece el pacto.",
    "HÉROE: Entonces viajaremos juntos y descubriremos cómo devolverle la luz."
]

func _ready() -> void:
    collision_layer = 1
    collision_mask = 1
    add_to_group("npc_cadejo_entrenamiento")
    _crear_visual()
    _crear_interfaz()
    heroe = get_parent().get_node_or_null("Heroe") as Node3D
    # Nuevo reinicio solicitado: una sola vez, con respaldos v5.
    _reiniciar_pacto_anterior_una_vez()
    if _estado() == "completada" or DatosJugador.companero_esta_desbloqueado("cadejo_blanco"):
        queue_free()

func _reiniciar_pacto_anterior_una_vez() -> void:
    const MARCADOR: String = "user://reinicio_pacto_cadejo_v5.realizado"
    if FileAccess.file_exists(MARCADOR):
        return
    # Se hace una copia de los tres archivos ANTES de escribir cambios.
    var archivos: Array[String] = [
        "user://inventario_equipamiento.save",
        "user://progreso_cadejo_blanco.save",
        "user://misiones.save"
    ]
    for ruta in archivos:
        if FileAccess.file_exists(ruta):
            var origen: String = ProjectSettings.globalize_path(ruta)
            var respaldo: String = origen + ".antes_del_reinicio_v5.bak"
            var resultado: Error = DirAccess.copy_absolute(origen, respaldo)
            if resultado != OK:
                push_error("No se pudo respaldar " + ruta + ". No se reinicio nada.")
                return
    # Solo el Cadejo Blanco: no tocar progreso del heroe, guantes ni cofres.
    DatosJugador.companeros_desbloqueados.erase("cadejo_blanco")
    DatosJugador.companero_activo = ""
    # Retirar el tecomate previo para obtenerlo mediante la nueva mision.
    DatosJugador.inventario.erase(DatosJugador.ID_TECOMATE_ESPIRITUS)
    DatosJugador.tecomate_equipado = false
    DatosJugador.nivel_cadejo_blanco = 1
    DatosJugador.xp_cadejo_blanco = 0
    DatosJugador.vida_guardada_cadejo = -1
    DatosJugador.inicio_descanso_cadejo = 0
    DatosJugador.resto_descanso_cadejo = 0
    DatosJugador.fin_agotamiento_cadejo = 0
    SistemaMisiones.misiones.erase(MISION)
    # Don Aurelio: conservar el estado historico de su mision y su XP.
    DatosJugador.guardar_progreso_cadejo_blanco()
    DatosJugador.guardar_inventario_equipamiento()
    SistemaMisiones.guardar_misiones()
    DatosJugador.inventario_actualizado.emit()
    DatosJugador.tecomate_actualizado.emit()
    DatosJugador.companero_actualizado.emit("")
    SistemaMisiones.mision_actualizada.emit()
    var marca: FileAccess = FileAccess.open(MARCADOR, FileAccess.WRITE)
    if marca != null:
        marca.store_string("Reinicio del pacto completado; respaldos .bak disponibles.")
        marca.close()
    DatosJugador.avisar_evento("El Cadejo Blanco espera un nuevo pacto en el claro.", "info")
    print("PACTO CADEJO REINICIADO UNA VEZ | Nivel Cadejo: 1 | XP: 0")

func _crear_visual() -> void:
    var col := CollisionShape3D.new()
    var forma := CapsuleShape3D.new()
    forma.radius = 0.7
    forma.height = 2.0
    col.shape = forma
    add_child(col)
    # Reutilizar el modelo REAL del Cadejo Blanco compañero.
    # Se copian solo las mallas, sin ejecutar su IA ni su script.
    var escena_real: PackedScene = load("res://CadejoBlanco.tscn")
    if escena_real != null:
        var modelo_real: Node = escena_real.instantiate()
        if modelo_real != null:
            var visual := Node3D.new()
            visual.name = "AparienciaCadejoOriginal"
            visual_cadejo = visual
            visual.rotation.y = GIRO_MODELO
            add_child(visual)
            _copiar_mallas(modelo_real, modelo_real, visual)
            modelo_real.free()
    else:
        push_warning("No se encontro CadejoBlanco.tscn para copiar su apariencia")
    indicacion = Label3D.new()
    indicacion.position = Vector3(0, 1.75, 0)
    indicacion.font_size = 30
    indicacion.pixel_size = 0.008
    indicacion.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(indicacion)

func _copiar_mallas(nodo: Node, raiz: Node, destino: Node3D) -> void:
    for hijo in nodo.get_children():
        if hijo is MeshInstance3D:
            var original: MeshInstance3D = hijo as MeshInstance3D
            var copia: MeshInstance3D = original.duplicate(0) as MeshInstance3D
            if copia != null:
                destino.add_child(copia)
                var transformacion: Transform3D = Transform3D.IDENTITY
                var actual: Node = original
                while actual != raiz and actual is Node3D:
                    transformacion = (actual as Node3D).transform * transformacion
                    actual = actual.get_parent()
                copia.transform = transformacion
        _copiar_mallas(hijo, raiz, destino)

func _crear_interfaz() -> void:
    var capa := CanvasLayer.new()
    capa.layer = 12
    add_child(capa)
    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 28.0
    panel.offset_right = -28.0
    panel.offset_top = -190.0
    panel.offset_bottom = -28.0
    panel.visible = false
    capa.add_child(panel)
    var margen := MarginContainer.new()
    margen.add_theme_constant_override("margin_left", 15)
    margen.add_theme_constant_override("margin_right", 15)
    margen.add_theme_constant_override("margin_top", 10)
    margen.add_theme_constant_override("margin_bottom", 10)
    panel.add_child(margen)
    texto = Label.new()
    texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    texto.custom_minimum_size = Vector2(0, 100)
    margen.add_child(texto)

func _estado() -> String:
    return SistemaMisiones.estado_mision(MISION)

func _process(_delta: float) -> void:
    if not is_instance_valid(heroe):
        return
    var cerca: bool = global_position.distance_to(heroe.global_position) <= RADIO_INTERACCION
    var estado: String = _estado()
    if estado == "completada":
        queue_free()
        return
    _orientar_hacia_heroe()
    # Solo la primera conversacion empieza por proximidad; E avanza el texto.
    if not primer_encuentro_activado and cerca and estado == "no_iniciada":
        primer_encuentro_activado = true
        if SistemaMisiones.iniciar_mision(MISION):
            dialogo_abierto = true
            linea = 0
            _mostrar(DIALOGOS[linea])
            print("DIALOGO CADEJO INICIADO AUTOMATICAMENTE")
        estado = _estado()
    if estado == "completada":
        indicacion.text = "Cadejo Blanco - Pacto sellado" if cerca else ""
    elif estado == "entrenamiento":
        indicacion.text = "Entrenamiento: %d/%d HP" % [vida_actual, VIDA_MAXIMA]
    elif cerca:
        indicacion.text = "E - Hablar con el Cadejo Blanco"
    else:
        indicacion.text = ""

func _input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.physical_keycode != KEY_E and event.keycode != KEY_E:
        return
    if not is_instance_valid(heroe) or get_tree().paused:
        return
    if not dialogo_abierto and global_position.distance_to(heroe.global_position) > RADIO_INTERACCION:
        return
    var estado: String = _estado()
    if estado == "completada" or estado == "entrenamiento":
        return
    get_viewport().set_input_as_handled()
    if estado == "no_iniciada":
        SistemaMisiones.iniciar_mision(MISION)
        estado = _estado()
    if estado == "dialogo":
        if not dialogo_abierto:
            dialogo_abierto = true
            linea = 0
            _mostrar(DIALOGOS[linea])
            print("DIALOGO CADEJO INICIADO")
        else:
            linea += 1
            if linea < DIALOGOS.size():
                _mostrar(DIALOGOS[linea])
            else:
                dialogo_abierto = false
                panel.visible = false
                vida_actual = VIDA_MAXIMA
                SistemaMisiones.avanzar_pacto("dialogo", "entrenamiento")
                DatosJugador.avisar_evento("Prueba iniciada: reduce al Cadejo Blanco al 20 % de vida.", "info")
    elif estado == "prueba_superada" or (estado == "tecomate_entregado" and dialogo_abierto):
        if not dialogo_abierto:
            dialogo_abierto = true
            linea = 0
            _mostrar(FINAL[linea])
        else:
            linea += 1
            if linea == 1:
                # Se concede una sola vez. Si ya lo tenia, no se duplica.
                if not DatosJugador.tiene_tecomate_espiritus():
                    DatosJugador.agregar_objeto_catalogo(DatosJugador.ID_TECOMATE_ESPIRITUS, 1)
                DatosJugador.equipar_tecomate()
                SistemaMisiones.avanzar_pacto("prueba_superada", "tecomate_entregado")
            if linea < FINAL.size():
                _mostrar(FINAL[linea])
            else:
                _sellar_pacto()
    elif estado == "tecomate_entregado":
        if not dialogo_abierto:
            dialogo_abierto = true
            linea = 2
            _mostrar(FINAL[linea])
        else:
            linea += 1
            if linea < FINAL.size():
                _mostrar(FINAL[linea])
            else:
                _sellar_pacto()

func _mostrar(mensaje: String) -> void:
    panel.visible = true
    print("DIALOGO CADEJO: ", mensaje)
    texto.text = mensaje + "\n\n[E] Continuar"

func _sellar_pacto() -> void:
    if not DatosJugador.tiene_tecomate_espiritus():
        DatosJugador.avisar_evento("Necesitas el Tecomate Básico para sellar el pacto.", "advertencia")
        return
    DatosJugador.desbloquear_companero("cadejo_blanco")
    SistemaMisiones.avanzar_pacto("tecomate_entregado", "completada")
    DatosJugador.avisar_evento("¡Pacto sellado! Cadejo Blanco es tu compañero. Equipa el Tecomate y pulsa R.", "exito")
    dialogo_abierto = false
    panel.visible = false
    # El espiritu del claro ya se encuentra en el Tecomate.
    queue_free()

func recibir_dano(cantidad: int) -> void:
    if _estado() != "entrenamiento":
        return
    vida_actual = maxi(VIDA_FIN_PRUEBA, vida_actual - maxi(1, cantidad))
    if vida_actual <= VIDA_FIN_PRUEBA:
        velocity = Vector3.ZERO
        SistemaMisiones.avanzar_pacto("entrenamiento", "prueba_superada")
        DatosJugador.avisar_evento("¡Prueba superada! Habla con el Cadejo Blanco (E).", "exito")

func _orientar_hacia_heroe() -> void:
    if not is_instance_valid(heroe):
        return
    var objetivo: Vector3 = heroe.global_position
    objetivo.y = global_position.y
    if global_position.distance_squared_to(objetivo) < 0.01:
        return
    # El modelo original mira hacia -Z; no aplicar giro extra.
    look_at(objetivo, Vector3.UP)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(heroe):
        return
    if _estado() != "entrenamiento":
        velocity = Vector3.ZERO
        return
    espera_ataque = maxf(0.0, espera_ataque - delta)
    var direccion: Vector3 = heroe.global_position - global_position
    direccion.y = 0.0
    var distancia: float = direccion.length()
    if distancia > RADIO_PERSECUCION:
        velocity = Vector3.ZERO
        return
    if distancia > 2.1:
        velocity.x = direccion.normalized().x * VELOCIDAD
        velocity.z = direccion.normalized().z * VELOCIDAD
    else:
        velocity.x = 0.0
        velocity.z = 0.0
        if espera_ataque <= 0.0 and heroe.has_method("recibir_dano"):
            # Daño no letal: no provocar muerte ni respawn por la prueba.
            var vida_heroe: int = int(heroe.get("vida_actual"))
            if vida_heroe > 1:
                var defensa_total: int = int(heroe.obtener_defensa_total())
                var golpe: int = maxi(1, mini(12, vida_heroe - 1))
                # Heroe.recibir_dano resta la defensa; se compensa aqui.
                heroe.recibir_dano(defensa_total + golpe)
            espera_ataque = TIEMPO_ATAQUE
    if not is_on_floor():
        velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
    else:
        velocity.y = 0.0
    move_and_slide()
