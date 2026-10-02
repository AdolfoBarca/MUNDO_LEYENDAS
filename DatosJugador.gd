extends Node

signal inventario_actualizado
signal objeto_obtenido(id_objeto: String, cantidad: int)
signal carta_desbloqueada(id_carta: String)

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
    "carta_ceniza_cipitio": {"nombre": "Carta: Ceniza del Cipitío", "tipo": "Carta", "rareza": "Legendario", "descripcion": "Consume 100 cenizas ancestrales para desbloquear su habilidad. La carta se conserva y después podrás equiparla en tus guantes.", "icono": "res://iconos/carta_ceniza_cipitio_icono.png"}
}

var fragmentos_esencia: int = 0
var cartas_desbloqueadas: Dictionary = {}

var inventario: Dictionary = {
    "fragmento_esencia": {"nombre": "Fragmento de esencia", "tipo": "Material", "cantidad": 0, "rareza": "Común", "descripcion": "Fragmento de energía obtenido de criaturas.", "icono": "res://iconos/fragmento_esencia.png"}
}


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
