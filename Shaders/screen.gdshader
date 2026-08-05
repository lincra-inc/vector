shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest_mipmap;

uniform int resolution_scale = 3;
uniform int color_depth = 5;
uniform bool dithering = true;

const int bayer[16] = int[](
     0, 8, 2,10,
    12,4,14,6,
     3,11,1,9,
    15,7,13,5
);

void fragment()
{
    vec2 size = vec2(textureSize(screen_texture,0));

    vec2 uv =
        floor(SCREEN_UV * size / float(resolution_scale))
        * float(resolution_scale)
        / size;

    vec3 color = texture(screen_texture, uv).rgb;

    if (dithering)
    {
        ivec2 p = ivec2(mod(FRAGCOORD.xy,4.0));
        float t = (float(bayer[p.y*4+p.x])/16.0 - 0.5)/255.0;
        color += vec3(t);
    }

    float levels = float((1<<color_depth)-1);
    color = floor(clamp(color,0.0,1.0)*levels+0.5)/levels;

    COLOR = vec4(color,1.0);
}