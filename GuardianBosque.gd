
extends "res://EnemigoPrueba.gd"

# GUARDIAN DEL BOSQUE - MUNDO_LEYENDAS
# Version con orientacion frontal corregida.
# Conserva IA, combate, drops, XP y respawn.

@onready var barra_vida_3d: Sprite3D = $BarraVida3D
@onready var viewport_vida: SubViewport = $ViewportVida

var cuerpo_visual: Node3D

var material_corteza: StandardMaterial3D
var material_madera_oscura: StandardMaterial3D
var material_musgo: StandardMaterial3D
var material_ojos: StandardMaterial3D


func _ready() -> void:
    barra_vida_3d.texture = viewport_vida.get_texture()

    crear_materiales()
    crear_apariencia()

    super._ready()

    print("GUARDIAN DEL BOSQUE ANCESTRAL LISTO: ", name)


func _physics_process(delta: float) -> void:
    # Ejecutar toda la IA original.
    super._physics_process(delta)

    if cuerpo_visual == null or esta_muerto:
        return

    # El modelo usa -Z como frente.
    # Su rotacion local permanece en cero.
    cuerpo_visual.rotation = Vector3.ZERO

    var destino: Vector3
    var debe_mirar: bool = false

    match estado_actual:
        Estado.PERSIGUIENDO:
            # Priorizar el objetivo real del combate.
            var objetivo: CharacterBody3D = null

            if is_instance_valid(cadejo_objetivo):
                if candidato_cadejo_valido(cadejo_objetivo):
                    objetivo = cadejo_objetivo

            if objetivo == null and is_instance_valid(heroe):
                objetivo = heroe

            if objetivo != null:
                destino = objetivo.global_position
                debe_mirar = true

        Estado.REGRESANDO:
            destino = posicion_inicial
            debe_mirar = true

        Estado.QUIETO:
            # Conservar la orientacion actual.
            pass

    if not debe_mirar:
        return

    var direccion: Vector3 = destino - global_position
    direccion.y = 0.0

    if direccion.length_squared() <= 0.0001:
        return

    # Girar el nodo principal hacia el objetivo.
    # look_at utiliza el eje local -Z como frente.
    var angulo_objetivo: float = atan2(
        -direccion.x,
        -direccion.z
    )

    rotation.y = lerp_angle(
        rotation.y,
        angulo_objetivo,
        minf(1.0, 10.0 * delta)
    )


func crear_materiales() -> void:
    material_corteza = StandardMaterial3D.new()
    material_corteza.albedo_color = Color(0.30, 0.19, 0.10)
    material_corteza.roughness = 1.0

    material_madera_oscura = StandardMaterial3D.new()
    material_madera_oscura.albedo_color = Color(0.16, 0.10, 0.055)
    material_madera_oscura.roughness = 1.0

    material_musgo = StandardMaterial3D.new()
    material_musgo.albedo_color = Color(0.13, 0.36, 0.12)
    material_musgo.roughness = 1.0

    material_ojos = StandardMaterial3D.new()
    material_ojos.albedo_color = Color(0.15, 1.0, 0.18)
    material_ojos.emission_enabled = true
    material_ojos.emission = Color(0.1, 1.0, 0.12)
    material_ojos.emission_energy_multiplier = 3.0


func crear_apariencia() -> void:
    # Ocultar capsula original sin eliminarla.
    $MeshInstance3D.visible = false

    cuerpo_visual = Node3D.new()
    cuerpo_visual.name = "CuerpoAncestral"
    add_child(cuerpo_visual)

    # El frente del personaje es -Z.

    # Tronco principal.
    crear_cilindro(
        Vector3(0, 0, 0),
        Vector3(0, 1.15, 0),
        0.47,
        0.36,
        material_corteza
    )

    # Pecho y hombros.
    crear_esfera(
        Vector3(0, 0.65, 0),
        Vector3(0.65, 0.43, 0.38),
        material_corteza
    )

    # Cabeza.
    crear_esfera(
        Vector3(0, 1.35, 0),
        Vector3(0.40, 0.37, 0.34),
        material_madera_oscura
    )

    # OJOS: ahora en el frente correcto (-Z).
    for lado in [-1.0, 1.0]:
        crear_esfera(
            Vector3(lado * 0.17, 1.40, -0.32),
            Vector3(0.095, 0.085, 0.065),
            material_ojos
        )

    # Brazos gruesos de madera.
    crear_rama(
        Vector3(-0.48, 0.78, 0),
        Vector3(-0.92, 0.22, 0),
        0.20
    )

    crear_rama(
        Vector3(0.48, 0.78, 0),
        Vector3(0.92, 0.22, 0),
        0.20
    )

    # Antebrazos y manos.
    for lado in [-1.0, 1.0]:
        crear_rama(
            Vector3(lado * 0.92, 0.22, 0),
            Vector3(lado * 1.04, -0.38, -0.10),
            0.15
        )

        # Dedos como pequenas ramas.
        for dedo in [-1.0, 0.0, 1.0]:
            crear_rama(
                Vector3(lado * 1.04, -0.38, -0.10),
                Vector3(
                    lado * (1.05 + dedo * 0.11),
                    -0.67,
                    -0.15
                ),
                0.045
            )

    # Piernas como raices.
    for lado in [-1.0, 1.0]:
        crear_rama(
            Vector3(lado * 0.24, -0.75, 0),
            Vector3(lado * 0.39, -1.20, -0.12),
            0.23
        )

        crear_rama(
            Vector3(lado * 0.39, -1.20, -0.12),
            Vector3(lado * 0.50, -1.32, -0.42),
            0.15
        )

    # Ramas que nacen de la cabeza.
    for lado in [-1.0, 1.0]:
        crear_rama(
            Vector3(lado * 0.22, 1.58, 0),
            Vector3(lado * 0.53, 2.05, 0),
            0.11
        )

        crear_rama(
            Vector3(lado * 0.53, 2.05, 0),
            Vector3(lado * 0.75, 2.27, 0),
            0.065
        )

    # Musgo en hombros y cabeza.
    crear_esfera(
        Vector3(-0.43, 0.91, 0),
        Vector3(0.28, 0.12, 0.30),
        material_musgo
    )

    crear_esfera(
        Vector3(0.43, 0.91, 0),
        Vector3(0.28, 0.12, 0.30),
        material_musgo
    )

    crear_esfera(
        Vector3(0, 1.70, 0),
        Vector3(0.31, 0.11, 0.29),
        material_musgo
    )


func crear_esfera(
    posicion: Vector3,
    escala: Vector3,
    material: Material
) -> void:
    var pieza := MeshInstance3D.new()
    var malla := SphereMesh.new()

    pieza.mesh = malla
    pieza.material_override = material
    pieza.position = posicion
    pieza.scale = escala

    cuerpo_visual.add_child(pieza)


func crear_cilindro(
    inicio: Vector3,
    fin: Vector3,
    radio_inferior: float,
    radio_superior: float,
    material: Material
) -> void:
    var direccion := fin - inicio
    var longitud := direccion.length()

    if longitud < 0.001:
        return

    var pieza := MeshInstance3D.new()
    var malla := CylinderMesh.new()

    malla.height = longitud
    malla.bottom_radius = radio_inferior
    malla.top_radius = radio_superior

    pieza.mesh = malla
    pieza.material_override = material
    pieza.position = (inicio + fin) * 0.5

    pieza.quaternion = Quaternion(
        Vector3.UP,
        direccion.normalized()
    )

    cuerpo_visual.add_child(pieza)


func crear_rama(
    inicio: Vector3,
    fin: Vector3,
    radio: float
) -> void:
    crear_cilindro(
        inicio,
        fin,
        radio,
        radio * 0.65,
        material_corteza
    )
