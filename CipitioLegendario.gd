extends CharacterBody3D

# =====================================
# CIPITÍO LEGENDARIO
# =====================================

@export var vida_maxima: int = 1500
@export var ataque_base: int = 35
@export var defensa: int = 12

var vida_actual: int
var fase_actual: int = 1
var derrotado: bool = false

const ANCHO_BARRA: float = 2.3

@onready var vida_label: Label3D = $VidaLabel
@onready var barra_relleno: MeshInstance3D = $BarraVidaRelleno


func _ready() -> void:
    vida_actual = vida_maxima
    actualizar_interfaz()

    print("==============================")
    print("CIPITÍO LEGENDARIO DESPERTÓ")
    print("VIDA: ", vida_actual)
    print("ATAQUE: ", ataque_base)
    print("DEFENSA: ", defensa)
    print("==============================")


func recibir_dano(cantidad: int) -> void:
    if derrotado:
        return

    var dano_real: int = max(1, cantidad - defensa)
    vida_actual = max(0, vida_actual - dano_real)

    print(
        "CIPITÍO RECIBIÓ DAÑO: ",
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

    if fase_actual == 1 and vida_actual <= vida_maxima / 2:
        activar_segunda_fase()


func actualizar_interfaz() -> void:
    vida_label.text = (
        "CIPITÍO LEGENDARIO\n"
        + str(vida_actual)
        + " / "
        + str(vida_maxima)
    )

    var porcentaje: float = clampf(
        float(vida_actual) / float(maxi(1, vida_maxima)),
        0.0,
        1.0
    )

    # Modificamos el tamaño real de la malla.
    var caja: BoxMesh = barra_relleno.mesh as BoxMesh

    if caja != null:
        caja.size.x = ANCHO_BARRA * porcentaje

        # Conservamos alineado el borde izquierdo.
        barra_relleno.position.x = (
            -ANCHO_BARRA * (1.0 - porcentaje) / 2.0
        )


func activar_segunda_fase() -> void:
    fase_actual = 2
    ataque_base = 50

    # La barra cambia a un tono anaranjado.
    var material: StandardMaterial3D = (
        barra_relleno.material_override as StandardMaterial3D
    )

    if material != null:
        material.albedo_color = Color.ORANGE_RED

    print("¡SEGUNDA FASE DEL CIPITÍO LEGENDARIO!")


func morir() -> void:
    derrotado = true

    print("¡CIPITÍO LEGENDARIO DERROTADO!")

    queue_free()