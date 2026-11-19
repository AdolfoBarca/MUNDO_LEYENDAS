extends Node3D
## Ayuda TEMPORAL para probar al Cadejo Blanco en BosqueCadejoNegro.tscn.
## Adjuntar únicamente al nodo raíz BosqueCadejoNegro.
## Eliminar este script del nodo raíz al terminar las pruebas.

@export var entregar_tecomate_de_prueba: bool = true
@export var desbloquear_cadejo_blanco_de_prueba: bool = true

func _ready() -> void:
	call_deferred("_preparar_prueba")

func _preparar_prueba() -> void:
	if entregar_tecomate_de_prueba:
		if not DatosJugador.tiene_tecomate_espiritus():
			DatosJugador.agregar_objeto_catalogo("tecomate_espiritus", 1)
			print("PRUEBA BOSQUE CADEJO NEGRO: Tecomate entregado.")
		else:
			print("PRUEBA BOSQUE CADEJO NEGRO: Ya tienes el Tecomate.")

	if desbloquear_cadejo_blanco_de_prueba:
		if not DatosJugador.companero_esta_desbloqueado("cadejo_blanco"):
			DatosJugador.desbloquear_companero("cadejo_blanco")
			print("PRUEBA BOSQUE CADEJO NEGRO: Cadejo Blanco desbloqueado.")
		else:
			print("PRUEBA BOSQUE CADEJO NEGRO: Cadejo Blanco ya desbloqueado.")

	print("PRUEBA BOSQUE CADEJO NEGRO: Equipa el Tecomate en el inventario e invoca con R.")
