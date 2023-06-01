// code adapted from https://iquilezles.org/articles/terrainmarching/

#include "random/random.glsl"
#include "common.glsl"
#include "random/perlin.glsl"

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
    return vec3(0.0, 0.0, 0.0);
}

// fractional brownian motion from https://iquilezles.org/articles/fbm/
float fbm( in vec2 x, in float H )
{
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    int numOctaves = 1;
    for( int i=0; i<numOctaves; i++ )
    {
        t += a*snoise(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;
}


// plane height
float f(float x, float z) {
    return fbm(vec2(x,z), 1.);
    //return snoise(vec2(x,z));
    return 0.5 * sin(x)*sin(z);
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

// --------------------- DRIVER -------------------------- //
// void main()
// {
//     // Aliasing
//     int num_samples = 1;
//     vec3 result = vec3(0.);

//     // scattering
//     init_rand(gl_FragCoord.xy, float(iTime));

//     // Image
//     vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
//     float focal_length = 4.;

//     // Camera
//     camera cam;
//     vec3 eye = vec3(-30, 2, 1);
//     vec3 up = vec3(0, 1, 0);
//     vec3 dir = vec3(0.0, 0.0, -1.0) - eye;
//     cameraCoords(dir, up, cam);

//     for (int i=0; i<num_samples; i++) {
//         float randseed = rand1(g_seed);
//         vec2 randuv = vec2(uv.x + randseed / iResolution.x, uv.y + randseed / iResolution.y);
//         ray r = cameraGenerateRay(randuv, eye, cam, focal_length);
//         vec3 col = rayColor(r);
//         result = result + col;
//     }

//     result = result / float(num_samples);
//     result = pow(result, vec3(1.0/2.2));

//     gl_FragColor = vec4(result, 1.0);

// }