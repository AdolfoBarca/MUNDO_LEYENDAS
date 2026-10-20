extends "res://EnemigoPrueba.gd"

# GUARDIAN DEL BOSQUE - Sendero de los Guardianes.
# Reutiliza IA, combate, muerte y reaparicion del enemigo base.

@onready var barra_vida_3d: Sprite3D = $BarraVida3D
@onready var viewport_vida: SubViewport = $ViewportVida

func _ready() -> void:
    # Asignar el viewport directamente evita rutas invalidas
    # al cargar la textura como subrecurso de la escena.
    barra_vida_3d.texture = viewport_vida.get_texture()
    super._ready()
    print("GUARDIAN DEL BOSQUE LISTO: ", name)
