extends "res://EnemigoPrueba.gd"

# ==========================================
# MINI CIPITÍO
# ==========================================

@export_group("Ceniza Mágica")

@export var alcance_ceniza: float = 6.0
@export var duracion_ceniza: float = 4.0

@export_range(0.0, 0.9, 0.05)
var reduccion_velocidad: float = 0.30

@export var recarga_ceniza: float = 12.0

var temporizador_ceniza: float = 2.0


func _ready() -> void:
    super._ready()

    print("==============================")
    print("MINI CIPITÍO LISTO: ", name)
    print("==============================")


func _physics_process(delta: float) -> void:
    super._physics_process(delta)

    if esta_muerto:
        return

    temporizador_ceniza = maxf(
        0.0,
        temporizador_ceniza - delta
    )

    if temporizador_ceniza > 0.0:
        return

    if estado_actual != Estado.PERSIGUIENDO:
        return

    if not is_instance_valid(heroe):
        return

    if heroe.esta_muerto:
        return

    if heroe.has_method("esta_en_zona_segura"):
        if heroe.esta_en_zona_segura():
            return

    var distancia := global_position.distance_to(
        heroe.global_position
    )

    if distancia > alcance_ceniza:
        return

    if heroe.has_method("aplicar_ceniza_magica"):

        heroe.aplicar_ceniza_magica(
            duracion_ceniza,
            reduccion_velocidad
        )

        temporizador_ceniza = recarga_ceniza

        crear_efecto_ceniza(
            heroe.global_position
        )

        print(
            "MINI CIPITÍO LANZÓ CENIZA MÁGICA"
        )


# ==========================================
# EFECTO VISUAL
# ==========================================

func crear_efecto_ceniza(
    posicion: Vector3
) -> void:

    var escena := get_tree().current_scene

    if escena == null:
        return

    var nube := MeshInstance3D.new()

    var esfera := SphereMesh.new()
    esfera.radius = 0.8
    esfera.height = 1.6

    nube.mesh = esfera

    var material := StandardMaterial3D.new()

    material.albedo_color = Color(
        0.48,
        0.19,
        0.62,
        0.55
    )

    material.transparency = (
        BaseMaterial3D.TRANSPARENCY_ALPHA
    )

    material.shading_mode = (
        BaseMaterial3D.SHADING_MODE_UNSHADED
    )

    nube.material_override = material

    escena.add_child(nube)

    nube.global_position = (
        posicion + Vector3(0, 1, 0)
    )

    var tween := create_tween()

    tween.tween_property(
        nube,
        "scale",
        Vector3(2.0, 1.5, 2.0),
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