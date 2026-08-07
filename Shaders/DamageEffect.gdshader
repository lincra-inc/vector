shader_type canvas_item;

uniform vec2 damage_dir = vec2(0.0, -1.0);

uniform float arrow_visibility = 1.0;

uniform float radius = 0.42;
uniform float arrow_size = 0.10;
uniform float arrow_width = 0.035;

uniform float hurt_amount = 0.0;


float triangle(vec2 p, vec2 a, vec2 b, vec2 c)
{
	vec2 v0 = c - a;
	vec2 v1 = b - a;
	vec2 v2 = p - a;

	float dot00 = dot(v0, v0);
	float dot01 = dot(v0, v1);
	float dot02 = dot(v0, v2);
	float dot11 = dot(v1, v1);
	float dot12 = dot(v1, v2);

	float inv = 1.0 / (dot00 * dot11 - dot01 * dot01);

	float u = (dot11 * dot02 - dot01 * dot12) * inv;
	float v = (dot00 * dot12 - dot01 * dot02) * inv;

	return step(0.0, u)
		* step(0.0, v)
		* step(u + v, 1.0);
}


void fragment()
{
	vec2 uv = SCREEN_UV;
	vec2 center = vec2(0.5);


	// ==========================
	// MANCHA DE DAÑO
	// ==========================

	float blood = hurt_amount * 0.35;


	// ==========================
	// FLECHA DIRECCIONAL
	// ==========================

	vec2 dir = normalize(damage_dir);

	vec2 edge = center + dir * radius;


	vec2 side = vec2(
		-dir.y,
		dir.x
	);


	vec2 tip = edge + dir * arrow_size;


	vec2 left =
		edge
		- dir * arrow_size * 0.35
		+ side * arrow_width;


	vec2 right =
		edge
		- dir * arrow_size * 0.35
		- side * arrow_width;


	float arrow = triangle(
		uv,
		tip,
		left,
		right
	);


	float arrow_alpha =
		arrow
		* hurt_amount
		* arrow_visibility;


	// glow alrededor de la flecha

	float glow = triangle(
		uv,
		tip + dir * 0.02,
		left - dir * 0.02,
		right - dir * 0.02
	);


	arrow_alpha +=
		glow
		* hurt_amount
		* 0.25
		* arrow_visibility;



	// ==========================
	// ALPHA FINAL
	// ==========================

	float final_alpha = max(
		blood,
		arrow_alpha
	);


	COLOR = vec4(
		1.0,
		0.05,
		0.02,
		final_alpha
	);
}