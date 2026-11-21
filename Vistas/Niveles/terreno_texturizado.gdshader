shader_type canvas_item;
render_mode unshaded;

uniform sampler2D interior : source_color, filter_linear;
uniform sampler2D superficie : source_color, filter_linear;
uniform sampler2D bordes : filter_linear;
uniform sampler2D perfiles : filter_linear;
uniform vec4 region_interior = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool pared_interior = false;
uniform float alto_superficie = 704.0;
uniform float escala_cap = 3.2;
uniform float profundidad_cap = 26.0;
uniform vec4 tinte : source_color = vec4(1.0);
varying vec2 punto;

void vertex() {
	punto = VERTEX;
}

void fragment() {
	float perfil_u = (clamp(punto.x / 4.0, 0.0, 450.0) + 0.5) / 451.0;
	vec2 alturas = texture(perfiles, vec2(perfil_u, 0.5)).rg * 1100.0;
	float profundidad = punto.y - alturas.r;
	// Repetición reflejada: une los bordes de los JPEG sin añadir juntas rectangulares.
	vec2 uv_suelo = 1.0 - abs(mod(punto / 440.0, 2.0) - 1.0);
	vec3 suelo = texture(interior, region_interior.xy + uv_suelo * region_interior.zw).rgb;
	if (pared_interior) {
		float hundimiento = max(alturas.r - alturas.g, 1.0);
		float avance = clamp((punto.y - alturas.g) / hundimiento, 0.0, 1.0);
		COLOR = vec4(suelo * mix(0.80, 0.54, avance) * tinte.rgb, 1.0);
	} else {
		float u = clamp(punto.x * escala_cap / 5856.0, 0.0, 0.9999);
		float borde = texture(bordes, vec2(u, 0.5)).r;
		vec3 capa = texture(superficie, vec2(u, borde + max(profundidad, 0.0) * escala_cap / alto_superficie)).rgb;
		float mezcla = 1.0 - smoothstep(profundidad_cap * 0.5, profundidad_cap, profundidad);
		// La hierba/asfalto desaparece con el impacto; no vuelve a crecer en el fondo del cráter.
		mezcla *= 1.0 - smoothstep(1.0, 6.0, max(alturas.r - alturas.g, 0.0));
		vec3 color = mix(suelo, capa, mezcla);
		// Se muestrea debajo de la silueta medida: el damero opaco nunca se dibuja.
		float sombra = mix(0.94, 1.0, smoothstep(0.0, 10.0, profundidad));
		COLOR = vec4(color * sombra * tinte.rgb, 1.0);
	}
}
