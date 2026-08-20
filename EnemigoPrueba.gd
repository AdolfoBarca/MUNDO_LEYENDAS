extends CharacterBody3D

@export var vida_maxima: int = 100
var vida_actual: int = vida_maxima

func recibir_dano(cantidad: int) -> void:
    vida_actual -= cantidad
    if vida_actual < 0:
        vida_actual = 0

    print("ENEMIGO RECIBE %d DE DANO. VIDA: %d" % [cantidad, vida_actual])

    if vida_actual <= 0:
        morir()

func morir() -> void:
    print("ENEMIGO DERROTADO")
    queue_free()