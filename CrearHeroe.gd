extends Control


# =========================================================
# CONTROLES DEL FORMULARIO
# =========================================================

@onready var nombre_heroe: LineEdit = $NombreHeroe
@onready var pais_origen: OptionButton = $PaisOrigen
@onready var color_piel: OptionButton = $ColorPiel
@onready var color_camisa: OptionButton = $ColorCamisa
@onready var color_pantalon: OptionButton = $ColorPantalon
@onready var boton_crear: Button = $BotonCrear


# =========================================================
# PARTES DEL HÉROE DE LA VISTA PREVIA
# =========================================================

@onready var cabeza: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/Cabeza
@onready var brazo_izquierdo: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/BrazoIzquierdo
@onready var brazo_derecho: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/BrazoDerecho
@onready var cuerpo: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/Cuerpo
@onready var pierna_izquierda: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/PiernaIzquierda
@onready var pierna_derecha: MeshInstance3D = $VistaHeroe/ViewportHeroe/EscenaHeroe/HeroePreview/PiernaDerecha


# =========================================================
# COLORES ACTUALES
# =========================================================

var color_piel_actual: Color = Color("#C98F65")
var color_camisa_actual: Color = Color("#244A73")
var color_pantalon_actual: Color = Color("#2F3540")


# =========================================================
# INICIO
# =========================================================

func _ready() -> void:
	cargar_paises()
	cargar_colores_piel()
	cargar_colores_camisa()
	cargar_colores_pantalon()

	color_piel.item_selected.connect(_on_color_piel_seleccionado)
	color_camisa.item_selected.connect(_on_color_camisa_seleccionado)
	color_pantalon.item_selected.connect(_on_color_pantalon_seleccionado)
	boton_crear.pressed.connect(_on_boton_crear_pressed)


# =========================================================
# PAÍSES
# =========================================================

func cargar_paises() -> void:
	pais_origen.clear()

	pais_origen.add_item("Selecciona tu país")
	pais_origen.add_item("El Salvador")
	pais_origen.add_item("Guatemala")
	pais_origen.add_item("Honduras")
	pais_origen.add_item("Nicaragua")
	pais_origen.add_item("Costa Rica")
	pais_origen.add_item("Panamá")
	pais_origen.add_item("Belice")


# =========================================================
# TONOS DE PIEL
# =========================================================

func cargar_colores_piel() -> void:
	color_piel.clear()

	color_piel.add_item("Selecciona tono de piel")
	color_piel.add_item("Claro")
	color_piel.add_item("Medio claro")
	color_piel.add_item("Medio")
	color_piel.add_item("Moreno")
	color_piel.add_item("Oscuro")


# =========================================================
# COLORES DE CAMISA
# =========================================================

func cargar_colores_camisa() -> void:
	color_camisa.clear()

	color_camisa.add_item("Selecciona color de camisa")
	color_camisa.add_item("Azul")
	color_camisa.add_item("Rojo")
	color_camisa.add_item("Verde")
	color_camisa.add_item("Negro")
	color_camisa.add_item("Blanco")


# =========================================================
# COLORES DE PANTALÓN
# =========================================================

func cargar_colores_pantalon() -> void:
	color_pantalon.clear()

	color_pantalon.add_item("Selecciona color de pantalón")
	color_pantalon.add_item("Gris oscuro")
	color_pantalon.add_item("Negro")
	color_pantalon.add_item("Azul oscuro")
	color_pantalon.add_item("Café")
	color_pantalon.add_item("Beige")


# =========================================================
# CAMBIAR TONO DE PIEL
# =========================================================

func _on_color_piel_seleccionado(indice: int) -> void:
	var nuevo_color: Color

	match indice:
		1:
			nuevo_color = Color("#E8B894")
		2:
			nuevo_color = Color("#D9A178")
		3:
			nuevo_color = Color("#C98F65")
		4:
			nuevo_color = Color("#9C6846")
		5:
			nuevo_color = Color("#67432E")
		_:
			return

	color_piel_actual = nuevo_color
	aplicar_color_piel(nuevo_color)


func aplicar_color_piel(nuevo_color: Color) -> void:
	var partes_piel = [
		cabeza,
		brazo_izquierdo,
		brazo_derecho
	]

	for parte in partes_piel:
		if parte != null:
			var material_parte = parte.get_surface_override_material(0)

			if material_parte != null:
				material_parte.albedo_color = nuevo_color


# =========================================================
# CAMBIAR COLOR DE CAMISA
# =========================================================

func _on_color_camisa_seleccionado(indice: int) -> void:
	var nuevo_color: Color

	match indice:
		1:
			nuevo_color = Color("#244A73")
		2:
			nuevo_color = Color("#B83232")
		3:
			nuevo_color = Color("#3E7A46")
		4:
			nuevo_color = Color("#202124")
		5:
			nuevo_color = Color("#E8E8E8")
		_:
			return

	color_camisa_actual = nuevo_color
	aplicar_color_camisa(nuevo_color)


func aplicar_color_camisa(nuevo_color: Color) -> void:
	if cuerpo != null:
		var material_cuerpo = cuerpo.get_surface_override_material(0)

		if material_cuerpo != null:
			material_cuerpo.albedo_color = nuevo_color


# =========================================================
# CAMBIAR COLOR DE PANTALÓN
# =========================================================

func _on_color_pantalon_seleccionado(indice: int) -> void:
	var nuevo_color: Color

	match indice:
		1:
			nuevo_color = Color("#2F3540")
		2:
			nuevo_color = Color("#1B1B1B")
		3:
			nuevo_color = Color("#1F3556")
		4:
			nuevo_color = Color("#6B4B32")
		5:
			nuevo_color = Color("#C8B58A")
		_:
			return

	color_pantalon_actual = nuevo_color
	aplicar_color_pantalon(nuevo_color)


func aplicar_color_pantalon(nuevo_color: Color) -> void:
	var piernas = [
		pierna_izquierda,
		pierna_derecha
	]

	for pierna in piernas:
		if pierna != null:
			var material_pierna = pierna.get_surface_override_material(0)

			if material_pierna != null:
				material_pierna.albedo_color = nuevo_color


# =========================================================
# CREAR HÉROE
# =========================================================

func _on_boton_crear_pressed() -> void:
	var nombre_elegido: String = nombre_heroe.text.strip_edges()

	if nombre_elegido.is_empty():
		print("ERROR: Debes escribir un nombre para tu héroe.")
		nombre_heroe.grab_focus()
		return

	if pais_origen.selected == 0:
		print("ERROR: Debes seleccionar un país.")
		return

	if color_piel.selected == 0:
		print("ERROR: Debes seleccionar un tono de piel.")
		return

	if color_camisa.selected == 0:
		print("ERROR: Debes seleccionar un color de camisa.")
		return

	if color_pantalon.selected == 0:
		print("ERROR: Debes seleccionar un color de pantalón.")
		return

	var pais_elegido: String = pais_origen.get_item_text(pais_origen.selected)

	DatosJugador.nombre = nombre_elegido
	DatosJugador.pais = pais_elegido

	DatosJugador.color_piel = color_piel_actual
	DatosJugador.color_camisa = color_camisa_actual
	DatosJugador.color_pantalon = color_pantalon_actual

	# Asignar región y afinidad según el país elegido
	DatosJugador.asignar_region_y_afinidad()

	print("==============================")
	print("HÉROE GUARDADO")
	print("Nombre: ", DatosJugador.nombre)
	print("País: ", DatosJugador.pais)
	print("Región: ", DatosJugador.region)
	print("Afinidad: ", DatosJugador.afinidad)
	print("==============================")

	get_tree().change_scene_to_file("res://Main.tscn")
