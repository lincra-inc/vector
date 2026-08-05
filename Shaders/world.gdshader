shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest_mipmap;

// Resolución (1 = sin pixelado)
uniform int resolution_scale : hint_range(1, 16) = 4;

// Bits por canal (8 = original)
uniform int color_depth : hint_range(1, 8) = 5;

// Activar dithering
uniform bool dithering = true;

const int bayer[16] = int[](
     0,  8,  2, 10,
    12,  4, 14,  6,
     3, 11,  1,  9,
    15,  7, 13,  5
);

void fragment()
{
    vec2 tex_size = vec2(textureSize(screen_texture, 0));

    // Pixelado
    vec2 pixel = floor(SCREEN_UV * tex_size / float(resolution_scale));
    vec2 uv = pixel * float(resolution_scale) / tex_size;

    vec3 color = texture(screen_texture, uv).rgb;

    // Dithering Bayer 4x4
    if (dithering)
    {
        ivec2 p = ivec2(mod(FRAGCOORD.xy, 4.0));
        float threshold = (float(bayer[p.y * 4 + p.x]) / 16.0 - 0.5) / 255.0;
        color += vec3(threshold);
    }

    // Reducir profundidad de color
    float levels = float((1 << color_depth) - 1);
    color = floor(clamp(color, 0.0, 1.0) * levels + 0.5) / levels;

    COLOR = vec4(color, 1.0);
}