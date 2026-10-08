extends Node3D
## Generador visual provisional de la Aldea del Despertar.
## Se adjunta al nodo raiz AldeaInicial (Node3D).
## No altera escenas, inventario ni scripts existentes.

const TAMANO_TERRENO: float = 64.0

func _ready() -> void:
	construir_aldea()

func material_color(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material

func agregar_caja(nombre: String, posicion: Vector3, dimensiones: Vector3, color: Color, colision: bool = false) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	add_child(nodo)
	var visual := MeshInstance3D.new()
	var malla := BoxMesh.new()
	malla.size = dimensiones
	visual.mesh = malla
	visual.material_override = material_color(color)
	nodo.add_child(visual)
	if colision:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var caja := BoxShape3D.new()
		caja.size = dimensiones
		forma.shape = caja
		cuerpo.add_child(forma)
		nodo.add_child(cuerpo)
	nodo.position = posicion
	return nodo

func agregar_cilindro(nombre: String, posicion: Vector3, radio: float, altura: float, color: Color, colision: bool = false) -> Node3D:
	var nodo := Node3D.new()
	nodo.name = nombre
	add_child(nodo)
	var visual := MeshInstance3D.new()
	var malla := CylinderMesh.new()
	malla.top_radius = radio
	malla.bottom_radius = radio
	malla.height = altura
	visual.mesh = malla
	visual.material_override = material_color(color)
	nodo.add_child(visual)
	if colision:
		var cuerpo := StaticBody3D.new()
		var forma := CollisionShape3D.new()
		var cilindro := CylinderShape3D.new()
		cilindro.radius = radio
		cilindro.height = altura
		forma.shape = cilindro
		cuerpo.add_child(forma)
		nodo.add_child(cuerpo)
	nodo.position = posicion
	return nodo

func agregar_arbol(nombre: String, posicion: Vector3) -> void:
	var arbol := Node3D.new()
	arbol.name = nombre
	arbol.position = posicion
	add_child(arbol)
	var tronco := MeshInstance3D.new()
	var malla_tronco := CylinderMesh.new()
	malla_tronco.top_radius = 0.27
	malla_tronco.bottom_radius = 0.42
	malla_tronco.height = 3.2
	tronco.mesh = malla_tronco
	tronco.material_override = material_color(Color(0.38, 0.22, 0.12))
	tronco.position.y = 1.6
	arbol.add_child(tronco)
	var copa := MeshInstance3D.new()
	var malla_copa := SphereMesh.new()
	malla_copa.radius = 2.0
	malla_copa.height = 3.6
	copa.mesh = malla_copa
	copa.material_override = material_color(Color(0.12, 0.38, 0.17))
	copa.position.y = 4.0
	arbol.add_child(copa)
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 0.42
	cilindro.height = 3.2
	forma.shape = cilindro
	forma.position.y = 1.6
	cuerpo.add_child(forma)
	arbol.add_child(cuerpo)

func agregar_casa(nombre: String, posicion: Vector3, ancho: float = 5.0, fondo: float = 5.0) -> void:
	var casa := Node3D.new()
	casa.name = nombre
	casa.position = posicion
	add_child(casa)
	var paredes := MeshInstance3D.new()
	var malla_paredes := BoxMesh.new()
	malla_paredes.size = Vector3(ancho, 3.2, fondo)
	paredes.mesh = malla_paredes
	paredes.material_override = material_color(Color(0.78, 0.63, 0.43))
	paredes.position.y = 1.6
	casa.add_child(paredes)
	var techo := MeshInstance3D.new()
	var malla_techo := BoxMesh.new()
	malla_techo.size = Vector3(ancho + 0.7, 0.65, fondo + 0.7)
	techo.mesh = malla_techo
	techo.material_override = material_color(Color(0.48, 0.17, 0.11))
	techo.position.y = 3.5
	casa.add_child(techo)
	var puerta := MeshInstance3D.new()
	var malla_puerta := BoxMesh.new()
	malla_puerta.size = Vector3(1.1, 2.0, 0.12)
	puerta.mesh = malla_puerta
	puerta.material_override = material_color(Color(0.28, 0.14, 0.08))
	puerta.position = Vector3(0, 1.0, fondo * 0.5 + 0.07)
	casa.add_child(puerta)
	var cuerpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caja := BoxShape3D.new()
	caja.size = Vector3(ancho, 3.2, fondo)
	forma.shape = caja
	forma.position.y = 1.6
	cuerpo.add_child(forma)
	casa.add_child(cuerpo)

func construir_aldea() -> void:
	# Piso con colision, y superficie en Y=0.
	agregar_caja("Terreno", Vector3(0, -0.2, 0), Vector3(TAMANO_TERRENO, 0.4, TAMANO_TERRENO), Color(0.26, 0.48, 0.22), true)
	# Caminos planos y decorativos.
	agregar_caja("CaminoPrincipal", Vector3(0, 0.025, 0), Vector3(4.5, 0.05, 57), Color(0.66, 0.54, 0.35))
	agregar_caja("CaminoPlaza", Vector3(0, 0.03, 2), Vector3(32, 0.05, 4), Color(0.66, 0.54, 0.35))
	agregar_cilindro("PlazaCentral", Vector3(0, 0.07, 2), 5.0, 0.12, Color(0.65, 0.62, 0.52))
	# Santuario visual; su checkpoint real se conectara en otro paso.
	agregar_cilindro("BaseSantuario", Vector3(0, 0.4, 2), 1.0, 0.8, Color(0.58, 0.59, 0.62), true)
	agregar_cilindro("MonolitoSantuario", Vector3(0, 1.65, 2), 0.34, 1.7, Color(0.34, 0.68, 0.78), true)
	# Viviendas con espacio libre para caminar.
	agregar_casa("Casa01", Vector3(-11, 0, -10))
	agregar_casa("Casa02", Vector3(11, 0, -10))
	agregar_casa("Casa03", Vector3(-12, 0, 13), 6.0, 5.0)
	agregar_casa("Casa04", Vector3(12, 0, 13), 6.0, 5.0)
	# Vegetacion periferica.
	var posiciones_arboles: Array[Vector3] = [
		Vector3(-24, 0, -24), Vector3(-18, 0, -22), Vector3(-8, 0, -24),
		Vector3(9, 0, -24), Vector3(20, 0, -22), Vector3(25, 0, -13),
		Vector3(-25, 0, -9), Vector3(-24, 0, 8), Vector3(24, 0, 7),
		Vector3(-24, 0, 24), Vector3(-14, 0, 25), Vector3(15, 0, 24),
		Vector3(24, 0, 23), Vector3(5, 0, 27)
	]
	for i in range(posiciones_arboles.size()):
		agregar_arbol("Arbol%02d" % (i + 1), posiciones_arboles[i])
	# Luz y ambiente visibles sin depender de otras escenas.
	var sol := DirectionalLight3D.new()
	sol.name = "SolAldea"
	sol.rotation_degrees = Vector3(-55, -30, 0)
	sol.light_energy = 1.2
	add_child(sol)
	var ambiente := WorldEnvironment.new()
	ambiente.name = "AmbienteAldea"
	var entorno := Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.58, 0.76, 0.92)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.78, 0.83, 0.87)
	entorno.ambient_light_energy = 0.7
	ambiente.environment = entorno
	add_child(ambiente)
	print("ALDEA DEL DESPERTAR: escenario inicial generado")
