#define EPSILON 1e-3
#define OCTAVES 2

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

vec3 noise3( in vec2 p )
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
    return n;
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
// sky mixing values from https://www.shadertoy.com/view/MdX3Rr
vec3 skyColor(const ray r, float t) {
    vec3 p = r.origin + r.direction * t;
    vec3 col = vec3(0.3,0.5,0.85);
    return mix( col, 0.85*vec3(0.7,0.75,0.85), pow( 1.0-max(r.direction.y,0.0), 4.0 ) );
}

// fractional brownian motion from https://iquilezles.org/articles/fbm/
float fbm( in vec2 p)
{
    const mat2 m2 = mat2(0.8,-0.6,0.6,0.8); //rotation matrix
    float f = 0.0;

    // octave 1
    f += 0.5000*noise(p); 
    p = m2*p*2.02;

    // octave 2
    //f += 0.2500*noise(p); 
    //p = m2*p*2.03;

    // octave 3
    //f += 0.1250*noise(p); p = m2*p*2.01;
    //f += 0.0625*noise(p);
    return f/0.9375;
}

// sum fractal noise
// plane height
float f(in vec2 p) {
    //return 2.0;
    const mat2 m2 = mat2(0.8,-0.6,0.6,0.8); //rotation matrix
    float f = 0.0;
    float c = 1.0;
    vec2 d = vec2(0.0);
    for (int i=0; i<OCTAVES; i++) {
        vec3 n = noise3(p);
        d += n.yz;
        f += c * n.x / (1. + dot(d, d));
        c *= 0.5;
        p = m2 * p * 2.0;
    }
    return f;
}

// float f( in vec2 x)
// {
//     const mat2 m2 = mat2(0.8,-0.6,0.6,0.8); //rotation matrix
// 	vec2  p = x*0.003/250.;
//     float a = 0.0;
//     float b = 1.0;
// 	vec2  d = vec2(0.0);
//     for( int i=0; i<3; i++ )
//     {
//         vec3 n = noised(p);
//         d += n.yz;
//         a += b*n.x/(1.0+dot(d,d));
// 		b *= 0.5;
//         p = m2*p*2.0;
//     }
//     return a;

//     a *= 0.9;
// 	return 250.*120.0*a;
// }


// The normal can be computed as usual with the central differences method:
vec3 getNormal( const vec3 p )
{
    return normalize( vec3( f(vec2(p.x-EPSILON,p.z)) - f(vec2(p.x+EPSILON,p.z)),
                            2.0f*EPSILON,
                            f(vec2(p.x,p.z-EPSILON)) - f(vec2(p.x,p.z+EPSILON)) ) );
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
    return vec3(0.0);
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
        float h = f(p.xz);
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
        if (t > maxt) break;
    }
    return false;
}

vec3 rayColor(ray r)
{
    float t;
    if (castRay(r, t)) {
        return terrainColor(r, t);
    }
    return skyColor(r, t);
}

vec3 shade(vec3 p)
{
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
    vec3 col = rayColor(r);

    // gamma correction
    return pow(col, vec3(1.0 / 2.2));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(render(), 1.0);

}