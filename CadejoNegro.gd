extends CharacterBody3D
# =========================================================
# MUNDO_LEYENDAS - CADEJO NEGRO
# Boss de la zona del Cadejo Negro
# =========================================================
@export_group("Estadísticas")
@export var vida_maxima: int = 2000
@export var ataque_base: int = 40
@export var defensa: int = 15
@export_group("Combate")
@export var velocidad_fase_1: float = 3.4
@export var velocidad_fase_2: float = 4.6
@export var distancia_deteccion: float = 15.0
@export var distancia_ataque: float = 2.2
@export var radio_arena: float = 17.0
@export var tiempo_entre_ataques: float = 1.5
@export_group("Defensa contra compañeros")
@export var distancia_detectar_cadejo: float = 9.0
@export_group("Mirada de Brasas")
@export var alcance_mirada: float = 8.0
@export var duracion_mirada: float = 1.5
@export var recarga_mirada: float = 12.0
@export_group("Acecho Oscuro")
@export var alcance_acecho: float = 10.0
@export var distancia_reaparicion: float = 2.5
@export var recarga_acecho: float = 10.0
@export_group("Robo del Alma - Fase 2")
@export var alcance_robo_alma: float = 5.0
@export var dano_robo_alma: int = 15
@export var energia_robo_alma: int = 20
@export var recarga_robo_alma: float = 14.0
@export_group("Reaparición")
@export var tiempo_reaparicion: float = 60.0
@export_group("Recompensas")
@export var experiencia_victoria: int = 750
enum Estado {
    QUIETO,
    PERSIGUIENDO,
    REGRESANDO
}
var estado_actual: Estado = Estado.QUIETO
var vida_actual: int = 2000
var fase_actual: int = 1
var derrotado: bool = false
var heroe: CharacterBody3D = null
var cadejo_objetivo: CharacterBody3D = null
var posicion_inicial: Vector3
var capa_colision_inicial: int = 0
var mascara_colision_inicial: int = 0
var temporizador_ataque: float = 0.0
var temporizador_mirada: float = 4.0
var temporizador_acecho: float = 6.0
var temporizador_robo_alma: float = 8.0
var velocidad_actual: float = 3.4
var ataque_inicial: int = 40
# =========================================================
# RALENTIZACIÓN DE LA CARTA CENIZA DEL CIPITÍO
# =========================================================
var tiempo_ceniza_jugador: float = 0.0
var multiplicador_velocidad_ceniza_jugador: float = 1.0
var aura_ceniza_jugador: MeshInstance3D = null
# =========================================================
# INTERFAZ DEL BOSS
# =========================================================
@onready var vida_label: Label3D = get_node_or_null("VidaLabel") as Label3D
@onready var barra_relleno: MeshInstance3D = (
    get_node_or_null("BarraVidaRelleno") as MeshInstance3D
)
@onready var barra_fondo: MeshInstance3D = (
    get_node_or_null("BarraVidaFondo") as MeshInstance3D
)
const ANCHO_BARRA: float = 2.8
const ALTURA_BARRA: float = 4.8
const SEPARACION_BARRAS: float = 0.15
const ATAQUE_FASE_2: int = 60
func _ready() -> void:
    posicion_inicial = global_position
    capa_colision_inicial = collision_layer
    mascara_colision_inicial = collision_mask
    vida_actual = vida_maxima
    ataque_inicial = ataque_base
    velocidad_actual = velocidad_fase_1
    if barra_relleno != null:
        if barra_relleno.mesh != null:
            barra_relleno.mesh = barra_relleno.mesh.duplicate()
        if barra_relleno.material_override != null:
            barra_relleno.material_override = barra_relleno.material_override.duplicate()
    if barra_fondo != null:
        if barra_fondo.mesh != null:
            barra_fondo.mesh = barra_fondo.mesh.duplicate()
        if barra_fondo.material_override != null:
            barra_fondo.material_override = barra_fondo.material_override.duplicate()
    actualizar_interfaz()
    orientar_barras()
    print("==============================")
    print("CADEJO NEGRO DESPERTÓ")
    print("VIDA: ", vida_actual)
    print("ATAQUE: ", ataque_base)
    print("DEFENSA: ", defensa)
    print("POSICIÓN: ", posicion_inicial)
    print("==============================")
func _process(_delta: float) -> void:
    orientar_barras()
func _physics_process(delta: float) -> void:
    actualizar_ceniza_jugador(delta)
    if derrotado:
        return
    temporizador_ataque = maxf(0.0, temporizador_ataque - delta)
    temporizador_mirada = maxf(0.0, temporizador_mirada - delta)
    temporizador_acecho = maxf(0.0, temporizador_acecho - delta)
    temporizador_robo_alma = maxf(0.0, temporizador_robo_alma - delta)
    if not is_instance_valid(heroe):
        buscar_heroe()
    if not is_instance_valid(heroe):
        velocity = Vector3.ZERO
        aplicar_gravedad(delta)
        move_and_slide()
        return
    var distancia_heroe: float = distancia_horizontal(global_position, heroe.global_position)
    var distancia_heroe_centro: float = distancia_horizontal(posicion_inicial, heroe.global_position)
    var distancia_jefe_centro: float = distancia_horizontal(posicion_inicial, global_position)
    var heroe_no_disponible: bool = heroe_no_es_objetivo()
    match estado_actual:
        Estado.QUIETO:
            velocity.x = 0.0
            velocity.z = 0.0
            if heroe_no_disponible or distancia_heroe_centro > radio_arena:
                aplicar_gravedad(delta)
                move_and_slide()
                return
            if distancia_heroe <= distancia_deteccion:
                estado_actual = Estado.PERSIGUIENDO
                print("CADEJO NEGRO DETECTÓ AL HÉROE")
        Estado.PERSIGUIENDO:
            if heroe_no_disponible or distancia_heroe_centro > radio_arena or distancia_jefe_centro > radio_arena:
                cadejo_objetivo = null
                comenzar_regreso()
                aplicar_gravedad(delta)
                move_and_slide()
                return
            cadejo_objetivo = buscar_cadejo_blanco()
            var objetivo: CharacterBody3D = heroe
            if is_instance_valid(cadejo_objetivo):
                objetivo = cadejo_objetivo
            var distancia_objetivo: float = distancia_horizontal(global_position, objetivo.global_position)
            if distancia_objetivo > distancia_ataque:
                mover_hacia_objetivo(objetivo.global_position)
            else:
                velocity.x = 0.0
                velocity.z = 0.0
                mirar_hacia(objetivo.global_position)
                atacar_objetivo(objetivo)
            # Las habilidades especiales originales siguen apuntando al héroe.
            intentar_mirada_brasas(distancia_heroe)
            intentar_acecho_oscuro(distancia_heroe)
            intentar_robo_alma(distancia_heroe)
        Estado.REGRESANDO:
            var distancia_regreso: float = distancia_horizontal(global_position, posicion_inicial)
            if distancia_regreso <= 0.35:
                global_position = posicion_inicial
                velocity = Vector3.ZERO
                restaurar_jefe()
                aplicar_gravedad(delta)
                move_and_slide()
                return
            mover_hacia_posicion(posicion_inicial)
    aplicar_gravedad(delta)
    move_and_slide()
func buscar_cadejo_blanco() -> CharacterBody3D:
    if not is_instance_valid(heroe):
        return null
    var candidato: Variant = heroe.get("cadejo_blanco_activo")
    if not (candidato is CharacterBody3D):
        return null
    var cadejo: CharacterBody3D = candidato as CharacterBody3D
    if not is_instance_valid(cadejo) or not cadejo.is_inside_tree():
        return null
    if cadejo.get("esta_muerto") == true or cadejo.get("derrotado") == true:
        return null
    if distancia_horizontal(posicion_inicial, cadejo.global_position) > radio_arena:
        return null
    if distancia_horizontal(global_position, cadejo.global_position) > distancia_detectar_cadejo:
        return null
    return cadejo
func mover_hacia_objetivo(destino: Vector3) -> void:
    var direccion: Vector3 = destino - global_position
    direccion.y = 0.0
    if direccion.length() <= 0.001:
        velocity.x = 0.0
        velocity.z = 0.0
        return
    direccion = direccion.normalized()
    var velocidad_final: float = velocidad_actual * multiplicador_velocidad_ceniza_jugador
    velocity.x = direccion.x * velocidad_final
    velocity.z = direccion.z * velocidad_final
    mirar_hacia(destino)
func atacar_objetivo(objetivo: CharacterBody3D) -> void:
    if temporizador_ataque > 0.0 or not is_instance_valid(objetivo):
        return
    if objetivo == heroe:
        atacar_heroe()
        return
    if not objetivo.has_method("recibir_dano"):
        return
    if objetivo.get("esta_muerto") == true or objetivo.get("derrotado") == true:
        return
    objetivo.recibir_dano(ataque_base)
    temporizador_ataque = tiempo_entre_ataques
    print("CADEJO NEGRO MORDIÓ AL CADEJO BLANCO | DAÑO BASE: ", ataque_base)
# =========================================================
# HÉROE
# =========================================================
func buscar_heroe() -> void:
    var heroes := get_tree().get_nodes_in_group(
        "heroe"
    )
    if heroes.is_empty():
        return
    heroe = heroes[0] as CharacterBody3D
func heroe_no_es_objetivo() -> bool:
    if not is_instance_valid(heroe):
        return true
    if heroe.get("esta_muerto") == true:
        return true
    if (
        heroe.has_method("esta_en_zona_segura")
        and heroe.esta_en_zona_segura()
    ):
        return true
    return false
# =========================================================
# MOVIMIENTO
# =========================================================
func distancia_horizontal(
    origen: Vector3,
    destino: Vector3
) -> float:
    var diferencia := destino - origen
    diferencia.y = 0.0
    return diferencia.length()
func mover_hacia_heroe() -> void:
    if not is_instance_valid(heroe):
        return
    var direccion := (
        heroe.global_position
        - global_position
    )
    direccion.y = 0.0
    if direccion.length() <= 0.001:
        return
    direccion = direccion.normalized()
    var velocidad_final := (
        velocidad_actual
        * multiplicador_velocidad_ceniza_jugador
    )
    velocity.x = (
        direccion.x
        * velocidad_final
    )
    velocity.z = (
        direccion.z
        * velocidad_final
    )
    mirar_hacia(
        heroe.global_position
    )
func mover_hacia_posicion(
    destino: Vector3
) -> void:
    var direccion := (
        destino
        - global_position
    )
    direccion.y = 0.0
    if direccion.length() <= 0.001:
        velocity.x = 0.0
        velocity.z = 0.0
        return
    direccion = direccion.normalized()
    var velocidad_final := (
        velocidad_fase_1
        * multiplicador_velocidad_ceniza_jugador
    )
    velocity.x = (
        direccion.x
        * velocidad_final
    )
    velocity.z = (
        direccion.z
        * velocidad_final
    )
func mirar_hacia(
    objetivo: Vector3
) -> void:
    var posicion_objetivo := Vector3(
        objetivo.x,
        global_position.y,
        objetivo.z
    )
    if (
        global_position.distance_to(
            posicion_objetivo
        )
        <= 0.01
    ):
        return
    look_at(
        posicion_objetivo,
        Vector3.UP
    )
func aplicar_gravedad(
    delta: float
) -> void:
    if not is_on_floor():
        velocity.y -= (
            9.8
            * delta
        )
    else:
        velocity.y = 0.0
# =========================================================
# ATAQUE NORMAL
# =========================================================
func atacar_heroe() -> void:
    if temporizador_ataque > 0.0:
        return
    if heroe_no_es_objetivo():
        return
    if not heroe.has_method(
        "recibir_dano"
    ):
        return
    heroe.recibir_dano(
        ataque_base
    )
    temporizador_ataque = (
        tiempo_entre_ataques
    )
    print(
        "CADEJO NEGRO MORDIÓ AL HÉROE | DAÑO: ",
        ataque_base
    )
# =========================================================
# MIRADA DE BRASAS
# =========================================================
func intentar_mirada_brasas(
    distancia: float
) -> void:
    if temporizador_mirada > 0.0:
        return
    if distancia > alcance_mirada:
        return
    if heroe_no_es_objetivo():
        return
    temporizador_mirada = (
        recarga_mirada
    )
    crear_efecto_mirada()
    if heroe.has_method(
        "aplicar_ceniza_magica"
    ):
        # Por ahora reutilizamos el sistema de reducción
        # de movimiento que ya existe en el héroe.
        # Posteriormente podemos crear inmovilización real.
        heroe.aplicar_ceniza_magica(
            duracion_mirada,
            0.90
        )
    print("==============================")
    print("¡MIRADA DE BRASAS!")
    print(
        "El Cadejo Negro paraliza al héroe durante ",
        duracion_mirada,
        " s"
    )
    print("==============================")
func crear_efecto_mirada() -> void:
    var escena := get_tree().current_scene
    if escena == null:
        return
    var esfera := MeshInstance3D.new()
    esfera.name = "MiradaBrasas"
    var mesh := SphereMesh.new()
    mesh.radius = 0.45
    mesh.height = 0.9
    mesh.radial_segments = 24
    mesh.rings = 12
    esfera.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(
        1.0,
        0.05,
        0.01,
        0.75
    )
    material.emission_enabled = true
    material.emission = Color(
        1.0,
        0.02,
        0.0
    )
    material.emission_energy_multiplier = 5.0
    material.transparency = (
        BaseMaterial3D.TRANSPARENCY_ALPHA
    )
    material.shading_mode = (
        BaseMaterial3D.SHADING_MODE_UNSHADED
    )
    esfera.material_override = material
    escena.add_child(
        esfera
    )
    esfera.global_position = (
        global_position
        + Vector3(
            0.0,
            2.3,
            0.0
        )
    )
    var tween := create_tween()
    tween.tween_property(
        esfera,
        "scale",
        Vector3(
            2.5,
            2.5,
            2.5
        ),
        0.35
    )
    tween.parallel().tween_property(
        material,
        "albedo_color:a",
        0.0,
        0.6
    )
    tween.finished.connect(
        esfera.queue_free
    )
# =========================================================
# ACECHO OSCURO
# =========================================================
func intentar_acecho_oscuro(
    distancia: float
) -> void:
    if temporizador_acecho > 0.0:
        return
    if distancia > alcance_acecho:
        return
    if distancia < 4.0:
        return
    if heroe_no_es_objetivo():
        return
    temporizador_acecho = (
        recarga_acecho
    )
    crear_efecto_oscuridad(
        global_position
    )
    var direccion_heroe := (
        heroe.global_position
        - global_position
    )
    direccion_heroe.y = 0.0
    if direccion_heroe.length() <= 0.001:
        return
    direccion_heroe = (
        direccion_heroe.normalized()
    )
    var posicion_destino := (
        heroe.global_position
        - direccion_heroe
        * distancia_reaparicion
    )
    posicion_destino.y = (
        global_position.y
    )
    global_position = (
        posicion_destino
    )
    velocity = Vector3.ZERO
    mirar_hacia(
        heroe.global_position
    )
    crear_efecto_oscuridad(
        global_position
    )
    print("==============================")
    print("¡ACECHO OSCURO!")
    print(
        "El Cadejo Negro apareció junto al héroe."
    )
    print("==============================")
func crear_efecto_oscuridad(
    posicion: Vector3
) -> void:
    var escena := get_tree().current_scene
    if escena == null:
        return
    var nube := MeshInstance3D.new()
    nube.name = "NubeOscura"
    var esfera := SphereMesh.new()
    esfera.radius = 1.0
    esfera.height = 2.0
    nube.mesh = esfera
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(
        0.03,
        0.01,
        0.05,
        0.70
    )
    material.transparency = (
        BaseMaterial3D.TRANSPARENCY_ALPHA
    )
    material.shading_mode = (
        BaseMaterial3D.SHADING_MODE_UNSHADED
    )
    nube.material_override = material
    escena.add_child(
        nube
    )
    nube.global_position = (
        posicion
        + Vector3(
            0.0,
            1.0,
            0.0
        )
    )
    var tween := create_tween()
    tween.tween_property(
        nube,
        "scale",
        Vector3(
            2.5,
            2.0,
            2.5
        ),
        0.65
    )
    tween.parallel().tween_property(
        material,
        "albedo_color:a",
        0.0,
        0.65
    )
    tween.finished.connect(
        nube.queue_free
    )
# =========================================================
# ROBO DEL ALMA
# SOLO FASE 2
# =========================================================
func intentar_robo_alma(
    distancia: float
) -> void:
    if fase_actual != 2:
        return
    if temporizador_robo_alma > 0.0:
        return
    if distancia > alcance_robo_alma:
        return
    if heroe_no_es_objetivo():
        return
    temporizador_robo_alma = (
        recarga_robo_alma
    )
    crear_efecto_robo_alma()
    if heroe.has_method(
        "recibir_dano"
    ):
        heroe.recibir_dano(
            dano_robo_alma
        )
    if (
        not heroe_no_es_objetivo()
        and heroe.has_method(
            "consumir_energia"
        )
    ):
        heroe.consumir_energia(
            energia_robo_alma
        )
    print("==============================")
    print("¡ROBO DEL ALMA!")
    print(
        "DAÑO: ",
        dano_robo_alma,
        " | PE DRENADOS: ",
        energia_robo_alma
    )
    print("==============================")
func crear_efecto_robo_alma() -> void:
    var escena := get_tree().current_scene
    if escena == null:
        return
    var aura := MeshInstance3D.new()
    aura.name = "RoboAlma"
    var esfera := SphereMesh.new()
    esfera.radius = 1.0
    esfera.height = 2.0
    aura.mesh = esfera
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(
        0.25,
        0.0,
        0.35,
        0.55
    )
    material.emission_enabled = true
    material.emission = Color(
        0.55,
        0.0,
        0.75
    )
    material.emission_energy_multiplier = 3.0
    material.transparency = (
        BaseMaterial3D.TRANSPARENCY_ALPHA
    )
    material.shading_mode = (
        BaseMaterial3D.SHADING_MODE_UNSHADED
    )
    aura.material_override = material
    escena.add_child(
        aura
    )
    aura.global_position = (
        heroe.global_position
        + Vector3(
            0.0,
            1.0,
            0.0
        )
    )
    var tween := create_tween()
    tween.tween_property(
        aura,
        "scale",
        Vector3(
            3.0,
            3.0,
            3.0
        ),
        0.8
    )
    tween.parallel().tween_property(
        material,
        "albedo_color:a",
        0.0,
        0.8
    )
    tween.finished.connect(
        aura.queue_free
    )
# =========================================================
# CARTA CENIZA DEL CIPITÍO
# =========================================================
func aplicar_ceniza_jugador(
    duracion: float = 6.0,
    reduccion: float = 0.55
) -> void:
    if derrotado:
        return
    tiempo_ceniza_jugador = maxf(
        tiempo_ceniza_jugador,
        duracion
    )
    multiplicador_velocidad_ceniza_jugador = minf(
        multiplicador_velocidad_ceniza_jugador,
        clampf(
            1.0 - reduccion,
            0.1,
            1.0
        )
    )
    crear_aura_ceniza_jugador()
    print(
        "CADEJO NEGRO AFECTADO POR CENIZA DEL CIPITÍO | ",
        roundi(
            reduccion * 100.0
        ),
        "% | ",
        duracion,
        " s"
    )
func actualizar_ceniza_jugador(
    delta: float
) -> void:
    if tiempo_ceniza_jugador <= 0.0:
        return
    tiempo_ceniza_jugador = maxf(
        0.0,
        tiempo_ceniza_jugador - delta
    )
    if tiempo_ceniza_jugador <= 0.0:
        multiplicador_velocidad_ceniza_jugador = 1.0
        eliminar_aura_ceniza_jugador()
        print(
            "CADEJO NEGRO RECUPERÓ SU VELOCIDAD"
        )
func crear_aura_ceniza_jugador() -> void:
    eliminar_aura_ceniza_jugador()
    aura_ceniza_jugador = (
        MeshInstance3D.new()
    )
    aura_ceniza_jugador.name = (
        "AuraCartaCeniza"
    )
    var esfera := SphereMesh.new()
    esfera.radius = 1.2
    esfera.height = 2.4
    esfera.radial_segments = 32
    esfera.rings = 16
    aura_ceniza_jugador.mesh = (
        esfera
    )
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(
        0.42,
        0.20,
        0.55,
        0.32
    )
    material.transparency = (
        BaseMaterial3D.TRANSPARENCY_ALPHA
    )
    material.shading_mode = (
        BaseMaterial3D.SHADING_MODE_UNSHADED
    )
    material.cull_mode = (
        BaseMaterial3D.CULL_DISABLED
    )
    aura_ceniza_jugador.material_override = (
        material
    )
    add_child(
        aura_ceniza_jugador
    )
    aura_ceniza_jugador.position = Vector3(
        0.0,
        1.25,
        0.0
    )
    aura_ceniza_jugador.scale = Vector3(
        1.4,
        1.7,
        1.4
    )
    var tween := create_tween()
    tween.set_loops()
    tween.tween_property(
        aura_ceniza_jugador,
        "scale",
        Vector3(
            1.6,
            1.9,
            1.6
        ),
        0.65
    )
    tween.tween_property(
        aura_ceniza_jugador,
        "scale",
        Vector3(
            1.4,
            1.7,
            1.4
        ),
        0.65
    )
func eliminar_aura_ceniza_jugador() -> void:
    if is_instance_valid(
        aura_ceniza_jugador
    ):
        aura_ceniza_jugador.queue_free()
    aura_ceniza_jugador = null
func limpiar_ceniza_jugador() -> void:
    tiempo_ceniza_jugador = 0.0
    multiplicador_velocidad_ceniza_jugador = 1.0
    eliminar_aura_ceniza_jugador()
# =========================================================
# DAÑO / VIDA
# =========================================================
func recibir_dano(
    cantidad: int
) -> void:
    if derrotado:
        return
    var dano_real := maxi(
        1,
        cantidad - defensa
    )
    vida_actual = maxi(
        0,
        vida_actual - dano_real
    )
    print(
        "CADEJO NEGRO RECIBIÓ DAÑO: ",
        dano_real,
        " | VIDA: ",
        vida_actual,
        "/",
        vida_maxima
    )
    actualizar_interfaz()
    if vida_actual <= 0:
        morir()
        return
    if (
        fase_actual == 1
        and vida_actual <= vida_maxima / 2.0
    ):
        activar_segunda_fase()
func esta_muerto() -> bool:
    return derrotado
# =========================================================
# SEGUNDA FASE
# =========================================================
func activar_segunda_fase() -> void:
    fase_actual = 2
    ataque_base = ATAQUE_FASE_2
    velocidad_actual = velocidad_fase_2
    temporizador_robo_alma = 2.0
    if barra_relleno != null:
        var material := (
            barra_relleno.material_override
            as StandardMaterial3D
        )
        if material != null:
            material.albedo_color = Color(
                0.55,
                0.0,
                0.0,
                1.0
            )
    crear_efecto_oscuridad(
        global_position
    )
    print("==============================")
    print("¡CADEJO NEGRO - SEGUNDA FASE!")
    print("ATAQUE: ", ataque_base)
    print("VELOCIDAD: ", velocidad_actual)
    print(
        "ROBO DEL ALMA DISPONIBLE EN 2 SEGUNDOS"
    )
    print("==============================")
# =========================================================
# REGRESO A LA ARENA
# =========================================================
func comenzar_regreso() -> void:
    if estado_actual == Estado.REGRESANDO:
        return
    estado_actual = Estado.REGRESANDO
    velocity = Vector3.ZERO
    print(
        "EL CADEJO NEGRO REGRESA A SU TERRITORIO"
    )
func restaurar_jefe() -> void:
    cadejo_objetivo = null
    limpiar_ceniza_jugador()
    estado_actual = Estado.QUIETO
    fase_actual = 1
    vida_actual = vida_maxima
    ataque_base = ataque_inicial
    velocidad_actual = velocidad_fase_1
    temporizador_ataque = 0.0
    temporizador_mirada = 4.0
    temporizador_acecho = 6.0
    temporizador_robo_alma = 8.0
    if barra_relleno != null:
        var material := (
            barra_relleno.material_override
            as StandardMaterial3D
        )
        if material != null:
            material.albedo_color = Color.RED
    actualizar_interfaz()
    print(
        "CADEJO NEGRO RESTAURADO: ",
        vida_actual,
        "/",
        vida_maxima
    )
# =========================================================
# INTERFAZ
# =========================================================
func actualizar_interfaz() -> void:
    if vida_label != null:
        vida_label.text = (
            "CADEJO NEGRO\n"
            + str(vida_actual)
            + " / "
            + str(vida_maxima)
        )
    if barra_relleno == null:
        return
    if barra_relleno.mesh == null:
        return
    var porcentaje := clampf(
        float(vida_actual)
        / float(
            maxi(
                1,
                vida_maxima
            )
        ),
        0.0,
        1.0
    )
    var caja := (
        barra_relleno.mesh
        as BoxMesh
    )
    if caja != null:
        caja.size.x = (
            ANCHO_BARRA
            * porcentaje
        )
func orientar_barras() -> void:
    if barra_fondo == null:
        return
    if barra_relleno == null:
        return
    var camara := (
        get_viewport().get_camera_3d()
    )
    if camara == null:
        return
    var base_camara := (
        camara.global_transform.basis
        .orthonormalized()
    )
    var centro := (
        global_position
        + Vector3(
            0.0,
            ALTURA_BARRA,
            0.0
        )
    )
    barra_fondo.global_transform = Transform3D(
        base_camara,
        centro
    )
    var porcentaje := clampf(
        float(vida_actual)
        / float(
            maxi(
                1,
                vida_maxima
            )
        ),
        0.0,
        1.0
    )
    var izquierda := (
        -ANCHO_BARRA
        * (1.0 - porcentaje)
        / 2.0
    )
    barra_relleno.global_transform = Transform3D(
        base_camara,
        centro
        + base_camara.z
        * SEPARACION_BARRAS
        + base_camara.x
        * izquierda
    )
# =========================================================
# MUERTE / RESPAWN
# =========================================================
func morir() -> void:
    if derrotado:
        return
    derrotado = true
    cadejo_objetivo = null
    limpiar_ceniza_jugador()
    velocity = Vector3.ZERO
    print("==============================")
    print("¡CADEJO NEGRO DERROTADO!")
    print("==============================")
    # De momento NO damos materiales de purificación.
    # Primero probaremos el boss.
    # Después conectaremos aquí el ritual.
    if (
        is_instance_valid(heroe)
        and heroe.has_method(
            "ganar_experiencia"
        )
    ):
        heroe.ganar_experiencia(
            experiencia_victoria
        )
    # Experiencia independiente del Cadejo Blanco si participó en esta derrota.
    # La recompensa se entrega una sola vez por muerte, aunque el héroe dé el último golpe.
    if is_instance_valid(heroe):
        var companero: Variant = heroe.get("cadejo_blanco_activo")
        if is_instance_valid(companero) and companero.has_method("conceder_xp_por_derrota"):
            companero.conceder_xp_por_derrota(self, 250)
    visible = false
    collision_layer = 0
    collision_mask = 0
    await get_tree().create_timer(
        tiempo_reaparicion
    ).timeout
    if not is_inside_tree():
        return
    global_position = posicion_inicial
    derrotado = false
    restaurar_jefe()
    collision_layer = capa_colision_inicial
    collision_mask = mascara_colision_inicial
    visible = true
    print(
        "CADEJO NEGRO REAPARECIÓ"
    )
