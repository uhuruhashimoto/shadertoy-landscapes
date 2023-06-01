#iKeyboard
#include "ray_trace.glsl"
#include "sdfs/sdf.glsl"

#define GRID 1
#define DIFFUSE 2
struct settings
{
    int shade_mode;    // How the primitive is being visualized (GRID or COST)
};


vec3 shade(vec3 p, settings setts)
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

vec3 render()
{
    // get the location on the screen in [-1,1] space after
    // accounting for the aspect ratio
    vec2 p = (2.0 * gl_FragCoord.xy - iResolution.xy) / iResolution.y;

    // Viewport
    float aspect = iResolution.x / iResolution.y;
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
    uv.x *= aspect;

    // Camera
    vec3 eye = vec3(-3.0, 2.6, -3.0);
    vec3 dir = vec3(0.3, 0.0, 0.3) - eye;
    vec3 up = vec3(0, 1, 0);
    float focal_length = .5;
    camera cam;
    cameraCoords(dir, up, cam);
    ray r = cameraGenerateRay(uv, eye, cam, focal_length);

    // Ray trace
    vec3 col = skyColor();
    vec3 hit_loc = vec3(0.0);
    float t;

    if (castRay(r, t)) {
        col = terrainColor(r, t);
        if (isKeyToggled(Key_L)) {
            col = shade(vec3(r.origin + r.direction * t), settings(GRID));
        }
    }

    return pow(col, vec3(1.0 / 2.2));
}

void main()
{
    gl_FragColor = vec4(render(), 1.0);

}