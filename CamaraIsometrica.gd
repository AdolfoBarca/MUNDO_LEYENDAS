
extends Camera3D

@export var tamano_camara: float = 25.0

func _ready() -> void:
    projection = Camera3D.PROJECTION_ORTHOGONAL
    size = tamano_camara
    current = true

    # Mirar hacia el centro del Sendero de los Guardianes.
    look_at(Vector3(0, 0, 0), Vector3.UP)
