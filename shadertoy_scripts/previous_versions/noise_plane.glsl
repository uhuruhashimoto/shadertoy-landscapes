// Credit to Inigo Quilez - see top-level README for full credits.
// See final.glsl for proper credit for all functions
#define EPSILON 1e-3
#define MAX_FLOAT 3.402823466e+38
#define MAX_RECURSION 50
#define GRID 1
#define DIFFUSE 2
struct settings
{
    int shade_mode;    // How the primiive is being visualized (GRID or COST)
};

struct ray
{
    vec3 origin;
    vec3 direction;
};

struct camera {
    vec3 u;
    vec3 v;
    vec3 w;
};

// ---------------------- RANDOMNESS ------------------------ //
vec2 hash( vec2 p ) // replace this by something better
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec2 p )
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
	vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}

// ---------------------- CAMERA ------------------------ //
ray cameraGenerateRay(vec2 uv, vec3 eye, camera cam, float focal_length)
{
    vec3 dir = -focal_length * cam.w + uv.x * cam.u + uv.y * cam.v;
    return ray(eye, normalize(dir));
}

void cameraCoords(vec3 dir, vec3 up, inout camera cam)
{
    cam.w = -normalize(dir);
    cam.u = normalize(cross(up, cam.w));
    cam.v = cross(cam.w, cam.u);
}

// ---------------------- LANDSCAPE INTERACTION ------------------------ //
vec3 skyColor() {
    return vec3(0.0, 0.0, 0.3);
}

// fractional brownian motion from https://iquilezles.org/articles/fbm/
float fbm( in vec2 p)
{
    const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);
    float f = 0.0;
    f += 0.5000*noise(p); p = m2*p*2.02;
    f += 0.2500*noise(p); p = m2*p*2.03;
    //f += 0.1250*noise(p); p = m2*p*2.01;
    //f += 0.0625*noise(p);
    return f/0.9375;
}


// plane height
float f(float x, float z) {
    return fbm(vec2(x,z));
}

// The normal can be computed as usual with the central differences method:
vec3 getNormal( const vec3 p )
{
    return normalize( vec3( f(p.x-EPSILON,p.z) - f(p.x+EPSILON,p.z),
                            2.0f*EPSILON,
                            f(p.x,p.z-EPSILON) - f(p.x,p.z+EPSILON) ) );
}

vec3 getShading(vec3 p, vec3 n)
{
    // sun
    vec3 s = vec3(1, 0.5, 0);
    return vec3(dot(n, s));
}

vec3 getMaterial(vec3 p, vec3 n)
{
    return vec3(1.0, 0.5, 0.2);
}

vec3 applyFog(vec3 p, float t)
{
    // no fog yet
    return p;
}

vec3 terrainColor( const ray r, float t )
{
    vec3 p = r.origin + r.direction * t;
    vec3 n = getNormal( p );
    vec3 s = getShading( p, n );
    vec3 m = getMaterial( p, n );
    return applyFog( m * s, t );
}

// ---------------------- RAY TRACE ------------------------ //
bool castRay(ray r, inout float resT)
{
    float dt = 0.01f;
    const float mint = 0.001f;
    const float maxt = 10.0f;
    float lh = 0.0f;
    float ly = 0.0f;
    for( float t = mint; t < maxt; t += dt )
    {
        vec3  p = r.origin + r.direction*t;
        float h = f( p.x, p.z );
        if( p.y < h )
        {
            // interpolate the intersection distance
            resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);
            return true;
        }
        // allow the error to be proportinal to the distance
        dt = 0.01f*t;
        lh = h;
        ly = p.y;
    }
    return false;
}

vec3 rayColor(ray r)
{
    float t;
    if (castRay(r, t)) {
        return terrainColor(r, t);
    }
    return skyColor();
}

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
        vec3 n = getNormal(p);
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
    }

    return pow(col, vec3(1.0 / 2.2));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(render(), 1.0);

}