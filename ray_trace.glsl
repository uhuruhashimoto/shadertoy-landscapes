// code adapted from https://iquilezles.org/articles/terrainmarching/
#include "random/perlin.glsl"
#include "random/random.glsl"
#include "common.glsl"
#iChannel0 'Mountain_2__mp.jpg'

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
vec2 tohash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float fuNnoise( in vec2 p )
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
	vec3  n = h*h*h*h*vec3( dot(a,tohash(i+0.0)), dot(b,tohash(i+o)), dot(c,tohash(i+1.0)));
    return dot( n, vec3(70.0) );
}

const mat2 m2 = mat2(1.6,  1.2, -1.2,  1.6);

float fbm4(vec2 p) {
    float amp = 0.5;
    float h = 0.0;
    for (int i = 0; i < 4; i++) {
        float n = fuNnoise(p);
        h += amp * n;
        amp *= 0.5;
        p = m2 * p ;
    }

	return  0.5 + 0.5*h;
}


vec3 skyColor(vec2 uv) {
    //return vec3(0.0, 0.0, 0.3);

    vec2 pos = vec2(uv.x * iResolution.x / iResolution.y - 0.5 * iResolution.x / iResolution.y, uv.y - 0.5);

    float a = atan(pos.x, pos.y);
    float val = 0.0;
    for (float i = 0.0; i < 1.0; i += 0.04)
    {
        float speed = (mod(pow(i * 200.0, 2.1) * 1.2, 3.8) - 5.0) * 0.75;
		float phase = iTime * speed + i * 0.256;

        float comp1 = pow(i * 20.0, 2.5);

        float freq = 2.0 * mod((comp1 - mod(comp1, 1.0)), 15.0) + 3.0;
        float f = pow(max(0.0, sin(a * freq + phase)), 0.2);
        val += pow(max(0.0, sin(a * freq + phase)), 0.3);
    }

    float c = 1.0 - (hypot(pos.x, pos.y) - 0.10) / (val + 0.02) * 40.0;
    c = pow(c, 3.0);
    c = clamp(c, 0.0, 1.0);

    vec3 sky_horizon = vec3(0.4, 0.7, 0.9);
    vec3 sky_zenith = vec3(0.1, 0.4, 0.8);
    vec3 sky = sky_zenith + sky_horizon * pow(1.0 - uv.y, 0.4);


    vec3 col = (vec3(1.1, 1.1, sin(iTime*4.0) * 0.01 + 0.9) - sky) * c + sky;

    float v = 0.006;


    vec2 mo = iMouse.xy/iResolution.xy;
    vec3 cloudCol = vec3(1.0);
    uv += mo * 10.0;

    vec2 scale = uv * 2.0;
    vec2 turbulence = 0.008 * vec2(fuNnoise(vec2(uv.x * 10.0, uv.y *10.0)), fuNnoise(vec2(uv.x * 10.0, uv.y * 10.0)));
    scale += turbulence;
	float n1 = fbm4(vec2(scale.x - 20.0 * sin(iTime * v * 2.0), scale.y - 50.0 * sin(iTime * v)));
    col = mix( col, cloudCol, smoothstep(0.5, 0.8, n1));

    //layer2
    scale = uv * 0.5;
    turbulence = 0.05 * vec2(fuNnoise(vec2(uv.x * 2.0, uv.y * 2.1)), fuNnoise(vec2(uv.x * 1.5, uv.y * 1.2)));
    scale += turbulence;
    float n2 = fbm4(scale + 20.0 * sin(iTime * v ));
    col =  mix( col, cloudCol, smoothstep(0.2, 0.9, n2));
    col = min(col, vec3(1.0));

    return col;
}

// plane height
float f(float x, float z) {
    //return 1.+0.5*noise(vec2(x,z));
    return 0.5 * sin(x+(iTime*0.7))*sin(z+(iTime*0.7));
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
	vec4 gragcolor = texture(iChannel0, uv * 2.0);
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