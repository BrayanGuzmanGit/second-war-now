extends Node

const APARIENCIAS = preload("res://Modelos/CatalogoApariencias.gd")
const ECONOMIA = preload("res://Modelos/ReglasEconomia.gd")

func obtener_catalogo() -> Array[Dictionary]:
	var catalogo: Array[Dictionary] = []
	for id in ECONOMIA.PRECIOS:
		var item: Dictionary = APARIENCIAS.obtener(id).duplicate(true)
		item["precio"] = ECONOMIA.PRECIOS[id]
		item["comprado"] = GestorGuardado.progreso["cosmeticos_comprados"].has(id)
		item["equipado"] = GestorGuardado.progreso["cosmetico_equipado"] == id
		catalogo.append(item)
	return catalogo

func comprar_cosmetico(id: String, operacion: String) -> Dictionary:
	return GestorGuardado.comprar_cosmetico(id, operacion)

func comprar_paquete(id: String, operacion: String) -> Dictionary:
	return GestorGuardado.comprar_paquete(id, operacion)

func obtener_paquetes() -> Array[Dictionary]:
	return ECONOMIA.PAQUETES.duplicate(true)

func procesar_compra_simulada(id: String) -> bool:
	return GestorGuardado.registrar_cosmetico_comprado(id)

func equipar_cosmetico(id: String) -> bool:
	return GestorGuardado.equipar_cosmetico(id)
