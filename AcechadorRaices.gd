extends "res://EnemigoPrueba.gd"

# MUNDO_LEYENDAS - ACECHADOR DE RAICES V1
# Segundo enemigo del Sendero de los Guardianes.
# Reutiliza combate, IA, drops, XP y respawn.

@onready var barra_3d: Sprite3D = $BarraVida3D
@onready var viewport_vida: SubViewport = $ViewportVida

var cuerpo: Node3D

var madera: StandardMaterial3D
var madera_oscura: StandardMaterial3D
var musgo: StandardMaterial3D
var ojos: StandardMaterial3D


func _ready() -> void:
    barra_3d.texture = viewport_vida.get_texture()

    crear_materiales()
    crear_cuerpo()

    super._ready()

    print("ACECHADOR DE RAICES LISTO: ", name)


func _physics_process(delta: float) -> void:
    super._physics_process(delta)

    if esta_muerto or cuerpo == null:
        return

    var destino := Vector3.ZERO
    var mirar := false

    match estado_actual:
        Estado.PERSIGUIENDO:
            var objetivo: CharacterBody3D = null

            if is_instance_valid(cadejo_objetivo):
                if candidato_cadejo_valido(cadejo_objetivo):
                    objetivo = cadejo_objetivo

            if objetivo == null and is_instance_valid(heroe):
                objetivo = heroe

            if objetivo != null:
                destino = objetivo.global_position
                mirar = true

        Estado.REGRESANDO:
            destino = posicion_inicial
            mirar = true

        Estado.QUIETO:
            pass

    if not mirar:
        return

    var direccion: Vector3 = destino - global_position
    direccion.y = 0.0

    if direccion.length_squared() < 0.0001:
        return

    var angulo: float = atan2(
        -direccion.x,
        -direccion.z
    )

    rotation.y = lerp_angle(
        rotation.y,
        angulo,
        minf(1.0, 10.0 * delta)
    )


func crear_materiales() -> void:
    madera = material_color(Color(0.30, 0.17, 0.08))
    madera_oscura = material_color(Color(0.12, 0.075, 0.045))
    musgo = material_color(Color(0.16, 0.32, 0.10))

    ojos = material_color(Color(1.0, 0.55, 0.05))
    ojos.emission_enabled = true
    ojos.emission = Color(1.0, 0.35, 0.02)
    ojos.emission_energy_multiplier = 3.0


func material_color(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 1.0
    return material


func crear_cuerpo() -> void:
    $MeshInstance3D.visible = false

    cuerpo = Node3D.new()
    cuerpo.name = "CuerpoAcechador"
    add_child(cuerpo)

    # Cuerpo bajo, ancho y oscuro.
    esfera(
        Vector3(0, 0.15, 0),
        Vector3(0.52, 0.43, 0.58),
        madera
    )

    # Espalda cubierta de musgo.
    esfera(
        Vector3(0, 0.47, 0.10),
        Vector3(0.43, 0.13, 0.43),
        musgo
    )

    # Cabeza frontal.
    esfera(
        Vector3(0, 0.42, -0.40),
        Vector3(0.37, 0.32, 0.33),
        madera_oscura
    )

    # Ojos ambar en el frente -Z.
    for lado in [-1.0, 1.0]:
        esfera(
            Vector3(lado * 0.17, 0.48, -0.69),
            Vector3(0.085, 0.075, 0.06),
            ojos
        )

        # Cejas de madera.
        rama(
            Vector3(lado * 0.07, 0.63, -0.66),
            Vector3(lado * 0.29, 0.61, -0.58),
            0.06,
            madera
        )

    # Cuatro patas de raices.
    for lado in [-1.0, 1.0]:
        for frente in [-1.0, 1.0]:
            var origen := Vector3(
                lado * 0.36,
                0.05,
                frente * 0.32
            )

            var extremo := Vector3(
                lado * 0.65,
                -0.65,
                frente * 0.55
            )

            rama(origen, extremo, 0.16, madera)

            # Garra dirigida hacia delante.
            rama(
                extremo,
                extremo + Vector3(0, -0.10, -0.27),
                0.07,
                madera_oscura
            )

    # Espinas de madera en la espalda.
    for i in range(3):
        var z: float = 0.32 - float(i) * 0.30

        rama(
            Vector3(0, 0.43, z),
            Vector3(0, 0.93, z + 0.13),
            0.12,
            madera_oscura
        )

    # Raices laterales.
    for lado in [-1.0, 1.0]:
        rama(
            Vector3(lado * 0.38, 0.25, 0.18),
            Vector3(lado * 0.75, 0.42, 0.35),
            0.10,
            madera
        )


func esfera(
    posicion: Vector3,
    escala: Vector3,
    material: Material
) -> void:
    var pieza := MeshInstance3D.new()
    var malla := SphereMesh.new()

    pieza.mesh = malla
    pieza.position = posicion
    pieza.scale = escala
    pieza.material_override = material

    cuerpo.add_child(pieza)


func rama(
    inicio: Vector3,
    fin: Vector3,
    radio: float,
    material: Material
) -> void:
    var direccion: Vector3 = fin - inicio
    var longitud: float = direccion.length()

    if longitud <= 0.001:
        return

    var pieza := MeshInstance3D.new()
    var malla := CylinderMesh.new()

    malla.height = longitud
    malla.bottom_radius = radio
    malla.top_radius = radio * 0.55

    pieza.mesh = malla
    pieza.position = (inicio + fin) * 0.5
    pieza.material_override = material

    pieza.quaternion = Quaternion(
        Vector3.UP,
        direccion.normalized()
    )

    cuerpo.add_child(pieza)
