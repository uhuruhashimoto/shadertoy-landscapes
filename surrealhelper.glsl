// code adapted from https://iquilezles.org/articles/terrainmarching/
//https://polyhaven.com/a/leafy_grass - used the seamless grass texture for the surrealism scene
//https://inspirnathan.com/posts/62-shadertoy-tutorial-part-15/ used to figure out how to add an image as textures

#include "random/perlin.glsl"
#include "random/random.glsl"
#include "common.glsl"
#iChannel0 'grass.jpg'
//////////////////////
//
//surreal landscape scene where all the rendering shapes happen, 
//
// cs77 final proj, 23S
//based on realistic scene
//JR
//
/////////////////////

// ---------------------- CAMERA ------------------------ //
ray cameraGenerateRay(vec2 uv, vec3 eye, camera cam, float focal_length)
{
    vec3 dir = -focal_length * cam.w + uv.x * cam.u + uv.y * cam.v;
    return ray(eye, normalize(dir));
}

void cameraCoords(vec3 dir, vec3 up, inout camera cam)
{
    cam.w = -normalize(dir*iTime);
    cam.u = normalize(cross(up, cam.w));
    cam.v = cross(cam.w, cam.u);
}

// ---------------------- LANDSCAPE INTERACTION ------------------------ //

float horizonFog(float dist, float density, float startDistance, float endDistance)
{
    float fogFactor = smoothstep(startDistance, endDistance, dist);
    float fogAmount = fogFactor * density;
    return fogAmount;
}

float hypot(float x, float y)
{
	return sqrt(x * x + y * y);
}


vec3 skyColor(vec2 uv) {
    //return vec3(0.0, 0.0, 0.3);

    vec2 pos = vec2(uv.x * iResolution.x / iResolution.y - 0.5 * iResolution.x / iResolution.y, uv.y - 0.5);
    
    float val = 0.0;
    
    float sun = 1.0 - (hypot(pos.x+sin(iTime)*0.08, pos.y+cos(iTime)*0.05) - 0.10) / (val + 0.02) * 40.0;
    
   	sun = pow(sun, 3.0);
    sun = clamp(sun, 0.0, 1.0)*sin(iTime);
    
    vec3 bottom = vec3(0.4, 0.7, 0.9)*sin(iTime*0.1);
    vec3 top = vec3(0.1, 0.4, 0.8)*cos(iTime*0.5);
    vec3 sky = top + bottom * pow(1.0 - uv.y, 0.4);


    vec3 col = (vec3(1.1, 1.1,  0.3) - sky) * sun + sky;

    float v = 0.006;


    vec2 mo = iMouse.xy/iResolution.xy;
    vec3 cloudCol = vec3(1.0);
    uv += mo * 10.0;
   

    col =  mix( col, cloudCol, smoothstep(0.2, 0.9, 0.5));
    col = min(col, vec3(1.0));

    return col;
}

// plane height
float f(float x, float z) {
    //return 1.+0.5*noise(vec2(x,z));
    return (0.3 * sin(x+(iTime*0.7)*1.2)*cos(z+(iTime*0.05)*0.2)) - 2.5;
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
    vec3 s = vec3(1.0, 0.5, 0.5);
    return vec3(dot(n, s));
}

vec3 getMaterial(vec3 p, vec3 n)
{
	vec2 uv = p.xy;
	vec4 gragcolor = texture(iChannel0, uv * 3.0)*vec4(vec3(0.1, 0.4, 0.15), 1.0);
    return gragcolor.xyz;
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
    return applyFog(m*s, t );
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

vec3 rayColor(ray r, vec2 uv)
{
    float t;
    if (castRay(r, t)) {
        return terrainColor(r, t);
    }
    return skyColor(uv);
}
