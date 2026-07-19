shader_type spatial;
render_mode shadows_disabled;

uniform vec4 dark_lava_color : source_color;
uniform vec4 light_lava_color : source_color;
uniform float speed : hint_range(0.0, 5.0);
uniform float scale : hint_range(0.1, 40.0) = 10;
uniform float sharpness : hint_range(1.0, 100.0); 
uniform float emission_intensity : hint_range(0.0, 10.0);
uniform int cel_bands : hint_range(2, 8) = 3;
uniform vec4 edge_color : source_color = vec4(0.03, 0.13, 0.15, 1.0);
uniform float edge_width : hint_range(0.0, 0.4) = 0.12;

vec2 random2D(vec2 p) {
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

float voronoiIQ(vec2 _pos) {
    float _time = TIME * speed;
    _pos.y += _time;
    _pos.x += sin(_time);

    vec2 p = floor(_pos);
    vec2 f = fract(_pos);
    float res = 0.0;
    
    float sharp = clamp(sharpness, 1.0, 50.0);
    
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 b = vec2(float(i), float(j));
            vec2 pnt = random2D(p + b);
            pnt = 0.5 + 0.5 * sin(_time + 6.2831 * pnt);
            vec2 r = vec2(b) - f + pnt;
            float d = dot(r, r);
            res += exp(-sharp * d);
        }
    }
    
    res = max(res, 1e-6);
    
    float result = -(1.0 / sharp) * log(res);
    return clamp(result, 0.0, 1.0);
}

void fragment() {
    vec2 uv = UV * scale;
    float voronoi_value = voronoiIQ(uv);

    float v = floor(voronoi_value * float(cel_bands)) / float(cel_bands - 1);
    v = clamp(v, 0.0, 1.0);
    vec4 final_color = mix(dark_lava_color, light_lava_color, v);
    float cell_edge = smoothstep(edge_width, 0.0, voronoi_value);
    final_color.rgb = mix(final_color.rgb, edge_color.rgb, cell_edge);
    ALBEDO = final_color.rgb;
	EMISSION = final_color.rgb * emission_intensity * (1.0 - cell_edge);
}
