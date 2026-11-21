extends Node2D
class_name VisualRodaje

const PIEZA = preload("res://Scripts/Tanques/pieza_rodaje.gdshader")
var distancia := 0.0
var anterior := 0.0
var detenido := false
var ruedas: Array[Sprite2D] = []
var radios: Array[float] = []
var centros: Array[Vector2] = []
var apoyos: Array[float] = []
var apoyos_previos: Array[float] = []
var ruta := PackedVector2Array()
var cadena: MultiMeshInstance2D
var paso := 1.0
var escala_mundo := Vector2.ONE
var _suelo: Node
var _espejo := 1.0
var _estaba_en_suelo := true
var _cubierta: Sprite2D
var _soportes: Array[Sprite2D] = []

func configurar(textura: Texture2D, datos: Dictionary) -> void:
	escala_mundo = global_transform.get_scale().abs()
	_espejo = -1.0 if global_transform.x.x < 0 else 1.0
	var fuente := textura.get_image()
	# Las capas son vistas de la fuente en memoria: los PNG originales permanecen intactos.
	var fondo := Polygon2D.new()
	fondo.polygon = _suavizar(PackedVector2Array(datos["ruta"]))
	fondo.color = Color("#24251f")
	add_child(fondo)
	var cuerpo := Sprite2D.new()
	cuerpo.texture = textura
	cuerpo.centered = false
	var material := ShaderMaterial.new()
	material.shader = PIEZA
	material.set_shader_parameter("corte", datos["corte"])
	material.set_shader_parameter("alto", fuente.get_height())
	cuerpo.material = material
	cuerpo.z_index = 2
	add_child(cuerpo)
	var brazos: Array = datos.get("brazos", [])
	if not brazos.is_empty():
		var cubierta := Sprite2D.new()
		cubierta.texture = textura
		cubierta.centered = false
		var material_brazos := ShaderMaterial.new()
		material_brazos.shader = PIEZA
		material_brazos.set_shader_parameter("suspension", true)
		material_brazos.set_shader_parameter("tamano", Vector2(fuente.get_size()))
		for i in brazos.size():
			material_brazos.set_shader_parameter(["brazo_a","brazo_b","brazo_c"][i], brazos[i])
		cubierta.material = material_brazos
		cubierta.z_index = 4
		add_child(cubierta)
		_cubierta = cubierta
	for apoyo: Vector2 in datos.get("soportes", []):
		# Dos recortes conservan la caja y el brazo vertical, sin incluir las ruedas.
		for recorte in [Rect2(apoyo, Vector2(88,40)),Rect2(apoyo+Vector2(12,32),Vector2(29,22))]:
			var soporte := Sprite2D.new()
			soporte.texture = ImageTexture.create_from_image(fuente.get_region(Rect2i(recorte)))
			soporte.centered = false
			soporte.position = recorte.position
			soporte.set_meta("origen", soporte.position)
			soporte.z_index = 4
			add_child(soporte)
			_soportes.append(soporte)
	for indice in datos["ruedas"].size():
		var rueda: Vector3 = datos["ruedas"][indice]
		var origen: Vector3 = datos.get("fuentes", {}).get(indice, rueda)
		var sprite := Sprite2D.new()
		var rect := Rect2i(roundi(origen.x - origen.z), roundi(origen.y - origen.z), roundi(origen.z * 2), roundi(origen.z * 2))
		sprite.texture = ImageTexture.create_from_image(fuente.get_region(rect))
		var mascara := ShaderMaterial.new()
		mascara.shader = PIEZA
		mascara.set_shader_parameter("disco", true)
		mascara.set_shader_parameter("reconstruir_mitad", indice in datos.get("reconstruir", []))
		sprite.material = mascara
		sprite.position = Vector2(rueda.x, rueda.y)
		add_child(sprite)
		ruedas.append(sprite)
		centros.append(sprite.position)
		radios.append(rueda.z * escala_mundo.y)
		apoyos.append(0.0)
		apoyos_previos.append(0.0)
	ruta = _suavizar(PackedVector2Array(datos["ruta"]))
	paso = datos["paso"] * escala_mundo.x
	cadena = MultiMeshInstance2D.new()
	var malla := QuadMesh.new()
	var recorte: Rect2 = datos["eslabon"]
	malla.size = Vector2(datos["paso"] * 1.08, recorte.size.y)
	cadena.texture = ImageTexture.create_from_image(fuente.get_region(Rect2i(recorte)))
	cadena.multimesh = MultiMesh.new()
	cadena.multimesh.transform_format = MultiMesh.TRANSFORM_2D
	cadena.multimesh.mesh = malla
	cadena.multimesh.instance_count = maxi(12, roundi(_longitud(ruta) / paso))
	cadena.z_index = 1
	add_child(cadena)
	_suelo = get_tree().get_first_node_in_group("terreno_destructible")
	_dibujar(1.0)

func _longitud(puntos: PackedVector2Array) -> float:
	var total := 0.0
	for i in puntos.size():
		total += ((puntos[(i+1)%puntos.size()] - puntos[i]) * escala_mundo).length()
	return total

func _suavizar(vertices: PackedVector2Array) -> PackedVector2Array:
	# Curvas cuadráticas dentro del contorno evitan cambios bruscos entre eslabones.
	var puntos := PackedVector2Array()
	for i in vertices.size():
		var inicio := vertices[i].lerp(vertices[(i-1+vertices.size())%vertices.size()],0.22)
		var fin := vertices[i].lerp(vertices[(i+1)%vertices.size()],0.22)
		for j in 8:
			var t := float(j)/8.0
			puntos.append(inicio.lerp(vertices[i],t).lerp(vertices[i].lerp(fin,t),t))
	return puntos

func actualizar(delta: float, desplazamiento: Vector2, en_suelo: bool, normal: Vector2) -> void:
	if detenido:
		return
	if absf(desplazamiento.x) >= 20.0:
		reiniciar()
		return
	anterior = distancia
	var tangente := Vector2(-normal.y, normal.x).normalized()
	if tangente.x < 0:
		tangente = -tangente
	# Reubicaciones y asentamiento vertical no equivalen a rodar sobre el suelo.
	if en_suelo and _estaba_en_suelo and absf(desplazamiento.x) > 0.0001 and desplazamiento.length() < 20.0:
		distancia += desplazamiento.dot(tangente) * _espejo
	_estaba_en_suelo = en_suelo
	for i in ruedas.size():
		apoyos_previos[i] = apoyos[i]
		var objetivo := 0.0
		if en_suelo and is_instance_valid(_suelo):
			var pie := to_global(centros[i] + Vector2(0, radios[i] / escala_mundo.y))
			objetivo = clampf(_suelo.obtener_altura(pie.x) - pie.y, -2.0, 2.0)
		var respuesta := 0.12 if en_suelo and desplazamiento.length() > 0.001 else 0.25
		apoyos[i] = lerpf(apoyos[i], objetivo, 1.0 - exp(-3.0 * delta / respuesta))

func _process(_delta: float) -> void:
	if not detenido:
		_dibujar(clampf(Engine.get_physics_interpolation_fraction(), 0.0, 1.0))

func _dibujar(fraccion: float) -> void:
	var fase := lerpf(anterior, distancia, fraccion)
	for i in ruedas.size():
		ruedas[i].rotation = fposmod(fase / radios[i], TAU)
		ruedas[i].position.y = centros[i].y + lerpf(apoyos_previos[i], apoyos[i], fraccion) / escala_mundo.y
	if _cubierta != null:
		var promedio := 0.0
		for i in apoyos.size():
			promedio += lerpf(apoyos_previos[i], apoyos[i], fraccion)
		_cubierta.position.y = promedio / maxf(1.0, apoyos.size()) / escala_mundo.y
	var puntos := ruta.duplicate()
	for soporte in _soportes:
		var origen: Vector2 = soporte.get_meta("origen")
		soporte.position.y = origen.y + _altura_apoyo(origen.x, fraccion) / escala_mundo.y
	for i in puntos.size():
		puntos[i].y += _altura_apoyo(puntos[i].x, fraccion) / escala_mundo.y
	var longitud := _longitud(puntos)
	for i in cadena.multimesh.instance_count:
		var recorrido := fposmod(float(i) * longitud / cadena.multimesh.instance_count + fase, longitud)
		for j in puntos.size():
			var inicio := puntos[j]
			var fin := puntos[(j + 1) % puntos.size()]
			var tramo := ((fin - inicio) * escala_mundo).length()
			if recorrido <= tramo:
				var posicion := inicio.lerp(fin, recorrido / tramo)
				cadena.multimesh.set_instance_transform_2d(i, Transform2D((fin - inicio).angle(), posicion))
				break
			recorrido -= tramo

func _altura_apoyo(x: float, fraccion: float) -> float:
	# Interpolación espacial: evita escalones al pasar entre apoyos vecinos.
	var izquierda := -1
	var derecha := -1
	for i in centros.size():
		if centros[i].x <= x and (izquierda < 0 or centros[i].x > centros[izquierda].x):
			izquierda = i
		if centros[i].x >= x and (derecha < 0 or centros[i].x < centros[derecha].x):
			derecha = i
	if izquierda < 0:
		izquierda = derecha
	if derecha < 0:
		derecha = izquierda
	var a := lerpf(apoyos_previos[izquierda], apoyos[izquierda], fraccion)
	var b := lerpf(apoyos_previos[derecha], apoyos[derecha], fraccion)
	if izquierda == derecha:
		return a
	return lerpf(a, b, smoothstep(centros[izquierda].x, centros[derecha].x, x))

func detener() -> void:
	_dibujar(1.0)
	detenido = true
	set_process(false)

func reiniciar() -> void:
	distancia = 0.0
	anterior = 0.0
	apoyos.fill(0.0)
	apoyos_previos.fill(0.0)
	detenido = false
	_estaba_en_suelo = true
	set_process(true)
	_dibujar(1.0)
