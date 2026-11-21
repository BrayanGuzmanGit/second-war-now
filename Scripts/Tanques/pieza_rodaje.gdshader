shader_type canvas_item;
uniform bool disco = false;
uniform bool reconstruir_mitad = false;
uniform float corte = 0.0;
uniform float alto = 1.0;
uniform vec2 tamano = vec2(1.0);
uniform bool suspension = false;
uniform vec4 brazo_a = vec4(0.0);
uniform vec4 brazo_b = vec4(0.0);
uniform vec4 brazo_c = vec4(0.0);
float brazo(vec2 p, vec4 b) {
	if (b.w <= 0.0) { return 0.0; }
	vec2 q = p - b.xy;
	float caja = step(abs(q.x), b.z * 0.57) * step(0.0,q.y) * step(q.y,b.w * 0.75);
	vec2 a = vec2(0.0,b.w * 0.64);
	vec2 v = vec2(b.z,b.w * 0.36);
	vec2 d = vec2(abs(q.x),q.y) - a;
	float t = clamp(dot(d,v) / dot(v,v),0.0,1.0);
	return max(caja,1.0-smoothstep(b.w*0.08,b.w*0.13,length(d-v*t)));
}
varying vec4 tinte;
void vertex() { tinte = COLOR; }
void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (suspension) {
		vec2 p = UV * tamano;
		color.a *= max(brazo(p,brazo_a),max(brazo(p,brazo_b),brazo(p,brazo_c)));
	} else if (disco) {
		// Reconstruye la parte tapada por el brazo con la mitad inferior de la rueda.
		if (reconstruir_mitad) {
			color = texture(TEXTURE, vec2(UV.x, 0.5 + abs(UV.y - 0.5)));
		}
		float r = length(UV * 2.0 - 1.0);
		color.a *= 1.0 - smoothstep(0.94, 1.0, r);
	} else {
		color.a *= 1.0 - smoothstep(corte - 1.0, corte + 1.0, UV.y * alto);
	}
	COLOR = tinte * color;
}
