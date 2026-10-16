extends Node3D

# MUNDO_LEYENDAS - Sendero de los Guardianes
# Escenario visual y fisico. No modifica al heroe, misiones ni guardados.
@export var ancho: float = 120.0
@export var largo: float = 240.0
@export var cantidad_arboles: int = 650
@export var semilla: int = 20261015

var rng := RandomNumberGenerator.new()
var materiales: Dictionary = {}

@export_group("Visibilidad del heroe")
@export var transparentar_copas: bool = true
@export_range(0.1, 1.0, 0.05) var opacidad_obstruccion: float = 0.25
@export var velocidad_transicion: float = 5.0

var copas_por_arbol: Array[Dictionary] = []
@export_group("Secretos visuales")
@export var mostrar_tesoros_decorativos: bool = true
var heroe_referencia: Node3D
var camara_referencia: Camera3D

# Primer cofre interactivo. Los otros cinco siguen siendo decorativos.
const ID_COFRE_PRUEBA: String = "sendero_cofre_entrada_01"
const RECOMPENSA_COFRE: int = 15
const DISTANCIA_ABRIR_COFRE: float = 2.8
var cofre_prueba: Node3D
var tapa_cofre_prueba: MeshInstance3D
var indicador_cofre: Label3D
var cofre_abierto_local: bool = false

func _ready() -> void:
	rng.seed = semilla
	crear_materiales()
	crear_suelo()
	crear_camino()
	crear_limites()
	crear_vegetacion()
	crear_claro_espiritual()
	crear_pistas_secretas()
	crear_cofre_interactivo()
	heroe_referencia = get_node_or_null("Heroe") as Node3D
	camara_referencia = get_node_or_null("Camara") as Camera3D
	print("SENDERO DE LOS GUARDIANES: escenario generado")

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo or event.keycode != KEY_E:
		return
	if get_tree().paused or not is_instance_valid(heroe_referencia) or not is_instance_valid(cofre_prueba):
		return
	if heroe_referencia.global_position.distance_to(cofre_prueba.global_position) > DISTANCIA_ABRIR_COFRE:
		return
	if cofre_abierto_local or DatosJugador.cofre_esta_abierto(ID_COFRE_PRUEBA):
		DatosJugador.avisar_evento("Este cofre ya fue abierto.", "info")
		return
	# El inventario existente se encarga de guardar y mostrar el objeto.
	DatosJugador.agregar_objeto_catalogo("fragmento_esencia", RECOMPENSA_COFRE)
	DatosJugador.registrar_cofre_abierto(ID_COFRE_PRUEBA)
	cofre_abierto_local = true
	actualizar_apariencia_cofre()
	DatosJugador.avisar_evento("¡Encontraste un tesoro oculto en el Sendero!", "exito")
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	actualizar_indicador_cofre()
	if not transparentar_copas:
		return
	if not is_instance_valid(heroe_referencia) or not is_instance_valid(camara_referencia):
		return
	var inicio := camara_referencia.global_position
	var final := heroe_referencia.global_position + Vector3(0, 1.1, 0)
	var segmento := final - inicio
	var longitud_cuadrada := segmento.length_squared()
	if longitud_cuadrada < 0.01:
		return
	for datos in copas_por_arbol:
		var copas: Array = datos["copas"]
		var bloquea := false
		for copa in copas:
			var centro: Vector3 = copa.global_position
			var t: float = clampf((centro - inicio).dot(segmento) / longitud_cuadrada, 0.0, 1.0)
			if t <= 0.02 or t >= 0.98:
				continue
			var cercano: Vector3 = inicio + segmento * t
			if cercano.distance_to(centro) < 2.7:
				bloquea = true
				break
		var objetivo: float = opacidad_obstruccion if bloquea else 1.0
		var material_copas: StandardMaterial3D = datos["material"]
		var color_actual: Color = material_copas.albedo_color
		color_actual.a = move_toward(color_actual.a, objetivo, velocidad_transicion * delta)
		material_copas.albedo_color = color_actual

func crear_materiales() -> void:
	materiales["hierba"] = material(Color("527547"))
	materiales["tierra"] = material(Color("94734c"))
	materiales["tronco"] = material(Color("5b3928"))
	materiales["hojas"] = material(Color("326a42"))
	materiales["hojas_claras"] = material(Color("54894a"))
	materiales["roca"] = material(Color("777e77"))
	materiales["espiritu"] = material(Color("8bd9cc"), true)
	materiales["morado"] = material(Color("50375f"))
	materiales["rojo"] = material(Color("81434b"))
	materiales["dorado"] = material(Color("a68a3f"))
	materiales["corteza_oscura"] = material(Color("29232c"))
	materiales["cofre"] = material(Color("674126"))

func material(color: Color, brillo: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if brillo:
		m.emission_enabled = true
		m.emission = color * 0.5
	return m

func caja_visual(padre: Node3D, nombre: String, tam: Vector3, pos: Vector3, mat: Material, angulo: float = 0.0) -> MeshInstance3D:
	var nodo := MeshInstance3D.new()
	nodo.name = nombre
	var malla := BoxMesh.new()
	malla.size = tam
	nodo.mesh = malla
	nodo.material_override = mat
	nodo.position = pos
	nodo.rotation.y = angulo
	padre.add_child(nodo)
	return nodo

func caja_fisica(padre: Node3D, nombre: String, tam: Vector3, pos: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.name = nombre
	cuerpo.position = pos
	padre.add_child(cuerpo)
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)

func crear_suelo() -> void:
	var suelo := Node3D.new()
	suelo.name = "SueloGenerado"
	add_child(suelo)
	caja_visual(suelo, "Hierba", Vector3(ancho, 0.5, largo), Vector3(0, -0.25, 0), materiales["hierba"])
	caja_fisica(suelo, "ColisionSuelo", Vector3(ancho, 0.5, largo), Vector3(0, -0.25, 0))

func centro_camino(z: float) -> float:
	return 2.5 * sin(z * 0.095) + 0.8 * sin(z * 0.22)

func crear_camino() -> void:
	# Una sola malla continua evita las esquinas y uniones cuadradas.
	var camino := MeshInstance3D.new()
	camino.name = "CaminoSinuosoContinuo"
	add_child(camino)
	var superficie := SurfaceTool.new()
	superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pasos: int = maxi(80, int(largo * 2.0))
	var mitad_ancho: float = 2.4
	for i in range(pasos):
		var z0: float = -largo * 0.5 + largo * float(i) / float(pasos)
		var z1: float = -largo * 0.5 + largo * float(i + 1) / float(pasos)
		var izq0 := punto_borde_camino(z0, -mitad_ancho)
		var der0 := punto_borde_camino(z0, mitad_ancho)
		var izq1 := punto_borde_camino(z1, -mitad_ancho)
		var der1 := punto_borde_camino(z1, mitad_ancho)
		# Vértices en sentido antihorario vistos desde arriba.
		superficie.add_vertex(izq0)
		superficie.add_vertex(der0)
		superficie.add_vertex(izq1)
		superficie.add_vertex(der0)
		superficie.add_vertex(der1)
		superficie.add_vertex(izq1)
	superficie.generate_normals()
	camino.mesh = superficie.commit()
	camino.material_override = materiales["tierra"]

func punto_borde_camino(z: float, lado: float) -> Vector3:
	# Desplazamiento perpendicular a la dirección local de la curva.
	var derivada: float = 2.5 * 0.095 * cos(z * 0.095) + 0.8 * 0.22 * cos(z * 0.22)
	var normal_2d := Vector2(1.0, -derivada).normalized()
	return Vector3(centro_camino(z) + normal_2d.x * lado, 0.035, z + normal_2d.y * lado)

func crear_limites() -> void:
	var limites := Node3D.new()
	limites.name = "LimitesInvisibles"
	add_child(limites)
	caja_fisica(limites, "Oeste", Vector3(1, 6, largo + 2), Vector3(-ancho / 2.0 + 0.5, 3, 0))
	caja_fisica(limites, "Este", Vector3(1, 6, largo + 2), Vector3(ancho / 2.0 - 0.5, 3, 0))
	caja_fisica(limites, "Norte", Vector3(ancho + 2, 6, 1), Vector3(0, 3, -largo / 2.0 + 0.5))
	caja_fisica(limites, "Sur", Vector3(ancho + 2, 6, 1), Vector3(0, 3, largo / 2.0 - 0.5))

func crear_vegetacion() -> void:
	var bosque := Node3D.new()
	bosque.name = "BosqueTropical"
	add_child(bosque)
	for i in range(cantidad_arboles):
		var x := rng.randf_range(-ancho / 2.0 + 2.0, ancho / 2.0 - 2.0)
		var z := rng.randf_range(-largo / 2.0 + 2.0, largo / 2.0 - 2.0)
		if absf(x - centro_camino(z)) < 5.0:
			continue
		if Vector2(x, z).distance_to(Vector2(centro_camino(-92.0), -92.0)) < 8.0:
			continue
		# Dejar despejado el primer tesoro, cerca de la entrada.
		if Vector2(x, z).distance_to(Vector2(centro_camino(105.0) + 6.5, 105.0)) < 3.2:
			continue
		crear_arbol(bosque, Vector3(x, 0, z), i)

func crear_arbol(padre: Node3D, pos: Vector3, indice: int) -> void:
	var arbol := Node3D.new()
	arbol.name = "Arbol_%02d" % indice
	arbol.position = pos
	padre.add_child(arbol)
	var tipo: int = indice % 11
	var alto := rng.randf_range(5.0, 9.0)
	if tipo == 0:
		alto *= 1.5
	var tronco := MeshInstance3D.new()
	var cilindro := CylinderMesh.new()
	cilindro.top_radius = 0.28
	cilindro.bottom_radius = 0.55
	cilindro.height = alto
	tronco.mesh = cilindro
	tronco.material_override = materiales["corteza_oscura"] if tipo == 1 or tipo == 2 else materiales["tronco"]
	tronco.position.y = alto / 2.0
	arbol.add_child(tronco)
	var material_copas := StandardMaterial3D.new()
	material_copas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_copas.roughness = 1.0
	var copas_arbol: Array[MeshInstance3D] = []
	for j in range(3):
		var copa := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = (2.2 if tipo == 0 else 1.3 if tipo == 1 else 1.6) + float(j) * 0.28
		esfera.height = esfera.radius * 2.0
		copa.mesh = esfera
		# Cada arbol tiene su propio material para evitar transparentar todo el bosque.
		# Las tres copas comparten color, pero solo dentro del mismo arbol.
		copa.material_override = material_copas
		copa.position = Vector3(float(j - 1) * 0.75, alto + float(j) * 0.6, 0)
		arbol.add_child(copa)
		copas_arbol.append(copa)
	if tipo == 1 or tipo == 2:
		material_copas.albedo_color = Color("50375f")
	elif tipo == 3:
		material_copas.albedo_color = Color("81434b")
	elif tipo == 4:
		material_copas.albedo_color = Color("a68a3f")
	else:
		material_copas.albedo_color = Color("326a42") if indice % 2 == 0 else Color("54894a")
	copas_por_arbol.append({"copas": copas_arbol, "material": material_copas})
	var cuerpo := StaticBody3D.new()
	arbol.add_child(cuerpo)
	var colision := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.65
	forma.height = alto
	colision.shape = forma
	colision.position.y = alto / 2.0
	cuerpo.add_child(colision)

func crear_claro_espiritual() -> void:
	var claro := Node3D.new()
	claro.name = "ClaroDelCadejoBlanco"
	claro.position = Vector3(centro_camino(-92.0), 0, -92.0)
	add_child(claro)
	for i in range(7):
		var angulo := TAU * float(i) / 7.0
		var x := cos(angulo) * 5.8
		var z := sin(angulo) * 5.8
		caja_visual(claro, "Piedra_%d" % i, Vector3(1.2, 1.7, 1.0), Vector3(x, 0.85, z), materiales["roca"], angulo)
	var marca := MeshInstance3D.new()
	marca.name = "MarcaEspiritual"
	var malla := CylinderMesh.new()
	malla.top_radius = 1.2
	malla.bottom_radius = 1.2
	malla.height = 0.08
	marca.mesh = malla
	marca.material_override = materiales["espiritu"]
	marca.position.y = 0.06
	claro.add_child(marca)
	var luz := OmniLight3D.new()
	luz.name = "LuzEspiritual"
	luz.light_color = Color("8bd9cc")
	luz.light_energy = 0.65
	luz.omni_range = 8.0
	luz.position.y = 2.5
	claro.add_child(luz)

# Pistas decorativas. No otorgan objetos ni modifican inventario/guardados.
func crear_pistas_secretas() -> void:
	if not mostrar_tesoros_decorativos:
		return
	var pistas := Node3D.new()
	pistas.name = "SecretosDecorativos"
	add_child(pistas)
	for i in range(5):
		var z: float = -78.0 + float(i) * 36.0
		var lado: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = centro_camino(z) + lado * 10.0
		var base := Node3D.new()
		base.name = "Pista_%02d" % i
		base.position = Vector3(x, 0, z)
		pistas.add_child(base)
		caja_visual(base, "CofreCerradoDecorativo", Vector3(1.1, 0.65, 0.8), Vector3(0, 0.34, 0), materiales["cofre"])
		caja_visual(base, "MarcaDorada", Vector3(1.13, 0.12, 0.15), Vector3(0, 0.58, 0.25), materiales["dorado"])
		# La colision evita atravesar el cofre. No se puede abrir aun.
		caja_fisica(base, "ColisionCofre", Vector3(1.1, 0.65, 0.8), Vector3(0, 0.34, 0))


# =========================================================
# PRIMER COFRE FUNCIONAL - SENDERO DE LOS GUARDIANES
# =========================================================
func crear_cofre_interactivo() -> void:
	cofre_prueba = Node3D.new()
	cofre_prueba.name = "CofreInteractivoEntrada"
	cofre_prueba.position = Vector3(centro_camino(105.0) + 6.5, 0.0, 105.0)
	add_child(cofre_prueba)

	caja_visual(cofre_prueba, "BaseMadera", Vector3(1.3, 0.65, 0.9), Vector3(0, 0.35, 0), materiales["cofre"])
	tapa_cofre_prueba = caja_visual(cofre_prueba, "Tapa", Vector3(1.4, 0.22, 1.0), Vector3(0, 0.78, 0), materiales["tronco"])
	caja_visual(cofre_prueba, "CerraduraDorada", Vector3(0.25, 0.28, 0.08), Vector3(0, 0.52, 0.49), materiales["dorado"])
	caja_fisica(cofre_prueba, "ColisionCofre", Vector3(1.3, 0.65, 0.9), Vector3(0, 0.35, 0))

	indicador_cofre = Label3D.new()
	indicador_cofre.name = "IndicadorInteraccion"
	indicador_cofre.text = "[E] Abrir cofre"
	indicador_cofre.font_size = 38
	indicador_cofre.pixel_size = 0.012
	indicador_cofre.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	indicador_cofre.position = Vector3(0, 1.65, 0)
	indicador_cofre.visible = false
	cofre_prueba.add_child(indicador_cofre)

	cofre_abierto_local = DatosJugador.cofre_esta_abierto(ID_COFRE_PRUEBA)
	actualizar_apariencia_cofre()

func actualizar_apariencia_cofre() -> void:
	if not is_instance_valid(tapa_cofre_prueba):
		return
	if cofre_abierto_local:
		tapa_cofre_prueba.rotation.x = -0.95
		tapa_cofre_prueba.position = Vector3(0, 1.03, -0.38)
	else:
		tapa_cofre_prueba.rotation.x = 0.0
		tapa_cofre_prueba.position = Vector3(0, 0.78, 0)

func actualizar_indicador_cofre() -> void:
	if not is_instance_valid(indicador_cofre) or not is_instance_valid(heroe_referencia):
		return
	var cerca: bool = heroe_referencia.global_position.distance_to(cofre_prueba.global_position) <= DISTANCIA_ABRIR_COFRE
	indicador_cofre.visible = cerca and not get_tree().paused
	if cerca:
		indicador_cofre.text = "Cofre abierto" if cofre_abierto_local else "[E] Abrir cofre"
