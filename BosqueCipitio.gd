extends Node3D

# MUNDO_LEYENDAS — Bosque encantado del Cipitío
# Mejora visual de la arena; no modifica combate, posiciones ni colisiones existentes.

@export_group("Dimensiones")
@export var ancho_bosque: float = 70.0
@export var largo_bosque: float = 110.0
@export var cantidad_arboles: int = 160
@export var radio_arena: float = 15.0

@export_group("Posiciones")
@export var posicion_entrada: Vector3 = Vector3(0, 0, 45)
@export var posicion_santuario: Vector3 = Vector3(0, 0, 5)
@export var posicion_arena: Vector3 = Vector3(0, 0, -35)

@export_group("Decoración de arena")
@export var cantidad_rocas: int = 16
@export var mostrar_anillo_ceniza: bool = true
@export var luz_ambiental_arena: bool = true

var generador := RandomNumberGenerator.new()
var material_suelo: StandardMaterial3D
var material_sendero: StandardMaterial3D
var material_tronco: StandardMaterial3D
var material_hojas: StandardMaterial3D
var material_arena: StandardMaterial3D
var material_santuario: StandardMaterial3D
var material_roca: StandardMaterial3D
var material_ceniza: StandardMaterial3D

func _ready() -> void:
    generador.seed = 20260928
    crear_materiales()
    crear_iluminacion()
    crear_suelo()
    crear_sendero()
    crear_arboles()
    crear_santuario()
    crear_arena()
    crear_entrada()
    print("==============================")
    print("BOSQUE ENCANTADO DEL CIPITÍO")
    print("ESCENARIO GENERADO")
    print("==============================")

func crear_materiales() -> void:
    material_suelo = StandardMaterial3D.new()
    material_suelo.albedo_color = Color(0.13, 0.24, 0.12)

    material_sendero = StandardMaterial3D.new()
    material_sendero.albedo_color = Color(0.35, 0.26, 0.16)

    material_tronco = StandardMaterial3D.new()
    material_tronco.albedo_color = Color(0.27, 0.15, 0.08)

    material_hojas = StandardMaterial3D.new()
    material_hojas.albedo_color = Color(0.08, 0.25, 0.10)

    material_arena = StandardMaterial3D.new()
    material_arena.albedo_color = Color(0.23, 0.17, 0.13)
    material_arena.roughness = 1.0

    material_santuario = StandardMaterial3D.new()
    material_santuario.albedo_color = Color(0.35, 0.65, 0.85)
    material_santuario.emission_enabled = true
    material_santuario.emission = Color(0.1, 0.4, 0.8)

    material_roca = StandardMaterial3D.new()
    material_roca.albedo_color = Color(0.27, 0.29, 0.27)
    material_roca.roughness = 1.0

    material_ceniza = StandardMaterial3D.new()
    material_ceniza.albedo_color = Color(0.34, 0.29, 0.27)
    material_ceniza.roughness = 1.0

func crear_iluminacion() -> void:
    var luz := DirectionalLight3D.new()
    luz.name = "LuzBosque"
    luz.rotation_degrees = Vector3(-55, 35, 0)
    luz.light_energy = 0.85
    luz.shadow_enabled = true
    add_child(luz)

func crear_suelo() -> void:
    var cuerpo := StaticBody3D.new()
    cuerpo.name = "SueloBosque"
    add_child(cuerpo)
    var visual := MeshInstance3D.new()
    var malla := BoxMesh.new()
    malla.size = Vector3(ancho_bosque, 1.0, largo_bosque)
    visual.mesh = malla
    visual.material_override = material_suelo
    cuerpo.add_child(visual)
    var colision := CollisionShape3D.new()
    var forma := BoxShape3D.new()
    forma.size = malla.size
    colision.shape = forma
    cuerpo.add_child(colision)
    cuerpo.position.y = -0.5

func crear_sendero() -> void:
    var sendero := MeshInstance3D.new()
    sendero.name = "SenderoPrincipal"
    var malla := BoxMesh.new()
    malla.size = Vector3(5, 0.08, 85)
    sendero.mesh = malla
    sendero.material_override = material_sendero
    sendero.position = Vector3(0, 0.02, 5)
    add_child(sendero)

func crear_arboles() -> void:
    var contenedor := Node3D.new()
    contenedor.name = "Arboles"
    add_child(contenedor)
    for i in range(cantidad_arboles):
        var x := generador.randf_range(-ancho_bosque / 2.0 + 3.0, ancho_bosque / 2.0 - 3.0)
        var z := generador.randf_range(-largo_bosque / 2.0 + 3.0, largo_bosque / 2.0 - 3.0)
        var posicion := Vector3(x, 0, z)
        if abs(x) < 4.5 and z > -22 and z < 48:
            continue
        if posicion.distance_to(posicion_arena) < radio_arena + 3:
            continue
        if posicion.distance_to(posicion_santuario) < 5:
            continue
        var arbol := crear_arbol()
        arbol.position = posicion
        contenedor.add_child(arbol)

func crear_arbol() -> Node3D:
    var arbol := Node3D.new()
    var altura := generador.randf_range(5.0, 9.0)
    var tronco := MeshInstance3D.new()
    var malla_tronco := CylinderMesh.new()
    malla_tronco.top_radius = 0.35
    malla_tronco.bottom_radius = 0.55
    malla_tronco.height = altura
    tronco.mesh = malla_tronco
    tronco.material_override = material_tronco
    tronco.position.y = altura / 2.0
    arbol.add_child(tronco)
    var copa := MeshInstance3D.new()
    var malla_copa := SphereMesh.new()
    malla_copa.radius = generador.randf_range(2.0, 3.0)
    malla_copa.height = malla_copa.radius * 2.0
    copa.mesh = malla_copa
    copa.material_override = material_hojas
    copa.position.y = altura
    arbol.add_child(copa)
    var cuerpo := StaticBody3D.new()
    arbol.add_child(cuerpo)
    cuerpo.collision_layer = 1
    var colision := CollisionShape3D.new()
    var forma := CylinderShape3D.new()
    forma.radius = 0.65
    forma.height = altura
    colision.shape = forma
    colision.position.y = altura / 2.0
    cuerpo.add_child(colision)
    return arbol

func crear_santuario() -> void:
    var santuario := Node3D.new()
    santuario.name = "SantuarioVisual"
    santuario.position = posicion_santuario
    add_child(santuario)
    var base := MeshInstance3D.new()
    var malla_base := CylinderMesh.new()
    malla_base.top_radius = 2.0
    malla_base.bottom_radius = 2.2
    malla_base.height = 0.35
    base.mesh = malla_base
    base.position.y = 0.2
    santuario.add_child(base)
    var cristal := MeshInstance3D.new()
    var malla_cristal := SphereMesh.new()
    malla_cristal.radius = 0.7
    malla_cristal.height = 1.4
    cristal.mesh = malla_cristal
    cristal.material_override = material_santuario
    cristal.position.y = 1.2
    santuario.add_child(cristal)
    var luz := OmniLight3D.new()
    luz.light_color = Color(0.2, 0.6, 1.0)
    luz.light_energy = 2.0
    luz.omni_range = 8.0
    luz.position.y = 2.0
    santuario.add_child(luz)

func crear_arena() -> void:
    var arena := Node3D.new()
    arena.name = "ArenaCipitio"
    arena.position = posicion_arena
    add_child(arena)

    var suelo_arena := MeshInstance3D.new()
    suelo_arena.name = "SueloArena"
    var malla := CylinderMesh.new()
    malla.top_radius = radio_arena
    malla.bottom_radius = radio_arena
    malla.height = 0.12
    suelo_arena.mesh = malla
    suelo_arena.material_override = material_arena
    suelo_arena.position.y = 0.03
    arena.add_child(suelo_arena)

    if mostrar_anillo_ceniza:
        crear_anillo_ceniza(arena)
    crear_piedras_arena(arena)
    if luz_ambiental_arena:
        var luz := OmniLight3D.new()
        luz.name = "ResplandorArena"
        luz.light_color = Color(0.78, 0.43, 0.27)
        luz.light_energy = 0.45
        luz.omni_range = 17.0
        luz.shadow_enabled = false
        luz.position = Vector3(0, 3.5, 0)
        arena.add_child(luz)

# El anillo es solo visual y queda dentro del borde de la arena.
func crear_anillo_ceniza(arena: Node3D) -> void:
    var contenedor := Node3D.new()
    contenedor.name = "AnilloCeniza"
    arena.add_child(contenedor)
    var segmentos := 48
    var radio_anillo := radio_arena - 0.8
    for i in range(segmentos):
        var angulo := TAU * float(i) / float(segmentos)
        var segmento := MeshInstance3D.new()
        var malla := BoxMesh.new()
        malla.size = Vector3(0.32, 0.025, TAU * radio_anillo / float(segmentos) + 0.08)
        segmento.mesh = malla
        segmento.material_override = material_ceniza
        segmento.position = Vector3(cos(angulo) * radio_anillo, 0.105, sin(angulo) * radio_anillo)
        segmento.rotation.y = -angulo
        contenedor.add_child(segmento)

# Rocas más bajas e irregulares, fuera del radio de combate.
# Siguen siendo decorativas, como las piedras originales.
func crear_piedras_arena(arena: Node3D) -> void:
    var contenedor := Node3D.new()
    contenedor.name = "RocasPerimetro"
    arena.add_child(contenedor)
    var total := maxi(1, cantidad_rocas)
    for i in range(total):
        var angulo := TAU * float(i) / float(total)
        var distancia := radio_arena + 1.25 + generador.randf_range(0.0, 0.65)
        var altura := generador.randf_range(0.75, 1.55)
        var radio := generador.randf_range(0.65, 1.15)
        var roca := MeshInstance3D.new()
        roca.name = "Roca_%02d" % i
        var malla := SphereMesh.new()
        malla.radial_segments = 7
        malla.rings = 4
        malla.radius = radio
        malla.height = altura
        roca.mesh = malla
        roca.material_override = material_roca
        roca.position = Vector3(cos(angulo) * distancia, altura * 0.42, sin(angulo) * distancia)
        roca.rotation_degrees = Vector3(generador.randf_range(-10.0, 10.0), generador.randf_range(0.0, 180.0), generador.randf_range(-10.0, 10.0))
        contenedor.add_child(roca)
        # Cuerpo físico fijo para impedir atravesar las rocas.
        var cuerpo_roca := StaticBody3D.new()
        cuerpo_roca.name = "ColisionRoca_%02d" % i
        cuerpo_roca.collision_layer = 1
        cuerpo_roca.position = roca.position
        contenedor.add_child(cuerpo_roca)
        var colision_roca := CollisionShape3D.new()
        var forma_roca := SphereShape3D.new()
        forma_roca.radius = minf(radio * 0.85, altura * 0.48)
        colision_roca.shape = forma_roca
        cuerpo_roca.add_child(colision_roca)

func crear_entrada() -> void:
    var entrada := Node3D.new()
    entrada.name = "EntradaBosque"
    entrada.position = posicion_entrada
    add_child(entrada)
    crear_pilar(entrada, Vector3(-3.5, 0, 0))
    crear_pilar(entrada, Vector3(3.5, 0, 0))

func crear_pilar(padre: Node3D, posicion: Vector3) -> void:
    var pilar := MeshInstance3D.new()
    var malla := BoxMesh.new()
    malla.size = Vector3(1.2, 5.0, 1.2)
    pilar.mesh = malla
    pilar.position = posicion + Vector3(0, 2.5, 0)
    padre.add_child(pilar)
