shader_type canvas_item;

uniform vec4 flat_color : source_color;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = vec4(flat_color.rgb, tex_color.a * flat_color.a);
}
