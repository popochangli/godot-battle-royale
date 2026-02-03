shader_type canvas_item;

uniform vec2 zone_center;
uniform float zone_radius;
uniform vec4 danger_color : source_color = vec4(1.0, 0.1, 0.1, 0.25);
uniform vec2 camera_position;
uniform vec2 viewport_size;
uniform float camera_zoom;

void fragment() {
	vec2 world_pos = camera_position + (UV - 0.5) * viewport_size * camera_zoom;
	float dist = distance(world_pos, zone_center);

	if (dist > zone_radius) {
		COLOR = danger_color;
	} else {
		COLOR = vec4(0.0);
	}
}
