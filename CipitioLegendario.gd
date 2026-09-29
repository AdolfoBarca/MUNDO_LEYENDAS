extends CharacterBody3D

# MUNDO_LEYENDAS - CIPITÍO LEGENDARIO
# Versión: segunda fase + Tormenta de Ceniza Legendaria.

@export_group("Estadísticas")
@export var vida_maxima: int = 1500
@export var ataque_base: int = 35
@export var defensa: int = 12

@export_group("Combate")
@export var velocidad_fase_1: float = 2.8
@export var velocidad_fase_2: float = 4.0
@export var distancia_deteccion: float = 14.0
@export var distancia_ataque: float = 2.5
@export var radio_arena: float = 15.0
@export var tiempo_entre_ataques: float = 1.8

@export_group("Ceniza Legendaria")
@export var alcance_ceniza: float = 8.0
@export var duracion_ceniza_fase_1: float = 5.0
@export var duracion_ceniza_fase_2: float = 6.0
@export var reduccion_fase_1: float = 0.40
@export var reduccion_fase_2: float = 0.55
@export var recarga_ceniza_fase_1: float = 10.0
@export var recarga_ceniza_fase_2: float = 7.0

@export_group("Recompensas legendarias")
@export var experiencia_victoria: int = 500

@export_group("Tormenta - Fase 2")
@export var radio_tormenta: float = 5.0
@export var dano_tormenta: int = 20
@export var duracion_tormenta: float = 3.0
@export var reduccion_tormenta: float = 0.60
@export var recarga_tormenta: float = 12.0
@export var espera_primera_tormenta: float = 2.0

# Mantener los mismos nombres de nodos que en BosqueCipitio.tscn.
@onready var sistema_drops: Node = get_node_or_null("SistemaDrops")
@onready var vida_label: Label3D = $VidaLabel
@onready var barra_relleno: MeshInstance3D = $BarraVidaRelleno

const ANCHO_BARRA: float = 2.3
const ATAQUE_FASE_2: int = 50

enum Estado { QUIETO, PERSIGUIENDO, REGRESANDO }
var estado_actual: Estado = Estado.QUIETO
var vida_actual: int = 1500
var fase_actual: int = 1
var derrotado: bool = false
var heroe: CharacterBody3D = null
var posicion_inicial: Vector3
var temporizador_ataque: float = 0.0
var temporizador_ceniza: float = 3.0
var temporizador_tormenta: float = 0.0
var velocidad_actual: float = 2.8
var ataque_inicial: int = 35
var color_barra_inicial: Color = Color.RED

func _ready() -> void:
    posicion_inicial = global_position
    vida_actual = vida_maxima
    ataque_inicial = ataque_base
    velocidad_actual = velocidad_fase_1
    if barra_relleno.mesh != null:
        barra_relleno.mesh = barra_relleno.mesh.duplicate()
    if barra_relleno.material_override != null:
        barra_relleno.material_override = barra_relleno.material_override.duplicate()
    var material := barra_relleno.material_override as StandardMaterial3D
    if material != null:
        color_barra_inicial = material.albedo_color
    actualizar_interfaz()
    print("==============================")
    print("CIPITÍO LEGENDARIO DESPERTÓ")
    print("VIDA: ", vida_actual)
    print("ATAQUE: ", ataque_base)
    print("DEFENSA: ", defensa)
    print("POSICIÓN: ", posicion_inicial)
    print("==============================")

func _physics_process(delta: float) -> void:
    if derrotado:
        return
    temporizador_ataque = maxf(0.0, temporizador_ataque - delta)
    temporizador_ceniza = maxf(0.0, temporizador_ceniza - delta)
    temporizador_tormenta = maxf(0.0, temporizador_tormenta - delta)
    if not is_instance_valid(heroe):
        buscar_heroe()
    if not is_instance_valid(heroe):
        velocity = Vector3.ZERO
        return

    var distancia_heroe := distancia_horizontal(global_position, heroe.global_position)
    var distancia_heroe_centro := distancia_horizontal(posicion_inicial, heroe.global_position)
    var distancia_jefe_centro := distancia_horizontal(posicion_inicial, global_position)
    var heroe_no_disponible := heroe_no_es_objetivo()

    match estado_actual:
        Estado.QUIETO:
            velocity = Vector3.ZERO
            if heroe_no_disponible or distancia_heroe_centro > radio_arena:
                return
            if distancia_heroe <= distancia_deteccion:
                estado_actual = Estado.PERSIGUIENDO
                print("CIPITÍO LEGENDARIO DETECTÓ AL HÉROE")
        Estado.PERSIGUIENDO:
            if heroe_no_disponible or distancia_heroe_centro > radio_arena or distancia_jefe_centro > radio_arena:
                comenzar_regreso()
                return
            if distancia_heroe > distancia_ataque:
                mover_hacia_heroe()
            else:
                velocity.x = 0.0
                velocity.z = 0.0
                atacar_heroe()
            intentar_ceniza(distancia_heroe)
            intentar_tormenta(distancia_heroe)
        Estado.REGRESANDO:
            var distancia_regreso := distancia_horizontal(global_position, posicion_inicial)
            if distancia_regreso <= 0.35:
                global_position = posicion_inicial
                velocity = Vector3.ZERO
                restaurar_jefe()
                return
            mover_hacia_posicion(posicion_inicial)
    aplicar_gravedad(delta)
    move_and_slide()

func heroe_no_es_objetivo() -> bool:
    if not is_instance_valid(heroe):
        return true
    if heroe.get("esta_muerto") == true:
        return true
    if heroe.has_method("esta_en_zona_segura") and heroe.esta_en_zona_segura():
        return true
    return false

func distancia_horizontal(origen: Vector3, destino: Vector3) -> float:
    var diferencia := destino - origen
    diferencia.y = 0.0
    return diferencia.length()

func aplicar_gravedad(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= 9.8 * delta
    else:
        velocity.y = 0.0

func buscar_heroe() -> void:
    var heroes := get_tree().get_nodes_in_group("heroe")
    if heroes.is_empty():
        return
    heroe = heroes[0] as CharacterBody3D

func mover_hacia_heroe() -> void:
    if not is_instance_valid(heroe):
        return
    var direccion := heroe.global_position - global_position
    direccion.y = 0.0
    if direccion.length() <= 0.001:
        return
    direccion = direccion.normalized()
    velocity.x = direccion.x * velocidad_actual
    velocity.z = direccion.z * velocidad_actual
    mirar_hacia(heroe.global_position)

func mirar_hacia(objetivo: Vector3) -> void:
    var posicion_objetivo := Vector3(objetivo.x, global_position.y, objetivo.z)
    if global_position.distance_to(posicion_objetivo) <= 0.01:
        return
    look_at(posicion_objetivo, Vector3.UP)

func atacar_heroe() -> void:
    if temporizador_ataque > 0.0 or heroe_no_es_objetivo():
        return
    if not heroe.has_method("recibir_dano"):
        return
    heroe.recibir_dano(ataque_base)
    temporizador_ataque = tiempo_entre_ataques
    print("CIPITÍO LEGENDARIO ATACÓ: ", ataque_base)

func intentar_ceniza(distancia: float) -> void:
    if temporizador_ceniza > 0.0 or distancia > alcance_ceniza or heroe_no_es_objetivo():
        return
    if not heroe.has_method("aplicar_ceniza_magica"):
        return
    var duracion := duracion_ceniza_fase_1
    var reduccion := reduccion_fase_1
    var recarga := recarga_ceniza_fase_1
    if fase_actual == 2:
        duracion = duracion_ceniza_fase_2
        reduccion = reduccion_fase_2
        recarga = recarga_ceniza_fase_2
    heroe.aplicar_ceniza_magica(duracion, reduccion)
    temporizador_ceniza = recarga
    crear_efecto_ceniza(heroe.global_position)
    print("CIPITÍO LANZÓ CENIZA LEGENDARIA | FASE: ", fase_actual)

# Habilidad nueva: solo durante la segunda fase.
# Golpea UNA VEZ a quienes estén dentro del radio al activarse.
# No crea un área de daño persistente: el efecto visual dura 0.9 segundos.
func intentar_tormenta(distancia: float) -> void:
    if fase_actual != 2 or temporizador_tormenta > 0.0:
        return
    if distancia > radio_tormenta or heroe_no_es_objetivo():
        return
    temporizador_tormenta = recarga_tormenta
    crear_efecto_tormenta()
    if heroe.has_method("recibir_dano"):
        heroe.recibir_dano(dano_tormenta)
    # El héroe puede morir con el daño anterior: volver a comprobarlo.
    if not heroe_no_es_objetivo() and heroe.has_method("aplicar_ceniza_magica"):
        heroe.aplicar_ceniza_magica(duracion_tormenta, reduccion_tormenta)
    print("¡TORMENTA DE CENIZA LEGENDARIA! DAÑO: ", dano_tormenta, " | RADIO: ", radio_tormenta)

func crear_efecto_ceniza(posicion: Vector3) -> void:
    var color := Color(0.5, 0.2, 0.7, 0.65)
    if fase_actual == 2:
        color = Color(0.9, 0.15, 0.1, 0.75)
    crear_nube(posicion + Vector3(0, 1, 0), 1.2, Vector3(3.0, 2.0, 3.0), color)

func crear_efecto_tormenta() -> void:
    # La esfera es un efecto provisional; después se puede sustituir por partículas.
    crear_nube(global_position + Vector3(0, 1, 0), 0.8, Vector3(radio_tormenta, 1.8, radio_tormenta), Color(0.95, 0.25, 0.08, 0.45))

func crear_nube(posicion: Vector3, radio: float, escala_final: Vector3, color: Color) -> void:
    var escena := get_tree().current_scene
    if escena == null:
        return
    var nube := MeshInstance3D.new()
    var esfera := SphereMesh.new()
    esfera.radius = radio
    esfera.height = radio * 2.0
    nube.mesh = esfera
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.no_depth_test = false
    nube.material_override = material
    escena.add_child(nube)
    nube.global_position = posicion
    var tween := create_tween()
    tween.tween_property(nube, "scale", escala_final, 0.9)
    tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.9)
    tween.finished.connect(nube.queue_free)

func recibir_dano(cantidad: int) -> void:
    if derrotado:
        return
    var dano_real := maxi(1, cantidad - defensa)
    vida_actual = maxi(0, vida_actual - dano_real)
    print("CIPITÍO RECIBIÓ DAÑO: ", dano_real, " | VIDA: ", vida_actual, "/", vida_maxima)
    actualizar_interfaz()
    if vida_actual <= 0:
        morir()
        return
    if fase_actual == 1 and vida_actual <= vida_maxima / 2.0:
        activar_segunda_fase()

func actualizar_interfaz() -> void:
    vida_label.text = "CIPITÍO LEGENDARIO\n" + str(vida_actual) + " / " + str(vida_maxima)
    var porcentaje := clampf(float(vida_actual) / float(maxi(1, vida_maxima)), 0.0, 1.0)
    var caja := barra_relleno.mesh as BoxMesh
    if caja != null:
        caja.size.x = ANCHO_BARRA * porcentaje
        barra_relleno.position.x = -ANCHO_BARRA * (1.0 - porcentaje) / 2.0

func activar_segunda_fase() -> void:
    fase_actual = 2
    ataque_base = ATAQUE_FASE_2
    velocidad_actual = velocidad_fase_2
    temporizador_tormenta = espera_primera_tormenta
    var material := barra_relleno.material_override as StandardMaterial3D
    if material != null:
        material.albedo_color = Color.ORANGE_RED
    print("==============================")
    print("¡SEGUNDA FASE ACTIVADA!")
    print("ATAQUE: ", ataque_base)
    print("VELOCIDAD: ", velocidad_actual)
    print("TORMENTA DISPONIBLE EN: ", espera_primera_tormenta, " SEGUNDOS")
    print("==============================")

func comenzar_regreso() -> void:
    if estado_actual == Estado.REGRESANDO:
        return
    estado_actual = Estado.REGRESANDO
    velocity = Vector3.ZERO
    print("EL CIPITÍO REGRESA AL CENTRO")

func mover_hacia_posicion(destino: Vector3) -> void:
    var direccion := destino - global_position
    direccion.y = 0.0
    if direccion.length() <= 0.001:
        velocity.x = 0.0
        velocity.z = 0.0
        return
    direccion = direccion.normalized()
    velocity.x = direccion.x * velocidad_fase_1
    velocity.z = direccion.z * velocidad_fase_1

func restaurar_jefe() -> void:
    estado_actual = Estado.QUIETO
    fase_actual = 1
    vida_actual = vida_maxima
    ataque_base = ataque_inicial
    velocidad_actual = velocidad_fase_1
    temporizador_ataque = 0.0
    temporizador_ceniza = 3.0
    temporizador_tormenta = 0.0
    var material := barra_relleno.material_override as StandardMaterial3D
    if material != null:
        material.albedo_color = color_barra_inicial
    actualizar_interfaz()
    print("CIPITÍO RESTAURADO: ", vida_actual, "/", vida_maxima)

func morir() -> void:
    if derrotado:
        return
    derrotado = true
    velocity = Vector3.ZERO
    print("==============================")
    print("¡CIPITÍO LEGENDARIO DERROTADO!")
    print("==============================")
    # Usar el sistema universal ya existente; sus IDs se validan en DatosJugador.
    if sistema_drops != null and sistema_drops.has_method("crear_objeto"):
        var posicion_drop: Vector3 = global_position
        sistema_drops.crear_objeto("corazon_cipitio", 1, posicion_drop)
        sistema_drops.crear_objeto("ceniza_ancestral", 2, posicion_drop)
        sistema_drops.crear_objeto("fragmento_esencia", 5, posicion_drop)
    else:
        push_warning("Cipitío: falta el nodo hijo SistemaDrops con su script.")
    if is_instance_valid(heroe) and heroe.has_method("ganar_experiencia"):
        heroe.ganar_experiencia(experiencia_victoria)
    queue_free()
