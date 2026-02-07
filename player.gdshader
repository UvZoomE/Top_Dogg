shader_type canvas_item;

// Settings you can change in the Inspector
uniform vec4 line_color : source_color = vec4(1.0, 0.84, 0.0, 1.0); // Gold
uniform float line_thickness : hint_range(0, 10) = 0.0; // Start at 0 (Off)

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    
    // Check the transparency of neighboring pixels (Up, Down, Left, Right)
    float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
    outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
    
    // Add diagonal checks for smoother corners
    outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
    outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
    
    // Cap the outline opacity at 1.0
    outline = min(outline, 1.0);
    
    // Get the sprite's original color
    vec4 color = texture(TEXTURE, UV);
    
    // Logic: If the pixel is transparent but neighbors are not, draw the gold line.
    // mix(Color A, Color B, Weight)
    COLOR = mix(color, line_color, outline - color.a);
}
