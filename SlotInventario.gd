
extends Panel

signal objeto_seleccionado(objeto: Dictionary)

# =========================================================
# NODOS
# =========================================================

@onready var icono_objeto: TextureRect = $IconoObjeto
@onready var nombre_objeto: Label = $NombreObjeto
@onready var cantidad_objeto: Label = $CantidadObjeto

# =========================================================
# DATOS
# =========================================================

var datos_objeto: Dictionary = {}

# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	icono_objeto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nombre_objeto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cantidad_objeto.mouse_filter = Control.MOUSE_FILTER_IGNORE

# =========================================================
# CONFIGURAR CASILLA
# =========================================================

func configurar(objeto: Dictionary) -> void:
	datos_objeto = objeto.duplicate(true)

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

# =========================================================
# SELECCIONAR OBJETO
# =========================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			objeto_seleccionado.emit(datos_objeto.duplicate(true))
			accept_event()

	elif event is InputEventScreenTouch:
		if event.pressed:
			objeto_seleccionado.emit(datos_objeto.duplicate(true))
			accept_event()
