shader_type spatial;

render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : hint_normal;
uniform sampler2D orm_texture;

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float metallic = 0.0;
uniform float roughness = 1.0;

uniform float max_distance = 30.0;
uniform float deformation_strength = 1.0;
uniform float random_strength = 0.3;

float hash(vec3 p)
{
    return fract(sin(dot(p, vec3(12.9898,78.233,45.164))) * 43758.5453);
}

void vertex()
{
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
    vec3 cam_pos = (INV_VIEW_MATRIX * vec4(0.0,0.0,0.0,1.0)).xyz;

    float dist = distance(world_pos, cam_pos);
    float factor = smoothstep(0.0, max_distance, dist);

    float rnd = mix(0.7,1.3,hash(world_pos));

    vec3 dir = normalize(VERTEX);

    vec3 rand_dir = normalize(vec3(
        hash(world_pos+vec3(1,0,0)),
        hash(world_pos+vec3(0,1,0)),
        hash(world_pos+vec3(0,0,1))
    ) * 2.0 - 1.0);

    dir = normalize(mix(dir, rand_dir, random_strength));

    VERTEX += dir * deformation_strength * factor * rnd;
}

void fragment()
{
    vec4 alb = texture(albedo_texture, UV) * albedo_color;

    ALBEDO = alb.rgb;
    ALPHA = alb.a;

    vec3 orm = texture(orm_texture, UV).rgb;

    AO = orm.r;
    ROUGHNESS = orm.g * roughness;
    METALLIC = orm.b * metallic;

    NORMAL_MAP = texture(normal_texture, UV).rgb;
}