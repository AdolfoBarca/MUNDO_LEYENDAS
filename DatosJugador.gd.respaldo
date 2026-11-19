extends Node

signal inventario_actualizado

# DATOS DEL JUGADOR
var nombre: String = ""
var pais: String = ""
var region: String = ""
var afinidad: String = ""

# APARIENCIA
var color_piel: Color = Color("#C98F65")
var color_camisa: Color = Color("#244A73")
var color_pantalon: Color = Color("#2F3540")

# CATÁLOGO DE OBJETOS
var catalogo_objetos: Dictionary = {
    "fragmento_esencia": {
        "nombre": "Fragmento de esencia", "tipo": "Material", "rareza": "Común",
        "descripcion": "Fragmento de energía obtenido de criaturas.",
        "icono": "res://iconos/fragmento_esencia.png"
    },
    "ceniza_encantada": {
        "nombre": "Ceniza encantada", "tipo": "Material", "rareza": "Raro",
        "descripcion": "Ceniza impregnada de magia del Cipitío.",
        "icono": "res://iconos/ceniza_encantada.png"
    },
    "sombrero_deteriorado": {
        "nombre": "Sombrero deteriorado", "tipo": "Material", "rareza": "Raro",
        "descripcion": "Un sombrero antiguo utilizado por los mini Cipitíos.",
        "icono": "res://iconos/sombrero_deteriorado.png"
    },
    "sombrero_cipitio": {
        "nombre": "Sombrero legendario del Cipitío", "tipo": "Equipamiento", "rareza": "Legendario",
        "descripcion": "Un sombrero que contiene poderes sobrenaturales.", "icono": ""
    },
    "corazon_cipitio": {
        "nombre": "Corazón del Cipitío", "tipo": "Material", "rareza": "Legendario",
        "descripcion": "Corazón mágico obtenido al derrotar al Cipitío Legendario.", "icono": ""
    },
    "ceniza_ancestral": {
        "nombre": "Ceniza ancestral", "tipo": "Material", "rareza": "Legendario",
        "descripcion": "Ceniza sobrenatural concentrada del Cipitío Legendario.", "icono": ""
    }
}

# INVENTARIO
var fragmentos_esencia: int = 0
var inventario: Dictionary = {
    "fragmento_esencia": {
        "nombre": "Fragmento de esencia", "tipo": "Material", "cantidad": 0,
        "rareza": "Común", "descripcion": "Fragmento de energía obtenido de criaturas.",
        "icono": "res://iconos/fragmento_esencia.png"
    }
}

# REGIÓN Y AFINIDAD
func asignar_region_y_afinidad() -> void:
    var centroamerica: Array = [
        "El Salvador", "Guatemala", "Honduras", "Nicaragua",
        "Costa Rica", "Panamá", "Belice"
    ]
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

# AGREGAR OBJETO
func agregar_objeto(
    id_objeto: String,
    nombre_objeto: String,
    tipo_objeto: String,
    cantidad: int = 1,
    rareza: String = "Común"
) -> void:
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

# AGREGAR OBJETO DESDE EL CATÁLOGO
func agregar_objeto_catalogo(id_objeto: String, cantidad: int = 1) -> void:
    if not catalogo_objetos.has(id_objeto):
        push_warning("Objeto desconocido: " + id_objeto)
        return
    var datos: Dictionary = catalogo_objetos[id_objeto]
    agregar_objeto(
        id_objeto,
        str(datos.get("nombre", "Objeto")),
        str(datos.get("tipo", "Material")),
        cantidad,
        str(datos.get("rareza", "Común"))
    )

# AGREGAR FRAGMENTOS
func agregar_fragmentos_esencia(cantidad: int) -> void:
    agregar_objeto_catalogo("fragmento_esencia", cantidad)

# CONSULTAR OBJETOS
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

# CONSUMIR OBJETOS
func consumir_objeto(id_objeto: String, cantidad: int = 1) -> bool:
    if cantidad <= 0:
        return false
    if not tiene_objeto(id_objeto, cantidad):
        return false
    inventario[id_objeto]["cantidad"] -= cantidad
    if id_objeto == "fragmento_esencia":
        fragmentos_esencia = obtener_cantidad_objeto("fragmento_esencia")
    inventario_actualizado.emit()
    return true
