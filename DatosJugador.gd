extends Node

signal inventario_actualizado
signal objeto_obtenido(id_objeto: String, cantidad: int)
signal carta_desbloqueada(id_carta: String)
signal equipamiento_actualizado

const COSTO_CENIZA_CIPITIO: int = 100
const ID_CARTA_CENIZA: String = "carta_ceniza_cipitio"

var nombre: String = ""
var pais: String = ""
var region: String = ""
var afinidad: String = ""

var color_piel: Color = Color("#C98F65")
var color_camisa: Color = Color("#244A73")
var color_pantalon: Color = Color("#2F3540")

var catalogo_objetos: Dictionary = {
    "fragmento_esencia": {"nombre": "Fragmento de esencia", "tipo": "Material", "rareza": "Común", "descripcion": "Fragmento de energía obtenido de criaturas.", "icono": "res://iconos/fragmento_esencia.png"},
    "ceniza_encantada": {"nombre": "Ceniza encantada", "tipo": "Material", "rareza": "Raro", "descripcion": "Ceniza impregnada de magia del Cipitío.", "icono": "res://iconos/ceniza_encantada.png"},
    "sombrero_deteriorado": {"nombre": "Sombrero deteriorado", "tipo": "Material", "rareza": "Raro", "descripcion": "Un sombrero antiguo utilizado por los mini Cipitíos.", "icono": "res://iconos/sombrero_deteriorado.png"},
    "sombrero_cipitio": {"nombre": "Sombrero legendario del Cipitío", "tipo": "Equipamiento", "rareza": "Legendario", "descripcion": "Un sombrero que contiene poderes sobrenaturales.", "icono": ""},
    "corazon_cipitio": {"nombre": "Corazón del Cipitío", "tipo": "Material", "rareza": "Legendario", "descripcion": "Corazón mágico obtenido al derrotar al Cipitío Legendario.", "icono": "res://iconos/corazon_cipitio.png"},
    "ceniza_ancestral": {"nombre": "Ceniza ancestral", "tipo": "Material", "rareza": "Legendario", "descripcion": "Ceniza sobrenatural concentrada del Cipitío Legendario.", "icono": "res://iconos/ceniza_ancestral.png"},
    "tecomate_espiritus": {"nombre": "Tecomate de los Espíritus", "tipo": "Equipamiento", "rareza": "Legendario", "descripcion": "Recipiente encantado que permitirá capturar e invocar compañeros.", "icono": "res://iconos/tecomate_espiritus.png"},
    "guantes_reforzados": {"nombre": "Guantes Reforzados", "tipo": "Equipamiento", "rareza": "Raro", "descripcion": "Guantes de prueba para comprobar que cada par conserva su carta. Defensa inicial: +5. Una ranura.", "icono": "res://iconos/guantes_aventurero.svg"},
    "guantes_aventurero": {"nombre": "Guantes del Aventurero", "tipo": "Equipamiento", "rareza": "Común", "descripcion": "Guantes iniciales. Defensa inicial: +2. Incluyen una ranura para cartas mágicas.", "icono": "res://iconos/guantes_aventurero.svg"},
    "carta_ceniza_cipitio": {"nombre": "Carta: Ceniza del Cipitío", "tipo": "Carta", "rareza": "Legendario", "descripcion": "Consume 100 cenizas ancestrales para desbloquear su habilidad. La carta se conserva y después podrás equiparla en tus guantes.", "icono": "res://iconos/carta_ceniza_cipitio_icono.png"}
}

var fragmentos_esencia: int = 0
var cartas_desbloqueadas: Dictionary = {}

# Etapa inicial: guantes básicos con un espacio para cartas.
# Más adelante, los grados y las estrellas podrán ampliar este valor.
# Cada tipo de guantes tiene sus ranuras independientes.
# Los ejemplares idénticos todavía se agrupan por tipo en el inventario.
var guantes_seleccionados: String = "guantes_aventurero"
var guantes_puestos: String = "guantes_aventurero"
var ranuras_por_guantes: Dictionary = {"guantes_aventurero": 1, "guantes_reforzados": 1}
var cartas_por_guantes: Dictionary = {"guantes_aventurero": [""], "guantes_reforzados": [""]}

# Atributos independientes por tipo. Preparados para refinado futuro.
# Al permitir dos copias del mismo tipo, migraremos estas claves a IDs de ejemplar.
var atributos_guantes: Dictionary = {
    "guantes_aventurero": {"defensa_base": 2, "refinado": 0, "defensa_refinado": 0},
    "guantes_reforzados": {"defensa_base": 5, "refinado": 0, "defensa_refinado": 0}
}

# Refinado provisional +0 a +5: coste y defensa adicional por nivel.
const MAX_REFINADO_GUANTES: int = 5
const COSTOS_REFINADO_GUANTES: Array[int] = [10, 20, 40, 80, 160]
const BONOS_REFINADO_AVENTURERO: Array[int] = [0, 1, 2, 3, 4, 6]
const BONOS_REFINADO_REFORZADOS: Array[int] = [0, 1, 2, 3, 4, 7]

func obtener_nivel_refinado_guantes(id_guantes: String) -> int:
    if not es_guante(id_guantes):
        return 0
    return int(atributos_guantes.get(id_guantes, {}).get("refinado", 0))

func obtener_costo_refinado_guantes(id_guantes: String) -> int:
    if not es_guante(id_guantes):
        return 0
    var nivel: int = obtener_nivel_refinado_guantes(id_guantes)
    if nivel >= MAX_REFINADO_GUANTES:
        return 0
    return COSTOS_REFINADO_GUANTES[nivel]

func puede_refinar_guantes(id_guantes: String) -> bool:
    if not es_guante(id_guantes) or not tiene_objeto(id_guantes):
        return false
    if obtener_nivel_refinado_guantes(id_guantes) >= MAX_REFINADO_GUANTES:
        return false
    return tiene_objeto("fragmento_esencia", obtener_costo_refinado_guantes(id_guantes))

func refinar_guantes(id_guantes: String) -> bool:
    if not puede_refinar_guantes(id_guantes):
        return false
    var costo: int = obtener_costo_refinado_guantes(id_guantes)
    if not consumir_objeto("fragmento_esencia", costo):
        return false
    var nivel_nuevo: int = obtener_nivel_refinado_guantes(id_guantes) + 1
    atributos_guantes[id_guantes]["refinado"] = nivel_nuevo
    if id_guantes == "guantes_reforzados":
        atributos_guantes[id_guantes]["defensa_refinado"] = BONOS_REFINADO_REFORZADOS[nivel_nuevo]
    else:
        atributos_guantes[id_guantes]["defensa_refinado"] = BONOS_REFINADO_AVENTURERO[nivel_nuevo]
    equipamiento_actualizado.emit()
    inventario_actualizado.emit()
    print("GUANTES REFINADOS: ", id_guantes, " +", nivel_nuevo, " | Costo: ", costo, " fragmentos | Defensa: +", obtener_defensa_guantes(id_guantes))
    return true

func obtener_defensa_guantes(id_guantes: String) -> int:
    if not es_guante(id_guantes) or not tiene_objeto(id_guantes):
        return 0
    var atributos: Dictionary = atributos_guantes.get(id_guantes, {})
    return maxi(0, int(atributos.get("defensa_base", 0)) + int(atributos.get("defensa_refinado", 0)))

func obtener_defensa_guantes_puestos() -> int:
    return obtener_defensa_guantes(guantes_puestos)



var inventario: Dictionary = {
    "fragmento_esencia": {"nombre": "Fragmento de esencia", "tipo": "Material", "cantidad": 0, "rareza": "Común", "descripcion": "Fragmento de energía obtenido de criaturas.", "icono": "res://iconos/fragmento_esencia.png"}
}

# =========================================================
# EQUIPO INICIAL Y PRUEBA TEMPORAL
# =========================================================
func _ready() -> void:
    # Equipo inicial permanente; NO borrar al retirar la prueba.
    if not tiene_objeto("guantes_aventurero"):
        agregar_objeto_catalogo("guantes_aventurero", 1)
    # INICIO LLAMADA DE PRUEBA - BORRAR ESTA LINEA DESPUES
    call_deferred("prueba_equipamiento")
    # FIN LLAMADA DE PRUEBA

# INICIO DE PRUEBA TEMPORAL DE EQUIPAMIENTO - BORRAR DESPUES
func prueba_equipamiento() -> void:
    agregar_objeto_catalogo("guantes_reforzados", 1) # SEGUNDO PAR DE PRUEBA: borrar esta línea después
    agregar_objeto_catalogo("carta_ceniza_cipitio", 1)
    agregar_objeto_catalogo("ceniza_ancestral", 100)
    agregar_objeto_catalogo("fragmento_esencia", 350) # PRUEBA TEMPORAL: borrar junto con prueba_equipamiento
    print("==============================")
    print("PRUEBA DE EQUIPAMIENTO")
    print("Carta del Cipitío: ", obtener_cantidad_objeto("carta_ceniza_cipitio"))
    print("Cenizas ancestrales: ", obtener_cantidad_objeto("ceniza_ancestral"))
    print("==============================")
# =========================================================
# FIN DE PRUEBA TEMPORAL DE EQUIPAMIENTO - BORRAR DESPUES
# =========================================================

# =========================================================

func asignar_region_y_afinidad() -> void:
    var centroamerica: Array = ["El Salvador", "Guatemala", "Honduras", "Nicaragua", "Costa Rica", "Panamá", "Belice"]
    if pais in centroamerica:
        region = "Centroamérica"
        afinidad = "Naturaleza"
    else:
        region = ""
        afinidad = ""
    print("==============================")
    print("DATOS DEL JUGADOR")
    print("País: ", pais)
    print("Región: ", region)
    print("Afinidad: ", afinidad)
    print("==============================")

func agregar_objeto(id_objeto: String, nombre_objeto: String, tipo_objeto: String, cantidad: int = 1, rareza: String = "Común") -> void:
    if cantidad <= 0:
        return
    if inventario.has(id_objeto):
        inventario[id_objeto]["cantidad"] += cantidad
    else:
        var datos: Dictionary = catalogo_objetos.get(id_objeto, {})
        inventario[id_objeto] = {
            "nombre": datos.get("nombre", nombre_objeto),
            "tipo": datos.get("tipo", tipo_objeto),
            "cantidad": cantidad,
            "rareza": datos.get("rareza", rareza),
            "descripcion": datos.get("descripcion", ""),
            "icono": datos.get("icono", "")
        }
    if id_objeto == "fragmento_esencia":
        fragmentos_esencia = obtener_cantidad_objeto("fragmento_esencia")
    inventario_actualizado.emit()
    objeto_obtenido.emit(id_objeto, cantidad)

func agregar_objeto_catalogo(id_objeto: String, cantidad: int = 1) -> void:
    if not catalogo_objetos.has(id_objeto):
        push_warning("Objeto desconocido: " + id_objeto)
        return
    var datos: Dictionary = catalogo_objetos[id_objeto]
    agregar_objeto(id_objeto, str(datos.get("nombre", "Objeto")), str(datos.get("tipo", "Material")), cantidad, str(datos.get("rareza", "Común")))

func agregar_fragmentos_esencia(cantidad: int) -> void:
    agregar_objeto_catalogo("fragmento_esencia", cantidad)

func obtener_cantidad_objeto(id_objeto: String) -> int:
    if not inventario.has(id_objeto):
        return 0
    return int(inventario[id_objeto].get("cantidad", 0))

func obtener_objeto(id_objeto: String) -> Dictionary:
    if not inventario.has(id_objeto):
        return {}
    return inventario[id_objeto].duplicate(true)

func tiene_objeto(id_objeto: String, cantidad: int = 1) -> bool:
    if cantidad <= 0:
        return false
    return obtener_cantidad_objeto(id_objeto) >= cantidad

func consumir_objeto(id_objeto: String, cantidad: int = 1) -> bool:
    if cantidad <= 0 or not tiene_objeto(id_objeto, cantidad):
        return false
    inventario[id_objeto]["cantidad"] -= cantidad
    if id_objeto == "fragmento_esencia":
        fragmentos_esencia = obtener_cantidad_objeto("fragmento_esencia")
    inventario_actualizado.emit()
    return true

# El desbloqueo es irreversible durante la partida, pero no equipa la carta.
func carta_esta_desbloqueada(id_carta: String) -> bool:
    return bool(cartas_desbloqueadas.get(id_carta, false))

func puede_desbloquear_ceniza_cipitio() -> bool:
    return tiene_objeto(ID_CARTA_CENIZA) and not carta_esta_desbloqueada(ID_CARTA_CENIZA) and tiene_objeto("ceniza_ancestral", COSTO_CENIZA_CIPITIO)

func desbloquear_ceniza_cipitio() -> bool:
    if not puede_desbloquear_ceniza_cipitio():
        return false
    # Se consumen las cenizas, pero nunca la carta.
    if not consumir_objeto("ceniza_ancestral", COSTO_CENIZA_CIPITIO):
        return false
    cartas_desbloqueadas[ID_CARTA_CENIZA] = true
    inventario_actualizado.emit()
    carta_desbloqueada.emit(ID_CARTA_CENIZA)
    print("CARTA DESBLOQUEADA: Ceniza del Cipitío")
    print("Cenizas consumidas: ", COSTO_CENIZA_CIPITIO)
    return true

# =========================================================
# EQUIPAMIENTO DE CARTAS EN GUANTES
# =========================================================
func es_guante(id_guantes: String) -> bool:
    return ranuras_por_guantes.has(id_guantes)

func seleccionar_guantes(id_guantes: String) -> bool:
    if not es_guante(id_guantes) or not tiene_objeto(id_guantes):
        return false
    guantes_seleccionados = id_guantes
    equipamiento_actualizado.emit()
    return true

func poner_guantes(id_guantes: String) -> bool:
    if not seleccionar_guantes(id_guantes):
        return false
    guantes_puestos = id_guantes
    equipamiento_actualizado.emit()
    inventario_actualizado.emit()
    print("GUANTES PUESTOS: ", id_guantes)
    return true

func obtener_ranuras(id_guantes: String) -> Array:
    return cartas_por_guantes.get(id_guantes, []).duplicate()

func carta_esta_equipada(id_carta: String) -> bool:
    for id_guantes in cartas_por_guantes:
        if id_carta in cartas_por_guantes[id_guantes]:
            return true
    return false

func guantes_de_carta(id_carta: String) -> String:
    for id_guantes in cartas_por_guantes:
        if id_carta in cartas_por_guantes[id_guantes]:
            return str(id_guantes)
    return ""

func puede_equipar_carta(id_carta: String, id_guantes: String = "", ranura: int = 0) -> bool:
    if id_guantes == "":
        id_guantes = guantes_seleccionados
    if not es_guante(id_guantes) or not tiene_objeto(id_guantes):
        return false
    if not catalogo_objetos.has(id_carta) or str(catalogo_objetos[id_carta].get("tipo", "")) != "Carta":
        return false
    if not tiene_objeto(id_carta) or not carta_esta_desbloqueada(id_carta):
        return false
    var espacios: Array = cartas_por_guantes[id_guantes]
    return ranura >= 0 and ranura < espacios.size() and str(espacios[ranura]) == "" and not carta_esta_equipada(id_carta)

func equipar_carta_guantes(id_carta: String, id_guantes: String = "", ranura: int = 0) -> bool:
    if id_guantes == "":
        id_guantes = guantes_seleccionados
    if not puede_equipar_carta(id_carta, id_guantes, ranura):
        return false
    cartas_por_guantes[id_guantes][ranura] = id_carta
    equipamiento_actualizado.emit()
    inventario_actualizado.emit()
    print("CARTA EQUIPADA: ", id_carta, " EN: ", id_guantes, " RANURA: ", ranura + 1)
    return true

func quitar_carta_guantes(id_carta: String) -> bool:
    var id_guantes: String = guantes_de_carta(id_carta)
    if id_guantes == "":
        return false
    var ranura: int = cartas_por_guantes[id_guantes].find(id_carta)
    cartas_por_guantes[id_guantes][ranura] = ""
    equipamiento_actualizado.emit()
    inventario_actualizado.emit()
    print("CARTA RETIRADA: ", id_carta, " DE: ", id_guantes)
    return true

func carta_activa(id_carta: String) -> bool:
    return id_carta in obtener_ranuras(guantes_puestos)
