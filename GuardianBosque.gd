
extends "res://EnemigoPrueba.gd"

# =========================================================
# MUNDO_LEYENDAS - GUARDIAN DEL BOSQUE V2
# Espiritu ancestral arboreo
# IA, combate, drops, XP y respawn heredados
# =========================================================

@onready var barra_vida_3d: Sprite3D = $BarraVida3D
@onready var viewport_vida: SubViewport = $ViewportVida
@onready var vida_label_3d: Label3D = $VidaLabel

var cuerpo_visual: Node3D

var corteza: StandardMaterial3D
var corteza_oscura: StandardMaterial3D
var corteza_clara: StandardMaterial3D
var musgo: StandardMaterial3D
var ojos: StandardMaterial3D
var hojas: StandardMaterial3D

# Escala de la apariencia, no de las colisiones.
const ESCALA_VISUAL: float = 1.0
const VELOCIDAD_GIRO: float = 10.0


func _ready() -> void:
    barra_vida_3d.texture = viewport_vida.get_texture()

    crear_materiales()
    crear_apariencia()

    # Subir la interfaz por encima de las ramas.
    vida_label_3d.position = Vector3(0, 3.20, 0)
    barra_vida_3d.position = Vector3(0, 3.42, 0)

    super._ready()

    print("GUARDIAN DEL BOSQUE V2 LISTO: ", name)


func _physics_process(delta: float) -> void:
    # Conservar la inteligencia artificial original.
    super._physics_process(delta)

    if cuerpo_visual == null or esta_muerto:
        return

    # El frente del modelo es -Z.
    cuerpo_visual.rotation = Vector3.ZERO

    var destino: Vector3 = Vector3.ZERO
    var debe_mirar: bool = false

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
                debe_mirar = true

        Estado.REGRESANDO:
            destino = posicion_inicial
            debe_mirar = true

        Estado.QUIETO:
            pass

    if not debe_mirar:
        return

    var direccion: Vector3 = destino - global_position
    direccion.y = 0.0

    if direccion.length_squared() <= 0.0001:
        return

    var angulo: float = atan2(
        -direccion.x,
        -direccion.z
    )

    rotation.y = lerp_angle(
        rotation.y,
        angulo,
        minf(1.0, VELOCIDAD_GIRO * delta)
    )


func crear_materiales() -> void:
    corteza = crear_material(Color(0.31, 0.19, 0.10))
    corteza_oscura = crear_material(Color(0.15, 0.09, 0.045))
    corteza_clara = crear_material(Color(0.43, 0.28, 0.14))
    musgo = crear_material(Color(0.12, 0.32, 0.10))
    hojas = crear_material(Color(0.19, 0.43, 0.13))

    ojos = crear_material(Color(0.22, 1.0, 0.16))
    ojos.emission_enabled = true
    ojos.emission = Color(0.10, 1.0, 0.08)
    ojos.emission_energy_multiplier = 4.0


func crear_material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 1.0
    return material


func crear_apariencia() -> void:
    $MeshInstance3D.visible = false

    cuerpo_visual = Node3D.new()
    cuerpo_visual.name = "CuerpoAncestralV2"
    add_child(cuerpo_visual)

    cuerpo_visual.scale = Vector3.ONE * ESCALA_VISUAL

    crear_tronco()
    crear_cabeza()
    crear_brazos()
    crear_piernas()
    crear_ramas()
    crear_musgo()


func crear_tronco() -> void:
    # Tronco central robusto.
    cilindro(
        Vector3(0, 0.05, 0),
        Vector3(0, 1.65, 0),
        0.54,
        0.65,
        corteza
    )

    # Pecho ancho.
    esfera(
        Vector3(0, 1.20, 0),
        Vector3(0.88, 0.57, 0.53),
        corteza
    )

    # Abdomen oscuro.
    esfera(
        Vector3(0, 0.35, -0.06),
        Vector3(0.55, 0.58, 0.43),
        corteza_oscura
    )

    # Placas frontales de corteza.
    for lado in [-1.0, 1.0]:
        esfera(
            Vector3(lado * 0.35, 1.18, -0.43),
            Vector3(0.24, 0.44, 0.12),
            corteza_clara
        )

        esfera(
            Vector3(lado * 0.25, 0.53, -0.43),
            Vector3(0.19, 0.35, 0.11),
            corteza
        )

    # Centro del pecho.
    esfera(
        Vector3(0, 1.15, -0.52),
        Vector3(0.17, 0.43, 0.10),
        corteza_oscura
    )


func crear_cabeza() -> void:
    # Cuello.
    cilindro(
        Vector3(0, 1.52, 0),
        Vector3(0, 1.92, 0),
        0.30,
        0.32,
        corteza_oscura
    )

    # Cabeza grande de madera.
    esfera(
        Vector3(0, 2.04, 0),
        Vector3(0.48, 0.46, 0.39),
        corteza
    )

    # Rostro oscuro.
    esfera(
        Vector3(0, 2.03, -0.31),
        Vector3(0.36, 0.28, 0.12),
        corteza_oscura
    )

    # Ojos orientados hacia -Z.
    for lado in [-1.0, 1.0]:
        esfera(
            Vector3(lado * 0.19, 2.12, -0.425),
            Vector3(0.11, 0.085, 0.07),
            ojos
        )

        # Cejas de corteza.
        rama(
            Vector3(lado * 0.09, 2.29, -0.39),
            Vector3(lado * 0.32, 2.25, -0.33),
            0.085,
            corteza_clara
        )

    # Mandibula de madera.
    esfera(
        Vector3(0, 1.78, -0.25),
        Vector3(0.31, 0.13, 0.20),
        corteza_clara
    )


func crear_brazos() -> void:
    for lado in [-1.0, 1.0]:
        # Hombro macizo.
        esfera(
            Vector3(lado * 0.83, 1.38, 0),
            Vector3(0.40, 0.38, 0.43),
            corteza
        )

        # Brazo superior.
        rama(
            Vector3(lado * 0.88, 1.30, 0),
            Vector3(lado * 1.20, 0.58, -0.03),
            0.30,
            corteza
        )

        # Codo.
        esfera(
            Vector3(lado * 1.20, 0.58, -0.03),
            Vector3(0.29, 0.29, 0.29),
            corteza_oscura
        )

        # Antebrazo.
        rama(
            Vector3(lado * 1.20, 0.58, -0.03),
            Vector3(lado * 1.34, -0.28, -0.22),
            0.27,
            corteza
        )

        # Mano de madera.
        esfera(
            Vector3(lado * 1.34, -0.29, -0.22),
            Vector3(0.29, 0.25, 0.28),
            corteza_clara
        )

        # Tres garras.
        for dedo in [-1.0, 0.0, 1.0]:
            rama(
                Vector3(
                    lado * 1.34 + dedo * 0.12,
                    -0.40,
                    -0.32
                ),
                Vector3(
                    lado * 1.37 + dedo * 0.15,
                    -0.76,
                    -0.50
                ),
                0.075,
                corteza_oscura
            )


func crear_piernas() -> void:
    for lado in [-1.0, 1.0]:
        # Piernas gruesas como raices.
        rama(
            Vector3(lado * 0.33, 0.05, 0),
            Vector3(lado * 0.43, -0.65, 0),
            0.34,
            corteza
        )

        # Pie de raiz.
        esfera(
            Vector3(lado * 0.45, -0.72, -0.20),
            Vector3(0.38, 0.20, 0.52),
            corteza_oscura
        )

        # Raices frontales.
        for dedo in [-1.0, 0.0, 1.0]:
            rama(
                Vector3(
                    lado * 0.45 + dedo * 0.15,
                    -0.72,
                    -0.35
                ),
                Vector3(
                    lado * 0.48 + dedo * 0.18,
                    -0.84,
                    -0.70
                ),
                0.09,
                corteza
            )


func crear_ramas() -> void:
    for lado in [-1.0, 1.0]:
        # Cuernos de ramas.
        rama(
            Vector3(lado * 0.27, 2.30, 0),
            Vector3(lado * 0.56, 2.80, 0.08),
            0.16,
            corteza
        )

        rama(
            Vector3(lado * 0.56, 2.80, 0.08),
            Vector3(lado * 0.82, 3.05, 0.02),
            0.10,
            corteza
        )

        rama(
            Vector3(lado * 0.52, 2.73, 0.07),
            Vector3(lado * 0.42, 3.07, -0.15),
            0.07,
            corteza_clara
        )

        # Ramas que salen de los hombros.
        rama(
            Vector3(lado * 0.75, 1.57, 0.16),
            Vector3(lado * 1.02, 2.15, 0.30),
            0.14,
            corteza
        )

        rama(
            Vector3(lado * 1.02, 2.15, 0.30),
            Vector3(lado * 1.23, 2.43, 0.34),
            0.07,
            corteza
        )


func crear_musgo() -> void:
    # Musgo en hombros.
    for lado in [-1.0, 1.0]:
        esfera(
            Vector3(lado * 0.80, 1.69, 0),
            Vector3(0.43, 0.14, 0.41),
            musgo
        )

        esfera(
            Vector3(lado * 0.94, 1.80, 0.10),
            Vector3(0.22, 0.20, 0.24),
            hojas
        )

    # Musgo sobre la cabeza.
    esfera(
        Vector3(0, 2.43, 0.06),
        Vector3(0.39, 0.12, 0.34),
        musgo
    )

    # Musgo en el pecho.
    esfera(
        Vector3(-0.48, 1.43, -0.35),
        Vector3(0.20, 0.13, 0.15),
        musgo
    )

    esfera(
        Vector3(0.49, 0.84, -0.36),
        Vector3(0.17, 0.22, 0.13),
        musgo
    )


func esfera(
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


func cilindro(
    inicio: Vector3,
    fin: Vector3,
    radio_inferior: float,
    radio_superior: float,
    material: Material
) -> void:
    var direccion: Vector3 = fin - inicio
    var longitud: float = direccion.length()

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


func rama(
    inicio: Vector3,
    fin: Vector3,
    radio: float,
    material: Material
) -> void:
    cilindro(
        inicio,
        fin,
        radio,
        radio * 0.65,
        material
    )
