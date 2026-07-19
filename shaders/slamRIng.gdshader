shader_type spatial;
render_mode cull_front, unshaded, world_vertex_coords;

uniform float outline_thickness = 0.03;
uniform float speed = 2.0;
uniform float noise_scale = 4.0;
uniform float alpha = 1.0;
uniform int cel_bands : hint_range(2, 6) = 3;
uniform sampler2D fire_noise : source_color, repeat_enable;
uniform sampler2D color_ramp : source_color, repeat_enable, filter_linear_mipmap;

float animated_noise(vec2 uv) {
    float time_factor = TIME * speed;
    return texture(fire_noise, uv * noise_scale + vec2(time_factor * 0.3, time_factor * 0.7)).r;
}

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 noise_uv = world_pos.xz * 0.5 + vec2(TIME * speed * 0.2);
    float displacement = animated_noise(noise_uv) * 0.1;
    
    VERTEX += NORMAL * (outline_thickness + displacement);
}

void fragment() {
    vec3 world_pos = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    vec2 fire_uv = world_pos.xz * 0.3 + vec2(TIME * speed, 0.0);
    
    float noise1 = animated_noise(fire_uv);
    float noise2 = animated_noise(fire_uv * 2.0 + vec2(0.2));
    float noise3 = animated_noise(fire_uv * 0.5 - vec2(TIME * 0.5));
    
    float combined_noise = clamp((noise1 * 0.6 + noise2 * 0.3 + noise3 * 0.1), 0.0, 1.0);
    
    float ramp_pos = smoothstep(0.2, 0.8, combined_noise);
    ramp_pos = floor(ramp_pos * float(cel_bands)) / float(cel_bands - 1);
    ramp_pos = clamp(ramp_pos, 0.0, 1.0);
    vec3 fire_color = texture(color_ramp, vec2(ramp_pos, 0.0)).rgb;
    
    float flame_mask = step(0.5, combined_noise);
    fire_color *= 1.0 + flame_mask * 2.0;
    
    ALPHA = step(0.25, combined_noise) * alpha;
    
    EMISSION = fire_color * (1.0 + sin(TIME * 10.0) * 0.3);
    ALBEDO = fire_color;
}