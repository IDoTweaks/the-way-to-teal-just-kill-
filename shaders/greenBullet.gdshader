shader_type spatial;
render_mode unshaded, blend_add, cull_disabled;

group_uniforms Color;
uniform vec3 primary_color : source_color = vec3(1.0);
uniform vec3 secondary_color : source_color = vec3(1.0, 0.8, 0.4);
uniform float emission = 2.0;
uniform float emission_mult = 1.0;

group_uniforms Shape;
uniform bool alpha_as_factor = false;
uniform float grow_factor : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D flare_texture;
uniform float streaks_amount = 4.0;
uniform float variance1_amplitude = 12.0;
uniform float variance2_amplitude = 5.0;

group_uniforms Alpha;
uniform float edge_hardness : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float edge_position : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform bool proximity_fade = false;
uniform float proximity_fade_distance = 1.0;

group_uniforms Billboard;
uniform bool billboard = false;

varying flat int id;

float overlay(float base, float blend){
	float limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}

void vertex() {
	id = INSTANCE_ID;
	if(billboard){
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
				MAIN_CAM_INV_VIEW_MATRIX[0],
				MAIN_CAM_INV_VIEW_MATRIX[1],
				MAIN_CAM_INV_VIEW_MATRIX[2],
				MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	float flare = texture(flare_texture, UV).r;
	flare = pow(flare, 8.0) * 0.8;
	
	vec2 centered_uv = UV - 0.5;
	float angle = (atan(centered_uv.x, centered_uv.y));
	
	float id_offset = float(id);
	
	float streaks = pow(cos((angle + id_offset) * streaks_amount) * 0.5 + 0.5, 16.0);
	float variance1 = sin((angle + id_offset) * variance1_amplitude) * 0.5 + 0.5;
	streaks *= variance1;
	
	float value = overlay(flare, streaks);
	value = max(value, flare*0.5);
	
	float variance2 = sin((angle + id_offset) * variance2_amplitude + id_offset) * 0.5 + 0.5;
	value *= (0.5 + variance2 * 0.5);
	
	float l_edge = mix(0.0, edge_position, edge_hardness);
	float r_edge = mix(1.0, edge_position + 0.01, edge_hardness);
	value = smoothstep(l_edge,r_edge,value);
	
	ALBEDO = (mix(secondary_color, primary_color, value) * COLOR.rgb) * emission * COLOR.a * emission_mult;
	
	ALPHA = value;
}
