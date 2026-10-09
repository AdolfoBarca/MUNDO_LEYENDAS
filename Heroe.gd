extends CharacterBody3D
# =========================================================
# MOVIMIENTO Y ATAQUE
# =========================================================
@export var move_speed: float = 5.0
@export var attack_cooldown: float = 0.5
@export var dano: int = 20
@export var defensa: int = 3
# La defensa del nivel se mantiene en 'defensa'. El equipo se calcula aparte.
func obtener_defensa_total() -> int:
    return defensa + DatosJugador.obtener_defensa_guantes_puestos()
func al_cambiar_equipamiento() -> void:
    print("DEFENSA ACTUALIZADA: base=", defensa,
        " guantes=", DatosJugador.obtener_defensa_guantes_puestos(),
        " total=", obtener_defensa_total())
    actualizar_interfaz()
# =========================================================
# VIDA DEL HÉROE
# =========================================================
@export var vida_maxima: int = 100
@export var regeneracion_por_segundo: int = 2
@export var espera_para_regenerar: float = 5.0
var vida_actual: int
var esta_muerto: bool = false
var en_zona_segura: bool = false
var temporizador_regeneracion: float = 0.0
var tiempo_desde_ultimo_dano: float = 0.0
# =========================================================
# PUNTOS DE ENERGÍA (PE)
# =========================================================
@export var pe_maximo: int = 100
@export var regeneracion_pe_por_pulso: int = 1
@export var intervalo_regeneracion_pe: float = 2.0
@export var espera_para_regenerar_pe: float = 5.0
var pe_actual: float = 100.0
var tiempo_desde_ultimo_gasto_pe: float = 0.0
var tiempo_para_siguiente_pulso_pe: float = 0.0
func tiene_pe(cantidad: float) -> bool:
    return cantidad >= 0.0 and pe_actual >= cantidad
func consumir_pe(cantidad: float) -> bool:
    if cantidad <= 0.0:
        return false
    if not tiene_pe(cantidad):
        print("PE INSUFICIENTE: ", roundi(pe_actual), "/", pe_maximo, " | Necesarios: ", roundi(cantidad))
        return false
    pe_actual = maxf(0.0, pe_actual - cantidad)
    tiempo_desde_ultimo_gasto_pe = 0.0
    tiempo_para_siguiente_pulso_pe = 0.0
    actualizar_interfaz()
    print("PE CONSUMIDOS: ", roundi(cantidad), " | PE: ", roundi(pe_actual), "/", pe_maximo)
    return true
func recuperar_pe(cantidad: float) -> void:
    if cantidad <= 0.0:
        return
    pe_actual = minf(float(pe_maximo), pe_actual + cantidad)
    actualizar_interfaz()
func regenerar_pe(delta: float) -> void:
    if esta_muerto:
        return
    if pe_actual >= float(pe_maximo):
        pe_actual = float(pe_maximo)
        tiempo_para_siguiente_pulso_pe = 0.0
        return
    tiempo_desde_ultimo_gasto_pe += delta
    # Después de gastar Energía, espera 5 segundos completos.
    if tiempo_desde_ultimo_gasto_pe < espera_para_regenerar_pe:
        tiempo_para_siguiente_pulso_pe = 0.0
        return
    # A partir de ahí, recupera 1 punto cada 2 segundos.
    tiempo_para_siguiente_pulso_pe += delta
    if tiempo_para_siguiente_pulso_pe < intervalo_regeneracion_pe:
        return
    var pulsos: int = int(
        floor(tiempo_para_siguiente_pulso_pe / intervalo_regeneracion_pe)
    )
    tiempo_para_siguiente_pulso_pe -= (
        float(pulsos) * intervalo_regeneracion_pe
    )
    pe_actual = minf(
        float(pe_maximo),
        pe_actual + float(pulsos * regeneracion_pe_por_pulso)
    )
    actualizar_interfaz()
# =========================================================
# RESPAWN Y CHECKPOINT
# =========================================================
@export var tiempo_respawn: float = 3.0
var posicion_respawn_actual: Vector3
var checkpoint_actual: Vector3
var checkpoint_activado: bool = false
# =========================================================
# NIVEL Y EXPERIENCIA
# =========================================================
@export var nivel: int = 1
@export var experiencia_para_siguiente_nivel: int = 100
var experiencia_actual: int = 0
# =========================================================
# APARIENCIA
# =========================================================
@export var color_piel: Color = Color("#C98F65")
@export var color_camisa: Color = Color("#244A73")
@export var color_pantalon: Color = Color("#2F3540")
# =========================================================
# VARIABLES GENERALES
# =========================================================
var gravity: float = ProjectSettings.get_setting(
    "physics/3d/default_gravity"
)
var attack_timer: float = 0.0
# =========================================================
# COMPAÑERO - CADEJO BLANCO
# =========================================================
var cadejo_blanco_activo: Node3D = null
# El tiempo de recuperación se conserva en el héroe, aunque el Cadejo desaparezca.
@export var tiempo_recuperacion_cadejo: float = 30.0
var recarga_cadejo_restante: float = 0.0
# HABILIDAD ACTIVA - CARTA CENIZA DEL CIPITÍO
@export var costo_pe_ceniza_carta: float = 30.0
@export var alcance_ceniza_carta: float = 8.0
@export var duracion_ceniza_carta: float = 6.0
@export var reduccion_ceniza_carta: float = 0.55
@export var recarga_ceniza_carta: float = 20.0
var recarga_actual_ceniza_carta: float = 0.0
# EFECTO DE CENIZA MÁGICA
var tiempo_ceniza: float = 0.0
var multiplicador_velocidad_ceniza: float = 1.0
func aplicar_ceniza_magica(duracion: float = 4.0, reduccion: float = 0.30) -> void:
    if esta_muerto or en_zona_segura:
        return
    tiempo_ceniza = max(tiempo_ceniza, duracion)
    multiplicador_velocidad_ceniza = clampf(1.0 - reduccion, 0.1, 1.0)
    print("CENIZA MÁGICA: velocidad reducida durante ", duracion, " segundos")
func limpiar_ceniza_magica() -> void:
    tiempo_ceniza = 0.0
    multiplicador_velocidad_ceniza = 1.0
# =========================================================
# NODOS
# =========================================================
@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var cabeza: MeshInstance3D = $Cabeza
@onready var brazo_izquierdo: MeshInstance3D = $BrazoIzquierdo
@onready var brazo_derecho: MeshInstance3D = $BrazoDerecho
@onready var cuerpo: MeshInstance3D = $Cuerpo
@onready var pierna_izquierda: MeshInstance3D = $PiernaIzquierda
@onready var pierna_derecha: MeshInstance3D = $PiernaDerecha
@onready var nombre_label: Label3D = $NombreHeroe
@onready var barra_vida: ProgressBar = get_node("../Interfaz/BarraVida")
@onready var texto_vida: Label = get_node("../Interfaz/TextoVida")
@onready var texto_nivel: Label = get_node("../Interfaz/TextoNivel")
@onready var texto_experiencia: Label = get_node("../Interfaz/TextoExperiencia")
@onready var barra_experiencia: ProgressBar = get_node("../Interfaz/BarraExperiencia")
@onready var texto_derrota: Label = get_node("../Interfaz/TextoDerrota")
@onready var punto_respawn: Marker3D = get_node("../PuntoRespawn")
var barra_pe: ProgressBar
var texto_pe: Label
# =========================================================
# INICIO
# =========================================================
func _ready() -> void:
    # Escuchar cambios de equipo y refinado durante toda la partida.
    if not DatosJugador.equipamiento_actualizado.is_connected(al_cambiar_equipamiento):
        DatosJugador.equipamiento_actualizado.connect(al_cambiar_equipamiento)
    if not DatosJugador.companero_actualizado.is_connected(al_actualizar_companero):
        DatosJugador.companero_actualizado.connect(al_actualizar_companero)
    if not DatosJugador.tecomate_actualizado.is_connected(al_actualizar_tecomate):
        DatosJugador.tecomate_actualizado.connect(al_actualizar_tecomate)
    call_deferred("al_actualizar_companero", DatosJugador.obtener_companero_activo())
    vida_actual = vida_maxima
    pe_actual = float(pe_maximo)
    tiempo_desde_ultimo_gasto_pe = espera_para_regenerar_pe
    tiempo_para_siguiente_pulso_pe = 0.0
    crear_interfaz_pe()
    limpiar_ceniza_magica()
    esta_muerto = false
    en_zona_segura = false
    temporizador_regeneracion = 0.0
    tiempo_desde_ultimo_dano = espera_para_regenerar
    if punto_respawn != null:
        posicion_respawn_actual = punto_respawn.global_position
    else:
        posicion_respawn_actual = global_position
    color_piel = DatosJugador.color_piel
    color_camisa = DatosJugador.color_camisa
    color_pantalon = DatosJugador.color_pantalon
    aplicar_colores_personaje()
    if nombre_label != null:
        nombre_label.text = DatosJugador.nombre
    if texto_derrota != null:
        texto_derrota.visible = false
    actualizar_interfaz()
    print("==============================")
    print("HÉROE CARGADO EN EL MAPA")
    print("Nombre: ", DatosJugador.nombre)
    print("País: ", DatosJugador.pais)
    print("Nivel: ", nivel)
    print("Experiencia: ", experiencia_actual, "/", experiencia_para_siguiente_nivel)
    print("Vida: ", vida_actual, "/", vida_maxima)
    print("PE: ", roundi(pe_actual), "/", pe_maximo)
    print("Daño: ", dano)
    print("Defensa base: ", defensa)
    print("Defensa de guantes: ", DatosJugador.obtener_defensa_guantes_puestos())
    print("Defensa total: ", obtener_defensa_total())
    print("Respawn inicial: ", posicion_respawn_actual)
    print("==============================")
# =========================================================
# ZONA SEGURA
# =========================================================
func entrar_zona_segura() -> void:
    if en_zona_segura:
        return
    en_zona_segura = true
    print("================================")
    print("ZONA SEGURA ACTIVADA")
    print("El héroe no puede recibir daño.")
    print("================================")
func salir_zona_segura() -> void:
    if not en_zona_segura:
        return
    en_zona_segura = false
    print("================================")
    print("ZONA SEGURA DESACTIVADA")
    print("El héroe vuelve a ser vulnerable.")
    print("================================")
func esta_en_zona_segura() -> bool:
    return en_zona_segura
# =========================================================
# CHECKPOINT
# =========================================================
func activar_checkpoint(nueva_posicion: Vector3) -> void:
    if checkpoint_activado:
        if checkpoint_actual.distance_to(nueva_posicion) < 0.01:
            return
    checkpoint_activado = true
    checkpoint_actual = nueva_posicion
    posicion_respawn_actual = nueva_posicion
    print("================================")
    print("CHECKPOINT ACTIVADO")
    print("Nuevo punto de respawn: ", posicion_respawn_actual)
    print("================================")
# =========================================================
# VIDA Y DEFENSA
# =========================================================
func recibir_dano(cantidad: int) -> void:
    if esta_muerto:
        return
    if en_zona_segura:
        return
    var dano_final: int = max(cantidad - obtener_defensa_total(), 1)
    vida_actual -= dano_final
    if vida_actual < 0:
        vida_actual = 0
    tiempo_desde_ultimo_dano = 0.0
    temporizador_regeneracion = 0.0
    actualizar_interfaz()
    if vida_actual <= 0:
        morir()
# =========================================================
# REGENERACIÓN
# =========================================================
func regenerar_vida(delta: float) -> void:
    if esta_muerto:
        return
    if vida_actual >= vida_maxima:
        return
    tiempo_desde_ultimo_dano += delta
    if tiempo_desde_ultimo_dano < espera_para_regenerar:
        return
    temporizador_regeneracion += delta
    if temporizador_regeneracion >= 1.0:
        vida_actual += regeneracion_por_segundo
        if vida_actual > vida_maxima:
            vida_actual = vida_maxima
        actualizar_interfaz()
        temporizador_regeneracion = 0.0
# =========================================================
# MUERTE Y RESPAWN
# =========================================================
func morir() -> void:
    if esta_muerto:
        return
    esta_muerto = true
    limpiar_ceniza_magica()
    vida_actual = 0
    velocity = Vector3.ZERO
    actualizar_interfaz()
    if texto_derrota != null:
        texto_derrota.visible = true
    print("==============================")
    print("HÉROE DERROTADO")
    print("Reapareciendo en ", tiempo_respawn, " segundos...")
    print("==============================")
    await get_tree().create_timer(tiempo_respawn).timeout
    respawn()
func respawn() -> void:
    global_position = posicion_respawn_actual
    vida_actual = vida_maxima
    pe_actual = float(pe_maximo)
    tiempo_desde_ultimo_gasto_pe = espera_para_regenerar_pe
    limpiar_ceniza_magica()
    esta_muerto = false
    temporizador_regeneracion = 0.0
    tiempo_desde_ultimo_dano = espera_para_regenerar
    velocity = Vector3.ZERO
    if texto_derrota != null:
        texto_derrota.visible = false
    actualizar_interfaz()
    print("==============================")
    print("HÉROE REAPARECIÓ")
    print("Posición: ", global_position)
    print("Vida: ", vida_actual, "/", vida_maxima)
    print("==============================")
# =========================================================
# EXPERIENCIA
# =========================================================
func recibir_experiencia(cantidad: int) -> void:
    if cantidad <= 0:
        return
    experiencia_actual += cantidad
    print("==============================")
    print("+", cantidad, " XP")
    print("EXPERIENCIA: ", experiencia_actual, "/", experiencia_para_siguiente_nivel)
    print("==============================")
    comprobar_subida_nivel()
    actualizar_interfaz()
func ganar_experiencia(cantidad: int) -> void:
    recibir_experiencia(cantidad)
func comprobar_subida_nivel() -> void:
    while experiencia_actual >= experiencia_para_siguiente_nivel:
        experiencia_actual -= experiencia_para_siguiente_nivel
        subir_nivel()
# =========================================================
# SUBIR DE NIVEL
# =========================================================
func subir_nivel() -> void:
    nivel += 1
    vida_maxima += 10
    dano += 2
    defensa += 1
    vida_actual = vida_maxima
    experiencia_para_siguiente_nivel += 50
    actualizar_interfaz()
    print("")
    print("================================")
    print("¡SUBIDA DE NIVEL!")
    print("NIVEL: ", nivel)
    print("VIDA MÁXIMA: ", vida_maxima)
    print("DAÑO: ", dano)
    print("DEFENSA TOTAL: ", obtener_defensa_total())
    print("SIGUIENTE NIVEL: ", experiencia_actual, "/", experiencia_para_siguiente_nivel, " XP")
    print("================================")
    print("")
# =========================================================
# INTERFAZ
# =========================================================
func actualizar_interfaz() -> void:
    if barra_vida != null:
        barra_vida.min_value = 0
        barra_vida.max_value = vida_maxima
        barra_vida.value = vida_actual
    if texto_vida != null:
        texto_vida.text = "%d / %d" % [
            vida_actual,
            vida_maxima
        ]
    if texto_nivel != null:
        texto_nivel.text = "Nivel %d" % nivel
    if texto_experiencia != null:
        texto_experiencia.text = "XP %d / %d" % [
            experiencia_actual,
            experiencia_para_siguiente_nivel
        ]
    if barra_experiencia != null:
        barra_experiencia.min_value = 0
        barra_experiencia.max_value = experiencia_para_siguiente_nivel
        barra_experiencia.value = experiencia_actual
    if barra_pe != null:
        barra_pe.min_value = 0
        barra_pe.max_value = pe_maximo
        barra_pe.value = pe_actual
    if texto_pe != null:
        texto_pe.text = "%d / %d" % [roundi(pe_actual), pe_maximo]
# =========================================================
# INTERFAZ DE PE
# =========================================================
func crear_interfaz_pe() -> void:
    var interfaz: CanvasLayer = get_node_or_null("../Interfaz") as CanvasLayer
    if interfaz == null:
        push_warning("No se encontró ../Interfaz como CanvasLayer.")
        return
    barra_pe = interfaz.get_node_or_null("BarraPE") as ProgressBar
    texto_pe = interfaz.get_node_or_null("TextoPE") as Label
    # -------------------------
    # VIDA
    # -------------------------
    var titulo_vida := interfaz.get_node_or_null("TituloVida") as Label
    if titulo_vida == null:
        titulo_vida = Label.new()
        titulo_vida.name = "TituloVida"
        titulo_vida.mouse_filter = Control.MOUSE_FILTER_IGNORE
        interfaz.add_child(titulo_vida)
    titulo_vida.text = "VIDA"
    titulo_vida.position = barra_vida.position + Vector2(0, -44)
    titulo_vida.size = Vector2(barra_vida.size.x, 20)
    # Valor 100 / 100 entre el título y la barra.
    texto_vida.position = barra_vida.position + Vector2(0, -24)
    texto_vida.size = Vector2(barra_vida.size.x, 20)
    var vida_fondo := StyleBoxFlat.new()
    vida_fondo.bg_color = Color("#243126")
    vida_fondo.set_corner_radius_all(5)
    var vida_relleno := StyleBoxFlat.new()
    vida_relleno.bg_color = Color("#35C759")
    vida_relleno.set_corner_radius_all(5)
    barra_vida.add_theme_stylebox_override("background", vida_fondo)
    barra_vida.add_theme_stylebox_override("fill", vida_relleno)
    barra_vida.show_percentage = true
    # -------------------------
    # ENERGÍA
    # -------------------------
    if barra_pe == null:
        barra_pe = ProgressBar.new()
        barra_pe.name = "BarraPE"
        barra_pe.mouse_filter = Control.MOUSE_FILTER_IGNORE
        interfaz.add_child(barra_pe)
    # Dejamos un bloque completo debajo de VIDA:
    # título -> valor -> barra.
    barra_pe.position = barra_vida.position + Vector2(0, 77)
    barra_pe.size = barra_vida.size
    barra_pe.custom_minimum_size = barra_vida.custom_minimum_size
    barra_pe.show_percentage = true
    var titulo_energia := interfaz.get_node_or_null("TituloEnergia") as Label
    if titulo_energia == null:
        titulo_energia = Label.new()
        titulo_energia.name = "TituloEnergia"
        titulo_energia.mouse_filter = Control.MOUSE_FILTER_IGNORE
        interfaz.add_child(titulo_energia)
    titulo_energia.text = "ENERGÍA"
    titulo_energia.position = barra_pe.position + Vector2(0, -44)
    titulo_energia.size = Vector2(barra_pe.size.x, 20)
    if texto_pe == null:
        texto_pe = Label.new()
        texto_pe.name = "TextoPE"
        texto_pe.mouse_filter = Control.MOUSE_FILTER_IGNORE
        interfaz.add_child(texto_pe)
    texto_pe.position = barra_pe.position + Vector2(0, -24)
    texto_pe.size = Vector2(barra_pe.size.x, 20)
    texto_pe.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    texto_pe.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    var pe_fondo := StyleBoxFlat.new()
    pe_fondo.bg_color = Color("#1B2638")
    pe_fondo.set_corner_radius_all(5)
    var pe_relleno := StyleBoxFlat.new()
    pe_relleno.bg_color = Color("#2F80ED")
    pe_relleno.set_corner_radius_all(5)
    barra_pe.add_theme_stylebox_override("background", pe_fondo)
    barra_pe.add_theme_stylebox_override("fill", pe_relleno)
    # -------------------------
    # NIVEL / XP
    # -------------------------
    # Como insertamos ENERGÍA entre VIDA y XP, bajamos estos nodos
    # para que no se amontonen.
    var y_nivel := barra_pe.position.y + barra_pe.size.y + 12.0
    texto_nivel.position = Vector2(barra_pe.position.x, y_nivel)
    texto_nivel.size = Vector2(barra_pe.size.x, 22)
    texto_experiencia.position = Vector2(barra_pe.position.x, y_nivel + 25.0)
    texto_experiencia.size = Vector2(barra_pe.size.x, 22)
    barra_experiencia.position = Vector2(barra_pe.position.x, y_nivel + 49.0)
    barra_experiencia.size = barra_pe.size
    actualizar_interfaz()
# =========================================================
# APLICAR APARIENCIA
# =========================================================
func aplicar_colores_personaje() -> void:
    aplicar_color_piel()
    aplicar_color_camisa()
    aplicar_color_pantalon()
func aplicar_color_piel() -> void:
    var partes_piel = [
        cabeza,
        brazo_izquierdo,
        brazo_derecho
    ]
    for parte in partes_piel:
        if parte != null:
            var material = parte.get_surface_override_material(0)
            if material != null:
                material.albedo_color = color_piel
func aplicar_color_camisa() -> void:
    if cuerpo != null:
        var material = cuerpo.get_surface_override_material(0)
        if material != null:
            material.albedo_color = color_camisa
func aplicar_color_pantalon() -> void:
    var piernas = [
        pierna_izquierda,
        pierna_derecha
    ]
    for pierna in piernas:
        if pierna != null:
            var material = pierna.get_surface_override_material(0)
            if material != null:
                material.albedo_color = color_pantalon
# =========================================================
# HABILIDAD ACTIVA - CARTA CENIZA DEL CIPITÍO
# =========================================================
func puede_usar_ceniza_cipitio() -> bool:
    return (
        not esta_muerto
        and DatosJugador.carta_activa(DatosJugador.ID_CARTA_CENIZA)
        and recarga_actual_ceniza_carta <= 0.0
        and tiene_pe(costo_pe_ceniza_carta)
    )
func usar_ceniza_cipitio() -> void:
    if esta_muerto:
        return
    if not DatosJugador.carta_activa(DatosJugador.ID_CARTA_CENIZA):
        print("CENIZA DEL CIPITÍO: equipa la carta en los guantes que llevas puestos.")
        return
    if recarga_actual_ceniza_carta > 0.0:
        print("CENIZA DEL CIPITÍO EN RECARGA: %.1f s" % recarga_actual_ceniza_carta)
        return
    if not tiene_pe(costo_pe_ceniza_carta):
        print("CENIZA DEL CIPITÍO: ENERGÍA insuficiente.")
        return
    # Lanzar siempre cuesta energía, incluso si no alcanza a ningún enemigo.
    consumir_pe(costo_pe_ceniza_carta)
    recarga_actual_ceniza_carta = recarga_ceniza_carta
    crear_efecto_visual_ceniza()
    var afectados: int = 0
    var nodos: Array[Node] = []
    _recolectar_nodos_con_ceniza(get_tree().current_scene, nodos)
    for nodo in nodos:
        if nodo == null or not is_instance_valid(nodo) or not nodo is Node3D:
            continue
        var enemigo := nodo as Node3D
        var distancia := Vector2(
            global_position.x - enemigo.global_position.x,
            global_position.z - enemigo.global_position.z
        ).length()
        if distancia <= alcance_ceniza_carta:
            enemigo.aplicar_ceniza_jugador(duracion_ceniza_carta, reduccion_ceniza_carta)
            afectados += 1
    print("==============================")
    print("CENIZA DEL CIPITÍO ACTIVADA")
    print("ENERGÍA: ", roundi(pe_actual), "/", pe_maximo)
    print("RALENTIZACIÓN: 55% | DURACIÓN: 6 s | ALCANCE: 8 m")
    print("ENEMIGOS AFECTADOS: ", afectados)
    print("==============================")
func _recolectar_nodos_con_ceniza(nodo: Node, resultado: Array[Node]) -> void:
    if nodo != self and nodo.has_method("aplicar_ceniza_jugador"):
        resultado.append(nodo)
    for hijo in nodo.get_children():
        _recolectar_nodos_con_ceniza(hijo, resultado)
func crear_efecto_visual_ceniza() -> void:
    # Efecto legendario: onda expansiva + nube de ceniza + destellos espirituales.
    var contenedor := Node3D.new()
    contenedor.name = "EfectoLegendarioCartaCeniza"
    get_parent().add_child(contenedor)
    contenedor.global_position = global_position + Vector3(0.0, 0.10, 0.0)
    # -----------------------------------------------------
    # 1. ONDA EXPANSIVA SOBRE EL SUELO
    # -----------------------------------------------------
    var onda := MeshInstance3D.new()
    onda.name = "OndaCeniza"
    contenedor.add_child(onda)
    var disco := CylinderMesh.new()
    disco.top_radius = 1.0
    disco.bottom_radius = 1.0
    disco.height = 0.035
    disco.radial_segments = 64
    onda.mesh = disco
    var material_onda := StandardMaterial3D.new()
    material_onda.albedo_color = Color(0.32, 0.10, 0.42, 0.48)
    material_onda.emission_enabled = true
    material_onda.emission = Color(0.40, 0.08, 0.60)
    material_onda.emission_energy_multiplier = 1.8
    material_onda.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material_onda.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material_onda.cull_mode = BaseMaterial3D.CULL_DISABLED
    onda.material_override = material_onda
    onda.scale = Vector3(0.35, 1.0, 0.35)
    var tween_onda := create_tween()
    tween_onda.set_parallel(true)
    tween_onda.tween_property(
        onda,
        "scale",
        Vector3(alcance_ceniza_carta, 1.0, alcance_ceniza_carta),
        0.85
    ).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween_onda.tween_property(material_onda, "albedo_color:a", 0.0, 1.05)
    # -----------------------------------------------------
    # 2. NUBE DE CENIZA ALREDEDOR DEL HÉROE
    # -----------------------------------------------------
    var particulas := GPUParticles3D.new()
    particulas.name = "NubeCeniza"
    particulas.amount = 180
    particulas.lifetime = 1.35
    particulas.one_shot = true
    particulas.explosiveness = 0.92
    particulas.randomness = 0.65
    particulas.visibility_aabb = AABB(
        Vector3(-alcance_ceniza_carta, -2.0, -alcance_ceniza_carta),
        Vector3(alcance_ceniza_carta * 2.0, 5.0, alcance_ceniza_carta * 2.0)
    )
    var proceso := ParticleProcessMaterial.new()
    proceso.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    proceso.emission_sphere_radius = 0.9
    proceso.direction = Vector3(0.0, 0.35, 0.0)
    proceso.spread = 180.0
    proceso.initial_velocity_min = 3.5
    proceso.initial_velocity_max = 7.0
    proceso.gravity = Vector3(0.0, 0.45, 0.0)
    proceso.scale_min = 0.12
    proceso.scale_max = 0.34
    proceso.color = Color(0.18, 0.12, 0.20, 0.78)
    particulas.process_material = proceso
    var ceniza_mesh := QuadMesh.new()
    ceniza_mesh.size = Vector2(0.22, 0.22)
    var material_ceniza := StandardMaterial3D.new()
    material_ceniza.albedo_color = Color(0.22, 0.16, 0.24, 0.78)
    material_ceniza.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material_ceniza.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material_ceniza.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
    material_ceniza.cull_mode = BaseMaterial3D.CULL_DISABLED
    ceniza_mesh.material = material_ceniza
    particulas.draw_pass_1 = ceniza_mesh
    contenedor.add_child(particulas)
    particulas.position = Vector3(0.0, 0.75, 0.0)
    particulas.emitting = true
    # -----------------------------------------------------
    # 3. DESTELLOS VIOLETAS QUE MARCAN EL CARÁCTER LEGENDARIO
    # -----------------------------------------------------
    var destellos := GPUParticles3D.new()
    destellos.name = "DestellosEspirituales"
    destellos.amount = 42
    destellos.lifetime = 0.95
    destellos.one_shot = true
    destellos.explosiveness = 1.0
    destellos.randomness = 0.8
    destellos.visibility_aabb = particulas.visibility_aabb
    var proceso_destellos := ParticleProcessMaterial.new()
    proceso_destellos.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
    proceso_destellos.emission_sphere_radius = 0.65
    proceso_destellos.direction = Vector3(0.0, 0.25, 0.0)
    proceso_destellos.spread = 180.0
    proceso_destellos.initial_velocity_min = 4.5
    proceso_destellos.initial_velocity_max = 8.0
    proceso_destellos.gravity = Vector3(0.0, -0.25, 0.0)
    proceso_destellos.scale_min = 0.08
    proceso_destellos.scale_max = 0.18
    proceso_destellos.color = Color(0.72, 0.30, 1.0, 0.95)
    destellos.process_material = proceso_destellos
    var destello_mesh := SphereMesh.new()
    destello_mesh.radius = 0.07
    destello_mesh.height = 0.14
    destello_mesh.radial_segments = 8
    destello_mesh.rings = 4
    var material_destello := StandardMaterial3D.new()
    material_destello.albedo_color = Color(0.72, 0.30, 1.0, 0.95)
    material_destello.emission_enabled = true
    material_destello.emission = Color(0.65, 0.20, 1.0)
    material_destello.emission_energy_multiplier = 2.8
    material_destello.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material_destello.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    destello_mesh.material = material_destello
    destellos.draw_pass_1 = destello_mesh
    contenedor.add_child(destellos)
    destellos.position = Vector3(0.0, 0.9, 0.0)
    destellos.emitting = true
    # El contenedor vive lo suficiente para que terminen las partículas.
    get_tree().create_timer(2.0).timeout.connect(
        func() -> void:
            if is_instance_valid(contenedor):
                contenedor.queue_free()
    )
# =========================================================
# COMPAÑERO - CADEJO BLANCO
# =========================================================
# ACTIVAR SOLO PARA PROBAR EL CADEJO ANTES DE SU MISION DE CAPTURA.
# Cuando la captura esté implementada, cambiar a false.
@export var permitir_cadejo_blanco_en_pruebas: bool = true
func al_agotarse_cadejo_blanco() -> void:
    # Bloquear inmediatamente la invocación, incluso ante señales del inventario.
    if recarga_cadejo_restante > 0.0:
        return
    recarga_cadejo_restante = maxf(0.0, tiempo_recuperacion_cadejo)
    print("CADEJO BLANCO REGRESA AL TECOMATE | RECUPERACIÓN: %.0f s" % recarga_cadejo_restante)
    # La retirada normal libera la escena y mantiene sincronizado DatosJugador.
    DatosJugador.retirar_companero_activo()
    retirar_cadejo_blanco()

func actualizar_recuperacion_cadejo(delta: float) -> void:
    if recarga_cadejo_restante <= 0.0:
        return
    recarga_cadejo_restante = maxf(0.0, recarga_cadejo_restante - delta)
    if recarga_cadejo_restante <= 0.0:
        print("CADEJO BLANCO RECUPERADO: 300/300 | Pulsa R para invocarlo.")

func alternar_cadejo_blanco_prueba() -> void:
    if is_instance_valid(cadejo_blanco_activo):
        DatosJugador.retirar_companero_activo()
        retirar_cadejo_blanco()
        return
    if recarga_cadejo_restante > 0.0:
        print("CADEJO BLANCO AGOTADO: faltan %.1f segundos." % recarga_cadejo_restante)
        return
    if not DatosJugador.tecomate_esta_equipado():
        print("CADEJO BLANCO: equipa primero el Tecomate de los Espíritus.")
        return
    if not DatosJugador.companero_esta_desbloqueado("cadejo_blanco"):
        if permitir_cadejo_blanco_en_pruebas:
            DatosJugador.desbloquear_companero("cadejo_blanco")
            print("CADEJO BLANCO: desbloqueo temporal de pruebas activado.")
        else:
            print("CADEJO BLANCO: todavía no está desbloqueado.")
            return
    if not DatosJugador.seleccionar_companero("cadejo_blanco"):
        return
    invocar_cadejo_blanco()
func invocar_cadejo_blanco() -> void:
    if recarga_cadejo_restante > 0.0:
        return
    if is_instance_valid(cadejo_blanco_activo):
        return
    if not DatosJugador.tecomate_esta_equipado():
        return
    if DatosJugador.obtener_companero_activo() != "cadejo_blanco":
        return
    var escena_cadejo: PackedScene = load("res://CadejoBlanco.tscn")
    if escena_cadejo == null:
        push_warning("No se pudo cargar res://CadejoBlanco.tscn")
        DatosJugador.retirar_companero_activo()
        return
    var nuevo_cadejo: Node3D = escena_cadejo.instantiate() as Node3D
    if nuevo_cadejo == null:
        push_warning("La escena del Cadejo Blanco necesita una raíz Node3D.")
        DatosJugador.retirar_companero_activo()
        return
    get_parent().add_child(nuevo_cadejo)
    nuevo_cadejo.global_position = global_position + Vector3(1.8, 0.0, 1.8)
    if nuevo_cadejo.has_method("asignar_heroe"):
        nuevo_cadejo.asignar_heroe(self)
    cadejo_blanco_activo = nuevo_cadejo
    # Conectar la señal del Cadejo antes de iniciar cualquier combate.
    if nuevo_cadejo.has_signal("agotamiento_espiritual"):
        nuevo_cadejo.connect("agotamiento_espiritual", Callable(self, "al_agotarse_cadejo_blanco"))
    print("CADEJO BLANCO INVOCADO MEDIANTE EL TECOMATE")
func retirar_cadejo_blanco() -> void:
    if is_instance_valid(cadejo_blanco_activo):
        cadejo_blanco_activo.queue_free()
    cadejo_blanco_activo = null
    print("CADEJO BLANCO RETIRADO")
func al_actualizar_companero(id_companero: String) -> void:
    if id_companero == "cadejo_blanco" and DatosJugador.tecomate_esta_equipado():
        invocar_cadejo_blanco()
    else:
        retirar_cadejo_blanco()
func al_actualizar_tecomate() -> void:
    if not DatosJugador.tecomate_esta_equipado():
        retirar_cadejo_blanco()
    else:
        al_actualizar_companero(DatosJugador.obtener_companero_activo())
# =========================================================
# ATAQUE
# =========================================================
func _input(event: InputEvent) -> void:
    if esta_muerto:
        return
    if event is InputEventKey:
        if event.pressed and not event.echo and event.physical_keycode == KEY_Q:
            usar_ceniza_cipitio()
            return
        if event.pressed and not event.echo and event.physical_keycode == KEY_R:
            alternar_cadejo_blanco_prueba()
            return
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if attack_timer <= 0.0:
                attack_timer = attack_cooldown
                var area_ataque: Area3D = get_node_or_null("AreaAtaque")
                if area_ataque == null:
                    return
                var enemigo_mas_cercano: Node3D = null
                var distancia_mas_cercana: float = INF
                for body in area_ataque.get_overlapping_bodies():
                    if body == self:
                        continue
                    if not body.has_method("recibir_dano"):
                        continue
                    if not body is Node3D:
                        continue
                    var distancia: float = global_position.distance_to(body.global_position)
                    if distancia < distancia_mas_cercana:
                        distancia_mas_cercana = distancia
                        enemigo_mas_cercano = body
                if enemigo_mas_cercano != null:
                    enemigo_mas_cercano.recibir_dano(dano)
# =========================================================
# MOVIMIENTO
# =========================================================
func _physics_process(delta: float) -> void:
    # La recuperación continúa incluso si el héroe muere o está en Santuario.
    actualizar_recuperacion_cadejo(delta)
    if esta_muerto:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    regenerar_vida(delta)
    regenerar_pe(delta)
    if recarga_actual_ceniza_carta > 0.0:
        recarga_actual_ceniza_carta = maxf(0.0, recarga_actual_ceniza_carta - delta)
    if tiempo_ceniza > 0.0:
        tiempo_ceniza = maxf(0.0, tiempo_ceniza - delta)
        if tiempo_ceniza <= 0.0:
            limpiar_ceniza_magica()
            print("CENIZA MÁGICA: velocidad recuperada")
    var move_dir := Vector3.ZERO
    if camera != null:
        var cam_forward := -camera.global_basis.z
        var cam_right := camera.global_basis.x
        cam_forward.y = 0.0
        cam_right.y = 0.0
        cam_forward = cam_forward.normalized()
        cam_right = cam_right.normalized()
        if Input.is_physical_key_pressed(KEY_W):
            move_dir += cam_forward
        if Input.is_physical_key_pressed(KEY_S):
            move_dir -= cam_forward
        if Input.is_physical_key_pressed(KEY_A):
            move_dir -= cam_right
        if Input.is_physical_key_pressed(KEY_D):
            move_dir += cam_right
    else:
        if Input.is_physical_key_pressed(KEY_W):
            move_dir.z -= 1.0
        if Input.is_physical_key_pressed(KEY_S):
            move_dir.z += 1.0
        if Input.is_physical_key_pressed(KEY_A):
            move_dir.x -= 1.0
        if Input.is_physical_key_pressed(KEY_D):
            move_dir.x += 1.0
    if move_dir != Vector3.ZERO:
        move_dir = move_dir.normalized()
    velocity.x = move_dir.x * move_speed * multiplicador_velocidad_ceniza
    velocity.z = move_dir.z * move_speed * multiplicador_velocidad_ceniza
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    if attack_timer > 0.0:
        attack_timer -= delta
