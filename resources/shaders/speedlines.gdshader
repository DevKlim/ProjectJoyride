shader_type canvas_item;

uniform float line_color_r = 1.0;
uniform float line_color_g = 1.0;
uniform float line_color_b = 1.0;
uniform float line_count = 50.0;
uniform float speed = 10.0;
uniform float intensity = 0.0; // Controlled by script

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    vec2 center = vec2(0.5, 0.5);
    vec2 uv = UV - center;
    float angle = atan(uv.y, uv.x);
    float radius = length(uv);
    
    // Create polar noise coordinates
    float noise = rand(vec2(floor(angle * line_count), floor(TIME * speed)));
    
    // Draw lines only where speed is active, radiating from center
    float line = step(0.8, noise) * smoothstep(0.2, 0.5, radius);
    
    COLOR = vec4(line_color_r, line_color_g, line_color_b, line * intensity * 0.5);
}
