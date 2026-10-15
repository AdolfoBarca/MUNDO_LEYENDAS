extends Node3D
## Aldea del Despertar. Casa01 es la Casa del Explorador.
## Construccion procedural; no modifica escenas existentes.

const TAMANO_TERRENO: float = 64.0
const POSICION_CASA_EXPLORADOR: Vector3 = Vector3(-11, 0, -10)
const ARCHIVO_COFRES: String = "user://cofres_aldea.save"
const ID_COFRE_EXPLORADOR: String = "casa_explorador_guantes"

var heroe: Node3D
const POSICION_CURANDERA: Vector3 = Vector3(11, 0, -10)
var puerta_curandera: StaticBody3D
var visual_puerta_curandera: MeshInstance3D
var techo_curandera: Node3D
var puerta_curandera_abierta: bool = false
var curandera_posicion: Vector3 = POSICION_CURANDERA + Vector3(0, 0, -1.8)
var puerta_curandera_posicion: Vector3 = POSICION_CURANDERA + Vector3(0, 0, 3.5)
var aviso_curandera: String = ""
var puerta_explorador: StaticBody3D
var visual_puerta: MeshInstance3D
var pomo_explorador: Node3D
var techo_explorador: Node3D
var visual_cofre: Node3D
var etiqueta_interaccion: Label
var puerta_abierta: bool = false
var cofre_abierto: bool = false
var recompensa_cofre_entregada: bool = false
var puerta_posicion: Vector3 = POSICION_CASA_EXPLORADOR + Vector3(0, 0, 4.0)
var cofre_posicion: Vector3 = POSICION_CASA_EXPLORADOR + Vector3(-2.5, 0, -2.6)

func _ready() -> void:
    heroe = get_node_or_null("Heroe") as Node3D
    _cargar_cofre()
    construir_aldea()
    _crear_interfaz()
    _actualizar_cofre()
    print("ALDEA DEL DESPERTAR: escenario inicial generado")

func _process(_delta: float) -> void:
    if heroe == null:
        return
    var posicion: Vector3 = heroe.global_position
    var dentro: bool = absf(posicion.x - POSICION_CASA_EXPLORADOR.x) < 3.85 and absf(posicion.z - POSICION_CASA_EXPLORADOR.z) < 3.85
    if techo_explorador != null:
        techo_explorador.visible = not dentro
    var dentro_curandera: bool = absf(posicion.x - POSICION_CURANDERA.x) < 3.3 and absf(posicion.z - POSICION_CURANDERA.z) < 3.3
    if techo_curandera != null:
        techo_curandera.visible = not dentro_curandera
    if etiqueta_interaccion == null:
        return
    etiqueta_interaccion.visible = false
    if puerta_curandera_abierta and _distancia_plana(posicion, curandera_posicion) < 2.0:
        etiqueta_interaccion.text = "E - Hablar con la Curandera (curar)"
        etiqueta_interaccion.visible = true
    elif _distancia_plana(posicion, puerta_curandera_posicion) < 2.5:
        etiqueta_interaccion.text = "E - Cerrar Casa de la Curandera" if puerta_curandera_abierta else "E - Abrir Casa de la Curandera"
        etiqueta_interaccion.visible = true
    elif not puerta_abierta and _distancia_plana(posicion, puerta_posicion) < 2.8:
        etiqueta_interaccion.text = "E - Abrir Casa del Explorador"
        etiqueta_interaccion.visible = true
    elif puerta_abierta and _distancia_plana(posicion, cofre_posicion) < 1.65:
        etiqueta_interaccion.text = "Cofre abierto" if recompensa_cofre_entregada else ("E - Recoger guantes pendientes" if cofre_abierto else "E - Abrir cofre del explorador")
        etiqueta_interaccion.visible = true
    elif puerta_abierta and _distancia_plana(posicion, puerta_posicion) < 2.8:
        etiqueta_interaccion.text = "E - Cerrar puerta"
        etiqueta_interaccion.visible = true

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    # Herramientas temporales para pruebas; no funcionan en exportaciones release.
    if OS.has_feature("debug") and event.keycode in [KEY_F7, KEY_P, KEY_F9]:
        _atajo_prueba(event.keycode)
        get_viewport().set_input_as_handled()
        return
    if event.keycode != KEY_E or heroe == null:
        return
    var posicion: Vector3 = heroe.global_position
    if puerta_curandera_abierta and _distancia_plana(posicion, curandera_posicion) < 2.0:
        _hablar_curandera()
        get_viewport().set_input_as_handled()
        return
    if _distancia_plana(posicion, puerta_curandera_posicion) < 2.5:
        if puerta_curandera_abierta and _distancia_plana(posicion, puerta_curandera_posicion) < 0.85:
            return
        puerta_curandera_abierta = not puerta_curandera_abierta
        if puerta_curandera != null:
            puerta_curandera.collision_layer = 0 if puerta_curandera_abierta else 1
        if visual_puerta_curandera != null:
            visual_puerta_curandera.visible = not puerta_curandera_abierta
        get_viewport().set_input_as_handled()
        return
    if puerta_abierta and not recompensa_cofre_entregada and _distancia_plana(posicion, cofre_posicion) < 1.65:
        _abrir_cofre()
        get_viewport().set_input_as_handled()
        return
    if _distancia_plana(posicion, puerta_posicion) < 2.8:
        if puerta_abierta:
            # Evita cerrar la puerta encima del heroe.
            if _distancia_plana(posicion, puerta_posicion) < 0.85:
                return
        puerta_abierta = not puerta_abierta
        if puerta_explorador != null:
            puerta_explorador.collision_layer = 0 if puerta_abierta else 1
        if visual_puerta != null:
            visual_puerta.visible = not puerta_abierta
        if pomo_explorador != null:
            pomo_explorador.visible = not puerta_abierta
        get_viewport().set_input_as_handled()

func _atajo_prueba(tecla: int) -> void:
    if heroe == null or not is_instance_valid(heroe):
        print("PRUEBAS: Heroe no encontrado.")
        return
    if bool(heroe.get("esta_muerto")):
        print("PRUEBAS: No se modifican recursos de un heroe derrotado.")
        return
    var vida: int = int(heroe.get("vida_actual"))
    var vida_max: int = int(heroe.get("vida_maxima"))
    var pe: float = float(heroe.get("pe_actual"))
    var pe_max: float = float(heroe.get("pe_maximo"))
    match tecla:
        KEY_F7:
            # No aplica dano real ni mata al heroe: solo reduce la barra.
            var nueva_vida: int = maxi(1, vida - 100)
            heroe.set("vida_actual", nueva_vida)
            heroe.set("tiempo_desde_ultimo_dano", 0.0)
            heroe.set("temporizador_regeneracion", 0.0)
            heroe.call("actualizar_interfaz")
            print("PRUEBA F7 | VIDA: %d -> %d / %d" % [vida, nueva_vida, vida_max])
            DatosJugador.avisar_evento("PRUEBA: -%d vida. Visita a la Curandera." % (vida - nueva_vida), "advertencia")
        KEY_P:
            var nuevo_pe: float = maxf(0.0, pe - 50.0)
            heroe.set("pe_actual", nuevo_pe)
            heroe.set("tiempo_desde_ultimo_gasto_pe", 0.0)
            heroe.set("tiempo_para_siguiente_pulso_pe", 0.0)
            heroe.call("actualizar_interfaz")
            print("PRUEBA P | PE: %.0f -> %.0f / %.0f" % [pe, nuevo_pe, pe_max])
            DatosJugador.avisar_evento("PRUEBA: -%.0f PE. Visita a la Curandera." % (pe - nuevo_pe), "advertencia")
        KEY_F9:
            print("PRUEBA F9 | VIDA: %d/%d | PE: %.0f/%.0f" % [vida, vida_max, pe, pe_max])
            DatosJugador.avisar_evento("ESTADO | Vida %d/%d | PE %.0f/%.0f" % [vida, vida_max, pe, pe_max], "info")

func _hablar_curandera() -> void:
    if heroe == null or not is_instance_valid(heroe):
        return
    if bool(heroe.get("esta_muerto")):
        DatosJugador.avisar_evento("Curandera: No puedo atender a un heroe derrotado.", "advertencia")
        return

    var vida_maxima: int = int(heroe.get("vida_maxima"))
    var vida_anterior: int = int(heroe.get("vida_actual"))
    var pe_maximo: float = float(heroe.get("pe_maximo"))
    var pe_anterior: float = float(heroe.get("pe_actual"))
    var cambio_heroe: bool = vida_anterior < vida_maxima or pe_anterior < pe_maximo
    if cambio_heroe:
        heroe.set("vida_actual", vida_maxima)
        heroe.set("pe_actual", pe_maximo)
        heroe.call("actualizar_interfaz")

    var cambio_cadejo: bool = _curar_cadejo_blanco()
    if cambio_heroe or cambio_cadejo:
        DatosJugador.avisar_evento("Curandera: Vida, energia y espiritu restaurados.", "info")
    else:
        DatosJugador.avisar_evento("Curandera: Todos estan recuperados.", "info")
    print("CURANDERA: vida %d/%d -> %d/%d | PE %.0f -> %.0f | Cadejo curado: %s" % [vida_anterior, vida_maxima, int(heroe.get("vida_actual")), vida_maxima, pe_anterior, float(heroe.get("pe_actual")), str(cambio_cadejo)])

func _curar_cadejo_blanco() -> bool:
    # No desbloquear un companero que aun no ha sido obtenido.
    if not DatosJugador.companero_esta_desbloqueado("cadejo_blanco"):
        return false

    var maximo: int = DatosJugador.vida_maxima_cadejo_blanco()
    var activo: Node3D = null
    var candidato: Variant = heroe.get("cadejo_blanco_activo")
    if candidato is Node3D and is_instance_valid(candidato):
        activo = candidato as Node3D

    # Si esta invocado, sanar al personaje y sincronizar la vida persistente.
    # Nunca reanimar un companero que ya entro en agotamiento.
    if activo != null and not bool(activo.get("agotado")):
        var antes: int = int(activo.get("vida_actual"))
        if antes >= maximo:
            return false
        activo.set("vida_actual", maximo)
        activo.call("actualizar_barra_vida")
        DatosJugador.guardar_vida_cadejo(maximo)
        print("CURANDERA | Cadejo invocado: %d -> %d" % [antes, maximo])
        return true

    # La Curandera restaura tambien el agotamiento espiritual.
    # No revivimos directamente el nodo agotado: la reinvocacion sigue
    # pasando por el flujo normal del Heroe al pulsar R.
    DatosJugador.actualizar_descanso_cadejo()
    var anterior: int = int(DatosJugador.vida_guardada_cadejo)
    var espera_anterior: int = DatosJugador.segundos_agotamiento_restantes()
    var necesita_cura: bool = anterior < maximo or espera_anterior > 0
    if not necesita_cura:
        return false
    DatosJugador.vida_guardada_cadejo = maximo
    DatosJugador.fin_agotamiento_cadejo = 0
    DatosJugador.inicio_descanso_cadejo = 0
    DatosJugador.resto_descanso_cadejo = 0
    DatosJugador.guardar_progreso_cadejo_blanco()
    DatosJugador.avisar_evento("Curandera: Cadejo recuperado. Puedes invocarlo con R.", "info")
    print("CURANDERA | Cadejo: %d -> %d | Agotamiento: %d -> 0 s" % [anterior, maximo, espera_anterior])
    return true

func _distancia_plana(a: Vector3, b: Vector3) -> float:
    return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))

func _crear_interfaz() -> void:
    var capa := CanvasLayer.new()
    capa.name = "InterfazCasaExplorador"
    capa.layer = 8
    add_child(capa)
    etiqueta_interaccion = Label.new()
    etiqueta_interaccion.name = "AvisoInteraccionCasa"
    etiqueta_interaccion.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    etiqueta_interaccion.position = Vector2(-155, -110)
    etiqueta_interaccion.add_theme_font_size_override("font_size", 19)
    etiqueta_interaccion.visible = false
    capa.add_child(etiqueta_interaccion)

func _cargar_cofre() -> void:
    if not FileAccess.file_exists(ARCHIVO_COFRES):
        return
    var archivo := FileAccess.open(ARCHIVO_COFRES, FileAccess.READ)
    if archivo == null:
        push_warning("No se pudo leer el estado de cofres")
        return
    var datos: Variant = archivo.get_var()
    archivo.close()
    if datos is Dictionary:
        cofre_abierto = bool(datos.get(ID_COFRE_EXPLORADOR, false))
        # Compatibilidad: cofres abiertos con el codigo anterior no
        # habian entregado necesariamente la recompensa.
        recompensa_cofre_entregada = bool(datos.get("casa_explorador_recompensa_entregada", false))

func _guardar_cofre() -> bool:
    var archivo := FileAccess.open(ARCHIVO_COFRES, FileAccess.WRITE)
    if archivo == null:
        push_error("No se pudo guardar el cofre")
        return false
    archivo.store_var({
        ID_COFRE_EXPLORADOR: cofre_abierto,
        "casa_explorador_recompensa_entregada": recompensa_cofre_entregada
    })
    archivo.close()
    return true

func _abrir_cofre() -> void:
    if recompensa_cofre_entregada:
        print("CASA DEL EXPLORADOR: recompensa ya recogida")
        return

    # La recompensa de este cofre es unica por partida, pero puede
    # obtenerse aunque el heroe ya posea otro par de guantes.
    DatosJugador.agregar_objeto_catalogo("guantes_aventurero", 1)
    DatosJugador.guardar_inventario_equipamiento()
    cofre_abierto = true
    recompensa_cofre_entregada = true
    if not _guardar_cofre():
        push_warning("Guantes entregados, pero no se pudo guardar el estado del cofre")
    print("CASA DEL EXPLORADOR: +1 Guantes del Aventurero | recompensa unica")
    _actualizar_cofre()

func _actualizar_cofre() -> void:
    if visual_cofre == null:
        return
    var tapa: Node3D = visual_cofre.get_node_or_null("Tapa")
    if tapa != null:
        tapa.rotation_degrees.x = -65.0 if cofre_abierto else 0.0

func material_color(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.95
    return material

func _caja_en(padre: Node3D, nombre: String, posicion: Vector3, dimensiones: Vector3, color: Color, colision: bool = false) -> Node3D:
    var nodo := Node3D.new()
    nodo.name = nombre
    nodo.position = posicion
    padre.add_child(nodo)
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
    return nodo

func agregar_caja(nombre: String, posicion: Vector3, dimensiones: Vector3, color: Color, colision: bool = false) -> Node3D:
    return _caja_en(self, nombre, posicion, dimensiones, color, colision)

func agregar_cilindro(nombre: String, posicion: Vector3, radio: float, altura: float, color: Color, colision: bool = false) -> Node3D:
    var nodo := Node3D.new()
    nodo.name = nombre
    nodo.position = posicion
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

func agregar_casa(nombre: String, posicion: Vector3, ancho: float = 6.5, fondo: float = 6.5) -> void:
    # Viviendas decorativas con la misma arquitectura que la Casa del Explorador.
    # Siguen cerradas hasta implementar sus interiores en etapas posteriores.
    var casa := Node3D.new()
    casa.name = nombre
    casa.position = posicion
    add_child(casa)
    var color_pared := Color(0.90, 0.80, 0.61)
    if nombre == "Casa03":
        color_pared = Color(0.83, 0.79, 0.66)
    elif nombre == "Casa04":
        color_pared = Color(0.93, 0.73, 0.57)
    var madera := Color(0.33, 0.19, 0.11)
    var altura := 4.5
    _caja_en(casa, "Muros", Vector3(0, altura * 0.5, 0), Vector3(ancho, altura, fondo), color_pared, true)
    _caja_en(casa, "PuertaDecorativa", Vector3(0, 1.5, fondo * 0.5 + 0.12), Vector3(1.9, 3, 0.12), madera)
    _caja_en(casa, "MarcoPuertaSuperior", Vector3(0, 3.07, fondo * 0.5 + 0.20), Vector3(2.2, 0.14, 0.20), madera)
    for x in [-1.05, 1.05]:
        _caja_en(casa, "MarcoPuerta_%s" % str(x), Vector3(x, 1.5, fondo * 0.5 + 0.20), Vector3(0.14, 3.1, 0.20), madera)
    _ventana(casa, "VentanaIzquierda", Vector3(-ancho * 0.34, 2.55, fondo * 0.5 + 0.16))
    _ventana(casa, "VentanaDerecha", Vector3(ancho * 0.34, 2.55, fondo * 0.5 + 0.16))
    _ventana(casa, "VentanaLateral", Vector3(ancho * 0.5 + 0.14, 2.55, -0.4), true)
    _techo_inclinado(casa, ancho, fondo, altura)

func _detalle_cilindro(padre: Node3D, nombre: String, posicion: Vector3, radio: float, altura: float, color: Color) -> void:
    var m := MeshInstance3D.new()
    m.name = nombre
    var mesh := CylinderMesh.new()
    mesh.top_radius = radio
    mesh.bottom_radius = radio
    mesh.height = altura
    m.mesh = mesh
    m.material_override = material_color(color)
    m.position = posicion
    padre.add_child(m)

func _triangulo_fachada(padre: Node3D, nombre: String, ancho: float, altura: float, z: float, color: Color) -> void:
    # Tapa triangular entre la pared recta y la cumbrera del techo.
    var superficie := SurfaceTool.new()
    superficie.begin(Mesh.PRIMITIVE_TRIANGLES)
    var izquierda := Vector3(-ancho * 0.5, altura, z)
    var derecha := Vector3(ancho * 0.5, altura, z)
    var punta := Vector3(0, altura + ancho * 0.27, z)
    for vertice in [izquierda, derecha, punta, punta, derecha, izquierda]:
        superficie.set_normal(Vector3(0, 0, 1))
        superficie.add_vertex(vertice)
    var malla := MeshInstance3D.new()
    malla.name = nombre
    malla.mesh = superficie.commit()
    malla.material_override = material_color(color)
    padre.add_child(malla)

func _techo_inclinado(padre: Node3D, ancho: float, fondo: float, altura: float) -> Node3D:
    var grupo := Node3D.new()
    grupo.name = "TechoInclinado"
    padre.add_child(grupo)
    var teja := Color(0.58, 0.20, 0.12)
    var madera := Color(0.37, 0.20, 0.12)
    var elevacion := ancho * 0.27
    var mitad := ancho * 0.5 + 0.45
    var inclinacion := rad_to_deg(atan2(elevacion, mitad))
    var largo_faldon := sqrt(mitad * mitad + elevacion * elevacion) + 0.10
    for lado in [-1, 1]:
        var pieza := _caja_en(grupo, "Tejas_%s" % str(lado),
            Vector3(lado * mitad * 0.5, altura + elevacion * 0.5, 0),
            Vector3(largo_faldon, 0.17, fondo + 0.95), teja)
        pieza.rotation_degrees.z = -inclinacion * lado
    _caja_en(grupo, "Cumbrera", Vector3(0, altura + elevacion + 0.03, 0),
        Vector3(0.24, 0.20, fondo + 1.02), madera)
    # Los frontones permanecen visibles también al ocultar el tejado.
    _triangulo_fachada(padre, "FrontonFrontal", ancho, altura, fondo * 0.5, Color(0.88, 0.76, 0.56))
    _triangulo_fachada(padre, "FrontonTrasero", ancho, altura, -fondo * 0.5, Color(0.88, 0.76, 0.56))
    return grupo

func _ventana(padre: Node3D, nombre: String, posicion: Vector3, lateral: bool = false) -> void:
    var marco := Color(0.31, 0.18, 0.10)
    var vidrio := Color(0.40, 0.70, 0.78)
    var ventana := Node3D.new()
    ventana.name = nombre
    ventana.position = posicion
    if lateral:
        ventana.rotation_degrees.y = 90.0
    padre.add_child(ventana)
    _caja_en(ventana, "Cristal", Vector3.ZERO, Vector3(1.2, 1.15, 0.07), vidrio)
    _caja_en(ventana, "MarcoSuperior", Vector3(0, 0.62, 0.04), Vector3(1.5, 0.13, 0.13), marco)
    _caja_en(ventana, "MarcoInferior", Vector3(0, -0.62, 0.04), Vector3(1.5, 0.13, 0.13), marco)
    for x in [-0.68, 0.68]:
        _caja_en(ventana, "MarcoLateral_%s" % str(x), Vector3(x, 0, 0.04), Vector3(0.13, 1.3, 0.13), marco)
    _caja_en(ventana, "Cruceta", Vector3(0, 0, 0.09), Vector3(0.11, 1.2, 0.08), marco)

func _construir_casa_explorador() -> void:
    var casa := Node3D.new()
    casa.name = "Casa01"
    casa.position = POSICION_CASA_EXPLORADOR
    add_child(casa)
    var pared := Color(0.88, 0.75, 0.53)
    var madera := Color(0.33, 0.19, 0.11)
    var altura := 4.5
    # Interior de 8 x 8 m; puerta al sur (+Z).
    _caja_en(casa, "ParedIzquierda", Vector3(-3.95, 2.25, 0), Vector3(0.20, altura, 8), pared, true)
    _caja_en(casa, "ParedDerecha", Vector3(3.95, 2.25, 0), Vector3(0.20, altura, 8), pared, true)
    _caja_en(casa, "ParedTrasera", Vector3(0, 2.25, -3.95), Vector3(8, altura, 0.20), pared, true)
    _caja_en(casa, "FrenteIzquierdo", Vector3(-2.55, 2.25, 3.95), Vector3(2.9, altura, 0.20), pared, true)
    _caja_en(casa, "FrenteDerecho", Vector3(2.55, 2.25, 3.95), Vector3(2.9, altura, 0.20), pared, true)
    _caja_en(casa, "Dintel", Vector3(0, 3.8, 3.95), Vector3(2.2, 1.4, 0.20), pared, true)
    _caja_en(casa, "MarcoPuertaIzq", Vector3(-1.13, 1.5, 4.08), Vector3(0.17, 3, 0.2), madera)
    _caja_en(casa, "MarcoPuertaDer", Vector3(1.13, 1.5, 4.08), Vector3(0.17, 3, 0.2), madera)
    _caja_en(casa, "MarcoPuertaArriba", Vector3(0, 3.05, 4.08), Vector3(2.4, 0.17, 0.2), madera)
    var puerta_nodo := _caja_en(casa, "Puerta", Vector3(0, 1.5, 4.07), Vector3(2.05, 3, 0.16), madera)
    visual_puerta = puerta_nodo.get_child(0) as MeshInstance3D
    puerta_explorador = StaticBody3D.new()
    puerta_explorador.name = "ColisionPuerta"
    var forma := CollisionShape3D.new()
    var caja := BoxShape3D.new()
    caja.size = Vector3(2.05, 3, 0.16)
    forma.shape = caja
    puerta_explorador.add_child(forma)
    puerta_nodo.add_child(puerta_explorador)
    pomo_explorador = Node3D.new()
    pomo_explorador.name = "PomoPuertaExplorador"
    casa.add_child(pomo_explorador)
    _detalle_cilindro(pomo_explorador, "Pomo", Vector3(0.75, 1.45, 4.20), 0.12, 0.16, Color(0.9, 0.69, 0.26))
    _ventana(casa, "VentanaFrenteIzq", Vector3(-2.55, 2.55, 4.08))
    _ventana(casa, "VentanaFrenteDer", Vector3(2.55, 2.55, 4.08))
    _ventana(casa, "VentanaLateral", Vector3(4.08, 2.5, -0.5), true)
    # Vigas, zocalos y aleros.
    for x in [-3.65, 3.65]:
        _caja_en(casa, "VigaFrontal_%s" % str(x), Vector3(x, 2.25, 4.12), Vector3(0.24, 4.5, 0.25), madera)
    _caja_en(casa, "ZocaloFrontalIzq", Vector3(-2.55, 0.28, 4.09), Vector3(2.9, 0.56, 0.14), Color(0.48, 0.37, 0.29))
    _caja_en(casa, "ZocaloFrontalDer", Vector3(2.55, 0.28, 4.09), Vector3(2.9, 0.56, 0.14), Color(0.48, 0.37, 0.29))
    techo_explorador = _techo_inclinado(casa, 8, 8, altura)
    _caja_en(casa, "SueloInterior", Vector3(0, 0.025, 0), Vector3(7.7, 0.05, 7.7), Color(0.56, 0.37, 0.23))
    # Cama de madera con almohada y manta.
    _caja_en(casa, "CamaBase", Vector3(-2.45, 0.43, 0.0), Vector3(1.7, 0.55, 2.5), madera, true)
    _caja_en(casa, "Colchon", Vector3(-2.45, 0.76, 0), Vector3(1.56, 0.16, 2.35), Color(0.88, 0.82, 0.68))
    _caja_en(casa, "Manta", Vector3(-2.45, 0.86, 0.50), Vector3(1.55, 0.08, 1.25), Color(0.18, 0.43, 0.56))
    _caja_en(casa, "Almohada", Vector3(-2.45, 0.89, -0.91), Vector3(1.18, 0.12, 0.35), Color(0.96, 0.92, 0.78))
    # Mesa, patas, taburetes y estante.
    _caja_en(casa, "MesaTablero", Vector3(1.75, 1.0, -1.65), Vector3(2.1, 0.17, 1.25), madera, true)
    for x in [0.90, 2.60]:
        for z in [-2.08, -1.22]:
            _caja_en(casa, "PataMesa_%s_%s" % [str(x), str(z)], Vector3(x, 0.48, z), Vector3(0.17, 0.94, 0.17), madera)
    _caja_en(casa, "Taburete", Vector3(1.8, 0.46, 0.1), Vector3(0.8, 0.92, 0.8), Color(0.46, 0.27, 0.13), true)
    _caja_en(casa, "Estanteria", Vector3(3.18, 1.45, -2.9), Vector3(0.9, 2.8, 1.3), madera, true)
    for y in [0.65, 1.3, 2.0]:
        _caja_en(casa, "Repisa_%s" % str(y), Vector3(2.66, y, -2.9), Vector3(0.12, 0.12, 1.3), Color(0.68, 0.42, 0.22))
    # Cofre en la esquina trasera izquierda.
    visual_cofre = Node3D.new()
    visual_cofre.name = "CofreExplorador"
    visual_cofre.position = Vector3(-2.5, 0, -2.6)
    casa.add_child(visual_cofre)
    _caja_en(visual_cofre, "Base", Vector3(0, 0.4, 0), Vector3(1.15, 0.8, 0.85), Color(0.43, 0.23, 0.12), true)
    for x in [-0.43, 0.43]:
        _caja_en(visual_cofre, "Herraje_%s" % str(x), Vector3(x, 0.4, 0.44), Vector3(0.13, 0.75, 0.08), Color(0.73, 0.57, 0.27))
    var tapa := Node3D.new()
    tapa.name = "Tapa"
    tapa.position = Vector3(0, 0.82, -0.34)
    visual_cofre.add_child(tapa)
    _caja_en(tapa, "MaderaTapa", Vector3(0, 0, 0.34), Vector3(1.2, 0.2, 0.9), Color(0.60, 0.35, 0.17))
    _caja_en(visual_cofre, "Cerradura", Vector3(0, 0.46, 0.45), Vector3(0.20, 0.25, 0.07), Color(0.91, 0.73, 0.28))

func _construir_casa_curandera() -> void:
    var casa := Node3D.new()
    casa.name = "Casa02"
    casa.position = POSICION_CURANDERA
    add_child(casa)
    var pared := Color(0.83, 0.79, 0.66)
    var madera := Color(0.33, 0.19, 0.11)
    var altura := 4.5
    var tamano := 7.0
    _caja_en(casa, "ParedIzquierda", Vector3(-3.45, 2.25, 0), Vector3(0.20, altura, tamano), pared, true)
    _caja_en(casa, "ParedDerecha", Vector3(3.45, 2.25, 0), Vector3(0.20, altura, tamano), pared, true)
    _caja_en(casa, "ParedTrasera", Vector3(0, 2.25, -3.45), Vector3(tamano, altura, 0.20), pared, true)
    _caja_en(casa, "FrenteIzquierdo", Vector3(-2.35, 2.25, 3.45), Vector3(2.3, altura, 0.20), pared, true)
    _caja_en(casa, "FrenteDerecho", Vector3(2.35, 2.25, 3.45), Vector3(2.3, altura, 0.20), pared, true)
    _caja_en(casa, "Dintel", Vector3(0, 3.8, 3.45), Vector3(2.4, 1.4, 0.20), pared, true)
    var puerta := _caja_en(casa, "Puerta", Vector3(0, 1.5, 3.57), Vector3(2.05, 3.0, 0.16), madera)
    visual_puerta_curandera = puerta.get_child(0) as MeshInstance3D
    puerta_curandera = StaticBody3D.new()
    puerta_curandera.name = "ColisionPuertaCurandera"
    var forma := CollisionShape3D.new()
    var caja := BoxShape3D.new()
    caja.size = Vector3(2.05, 3.0, 0.16)
    forma.shape = caja
    puerta_curandera.add_child(forma)
    puerta.add_child(puerta_curandera)
    _ventana(casa, "VentanaFrenteIzq", Vector3(-2.35, 2.55, 3.58))
    _ventana(casa, "VentanaFrenteDer", Vector3(2.35, 2.55, 3.58))
    _ventana(casa, "VentanaLateral", Vector3(3.58, 2.55, -0.5), true)
    techo_curandera = _techo_inclinado(casa, tamano, tamano, altura)
    _caja_en(casa, "SueloInterior", Vector3(0, 0.025, 0), Vector3(6.7, 0.05, 6.7), Color(0.55, 0.37, 0.24))
    _caja_en(casa, "Camilla", Vector3(-1.8, 0.55, -1.7), Vector3(1.7, 0.65, 2.6), madera, true)
    _caja_en(casa, "Sabana", Vector3(-1.8, 0.91, -1.7), Vector3(1.6, 0.09, 2.5), Color(0.90, 0.88, 0.76))
    _caja_en(casa, "MesaHierbas", Vector3(1.7, 0.85, 1.3), Vector3(1.7, 1.2, 1.1), madera, true)
    for x in [1.1, 1.7, 2.3]:
        _detalle_cilindro(casa, "Frasco_%s" % str(x), Vector3(x, 1.65, 1.3), 0.16, 0.40, Color(0.21, 0.53, 0.36))
    _caja_en(casa, "Estante", Vector3(2.9, 1.45, -2.5), Vector3(0.65, 2.7, 1.3), madera, true)
    # NPC provisional, separado de la camilla y del acceso.
    var npc := Node3D.new()
    npc.name = "Curandera"
    npc.position = Vector3(0, 0, -1.8)
    casa.add_child(npc)
    var colision_npc := StaticBody3D.new()
    colision_npc.name = "ColisionCurandera"
    var forma_npc := CollisionShape3D.new()
    var capsula_npc := CapsuleShape3D.new()
    capsula_npc.radius = 0.42
    capsula_npc.height = 1.9
    forma_npc.shape = capsula_npc
    forma_npc.position = Vector3(0, 0.95, 0)
    colision_npc.add_child(forma_npc)
    npc.add_child(colision_npc)
    _detalle_cilindro(npc, "Cuerpo", Vector3(0, 0.95, 0), 0.37, 1.35, Color(0.25, 0.45, 0.30))
    var cabeza := MeshInstance3D.new()
    cabeza.name = "Cabeza"
    var esfera := SphereMesh.new()
    esfera.radius = 0.33
    esfera.height = 0.66
    cabeza.mesh = esfera
    cabeza.position = Vector3(0, 1.92, 0)
    cabeza.material_override = material_color(Color(0.72, 0.50, 0.36))
    npc.add_child(cabeza)

func construir_aldea() -> void:
    agregar_caja("Terreno", Vector3(0, -0.2, 0), Vector3(TAMANO_TERRENO, 0.4, TAMANO_TERRENO), Color(0.26, 0.48, 0.22), true)
    agregar_caja("CaminoPrincipal", Vector3(0, 0.025, 0), Vector3(4.5, 0.05, 57), Color(0.66, 0.54, 0.35))
    agregar_caja("CaminoPlaza", Vector3(0, 0.03, 2), Vector3(32, 0.05, 4), Color(0.66, 0.54, 0.35))
    agregar_cilindro("PlazaCentral", Vector3(0, 0.07, 2), 5.0, 0.12, Color(0.65, 0.62, 0.52))
    agregar_cilindro("BaseSantuario", Vector3(0, 0.4, 2), 1.0, 0.8, Color(0.58, 0.59, 0.62), true)
    agregar_cilindro("MonolitoSantuario", Vector3(0, 1.65, 2), 0.34, 1.7, Color(0.34, 0.68, 0.78), true)
    _construir_casa_explorador()
    _construir_casa_curandera()
    agregar_casa("Casa03", Vector3(-12, 0, 13), 7.0, 7.0)
    agregar_casa("Casa04", Vector3(12, 0, 13), 7.0, 7.0)
    var posiciones_arboles: Array[Vector3] = [
        Vector3(-24, 0, -24), Vector3(-18, 0, -22), Vector3(-8, 0, -24),
        Vector3(9, 0, -24), Vector3(20, 0, -22), Vector3(25, 0, -13),
        Vector3(-25, 0, -9), Vector3(-24, 0, 8), Vector3(24, 0, 7),
        Vector3(-24, 0, 24), Vector3(-14, 0, 25), Vector3(15, 0, 24),
        Vector3(24, 0, 23), Vector3(5, 0, 27)
    ]
    for i in range(posiciones_arboles.size()):
        agregar_arbol("Arbol%02d" % (i + 1), posiciones_arboles[i])
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
