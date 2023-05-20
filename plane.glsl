#include "ray_trace/ray_trace.glsl"

#define GRID 1
#define COST 2
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
    // we will give them the grid shade mode
    if (setts.shade_mode == GRID)
    {
        float res = 0.2;
        float one = abs(mod(p.x, res) - res / 2.0);
        float two = abs(mod(p.y, res) - res / 2.0);
        float three = abs(mod(p.z, res) - res / 2.0);
        float interp = min(one, min(two, three)) / res;

        return mix(vec3(0.2, 0.5, 1.0), vec3(0.1, 0.1, 0.1), smoothstep(0.0, 0.05, abs(interp)));
    }
    else if (setts.shade_mode == COST)
    {
        return vec3(float(iters) / float(cost_norm));
    }
    else
    {
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

    float focal_length = 4.;

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
        col = shade(hit_loc, iters, setts);
    }

    return pow(col, vec3(1.0 / 2.2));
}

void main()
{
    vec2 uvw = gl_FragCoord.xy / iResolution.xy;
    gl_FragColor = vec4(render(setts), 1.0);

}