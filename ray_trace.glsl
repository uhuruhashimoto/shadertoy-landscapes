// code adapted from https://iquilezles.org/articles/terrainmarching/

#include "random/random.glsl"
#include "common.glsl"

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
    cam.w = 0.5*cam.w;
}

// ---------------------- LANDSCAPE INTERACTION ------------------------ //
void renderImage( vec3 image )
{
    for( int j=0; j < yres; j++ ) {
        for( int i=0; i < xres; i++ ) {
            ray r = generateRayForPixel( i, j );
            float t;
            if (castRay( r, t )) {
                image[xres*j+i] = terrainColor( r, t );
            }
            else {
                image[xres*j+i] = skyColor();
            }
        }
    }
}

vec3 skyColor() {
    return vec3(0.0, 0.0, 0.3);
}

vec3 terrainColor( const ray r, float t )
{
    const vec3 p = r.origin + r.direction * t;
    const vec3 n = getNormal( p );
    const vec3 s = getShading( p, n );
    const vec3 m = getMaterial( p, n );
    return applyFog( m * s, t );
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
    return vec3(0.0);
}

vec3 getMaterial(vec3 p, vec3 n)
{
    return vec3(0.0);
}

vec3 applyFog(vec3 p, float t)
{
    return vec3(1.0, 0.0, 0.0);
}

// ---------------------- RAY TRACE ------------------------ //
bool castRay(ray r, inout float resT )
{
    float dt = 0.01f;
    const float mint = 0.001f;
    const float maxt = 10.0f;
    float lh = 0.0f;
    float ly = 0.0f;
    for( float t = mint; t < maxt; t += dt )
    {
        const vec3  p = r.origin + r.direction*t;
        const float h = f( p.xz );
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

// --------------------- DRIVER -------------------------- //
void main()
{
    // Aliasing
    int num_samples = 1;
    int max_depth = 20;
    vec3 result = vec3(0.);

    // scattering
    init_rand(gl_FragCoord.xy, float(iTime));

    // Image
    vec2 uv = gl_FragCoord.xy / iResolution.xy - 0.5;
    float focal_length = 4.;

    // Camera
    camera cam;
    vec3 eye = vec3(-2, 2, 1);
    vec3 up = vec3(0, 1, 0);
    vec3 dir = vec3(0.0, 0.0, -1.0) - eye;
    cameraCoords(dir, up, cam);

    for (int i=0; i<num_samples; i++) {
        float randseed = rand1(g_seed);
        vec2 randuv = vec2(uv.x + randseed / iResolution.x, uv.y + randseed / iResolution.y);
        ray r = cameraGenerateRay(randuv, eye, cam, focal_length);
        vec3 col = ray_color(r, max_depth);
        result = result + col;
    }

    result = result / float(num_samples);
    result = pow(result, vec3(1.0/2.2));

    gl_FragColor = vec4(result, 1.0);

}