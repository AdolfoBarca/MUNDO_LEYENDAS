extends Panel


# =========================================================
# NODOS
# =========================================================

@onready var icono_objeto: TextureRect = $IconoObjeto
@onready var nombre_objeto: Label = $NombreObjeto
@onready var cantidad_objeto: Label = $CantidadObjeto


# =========================================================
# CONFIGURAR CASILLA
# =========================================================

func configurar(objeto: Dictionary) -> void:

	var nombre: String = str(
		objeto.get("nombre", "Objeto")
	)

	var cantidad: int = int(
		objeto.get("cantidad", 0)
	)

	var ruta_icono: String = str(
		objeto.get("icono", "")
	)


	# =====================================================
	# NOMBRE
	# =====================================================

	nombre_objeto.text = nombre


	# =====================================================
	# CANTIDAD
	# =====================================================

	cantidad_objeto.text = "x%d" % cantidad


	# =====================================================
	# ICONO
	# =====================================================

	if ruta_icono != "":

		if ResourceLoader.exists(ruta_icono):

			icono_objeto.texture = load(ruta_icono)
			icono_objeto.visible = true

		else:

			icono_objeto.texture = null
			icono_objeto.visible = false

	else:

		icono_objeto.texture = null
		icono_objeto.visible = false