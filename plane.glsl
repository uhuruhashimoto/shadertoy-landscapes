#include "ray_trace/ray_trace.glsl"
#include "perlin.glsl"

#define GRID 1
#define DIFFUSE 2
#define RAY_MARCHING 3
#define SPHERE_TRACING 4
int cost_norm = 300;

struct settings
{
    int shade_mode;    // How the primiive is being visualized (GRID or COST)
    int marching_type; // Should we use RAY_MARCHING or SPHERE_TRACING?
};


settings setts = settings(GRID, RAY_MARCHING);

vec3 shade(vec3 p, int iters, settings setts)
{
    if (setts.shade_mode == GRID) {
        float res = 0.2;
        float one = abs(mod(p.x, res) - res / 2.0);
        float two = abs(mod(p.y, res) - res / 2.0);
        float three = abs(mod(p.z, res) - res / 2.0);
        float interp = min(one, min(two, three)) / res;

        return mix(vec3(0.2, 0.5, 1.0), vec3(0.1, 0.1, 0.1), smoothstep(0.0, 0.05, abs(interp)));
    }
    else if (setts.shade_mode == DIFFUSE) {
        vec3 light_pos = vec3(0.0, 5.0, 0.0);
        vec3 light_intensity = vec3(5.0);
        vec3 surface_color = vec3(0.5);
        vec3 l = normalize(light_pos - p);
        vec3 n = computeNormal(p);
        float distance = length(light_pos - p);
        float costheta = max(dot(n, l), 0.0);
        float attentuation = 1.0 / (distance * distance);
        surface_color = costheta * attentuation * light_intensity * surface_color;
        return surface_color;
    }
    else {
        return vec3(0.0);
    }
}

vec3 render(settings setts)
{
    // get the location on the screen in [-1,1] space after
    // accounting for the aspect ratio
    vec2 p = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;

    float aspect = iResolution.x / iResolution.y;
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
    uv.x *= aspect;

    vec3 eye = vec3(-3.0, 2.0 + 0.5, -3.0);
    vec3 dir = vec3(0.3, 0.0, 0.3) - eye;
    vec3 up = vec3(0, 1, 0);

    float focal_length = 1.;

    vec3 u, v, w;
    compute_camera_frame(dir, up, u, v, w);

    ray r = generate_ray_perspective(uv, eye, u, v, w, focal_length);

    int max_iter = 2000;
    float step_size = 0.005;

    vec3 col = vec3(0.0);

    vec3 hit_loc;
    int iters;
    bool hit;

    // evaluate the specified rendering method and shade appropriately
    if (ray_march(r, step_size, max_iter, hit_loc, iters)) {
        float f = snoise(hit_loc.xz);
        hit_loc.y += f;
        col = shade(hit_loc, iters, setts);
    }

    return pow(col, vec3(1.0 / 2.2));
}

void main()
{
    vec2 uvw = gl_FragCoord.xy / iResolution.xy;
    gl_FragColor = vec4(render(setts), 1.0);

}