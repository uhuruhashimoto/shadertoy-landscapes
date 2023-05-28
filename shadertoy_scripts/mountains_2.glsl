#define EPSILON 1e-3
#define OCTAVES 1

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

vec3 vnoise( in vec2 p )
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

float noise(in vec2 p) {
    return dot(vnoise(p), vec3(70.0) );
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

// sum fractal noise
// plane height
float terrainH(in vec2 p) {
    //return 2.0;
    const mat2 m2 = mat2(0.8,-0.6,0.6,0.8); //rotation matrix
    float f = 0.0;
    float c = 1.0;
    for (int i=0; i<OCTAVES; i++) {
        f += c * noise(m2 * p * 2.0);
        c *= 0.5;
        p = m2 * p * 2.0;
    }
    return f;
}


// The normal can be computed as usual with the central differences method:
vec3 getNormal( const vec3 pos, float t)
{
    vec2  eps = vec2( 0.001*t, 0.0 );
    return normalize( vec3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                            2.0*eps.x,
                            terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
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
    vec3 n = getNormal(p, t);
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
        float h = terrainH(p.xz);
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


void mainImage(out vec4 fragColor, in vec2 fragCoord )
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
    float focal_length = 1./4.;
    camera cam;
    cameraCoords(dir, up, cam);
    ray r = cameraGenerateRay(uv, eye, cam, focal_length);

    // Ray trace
    vec3 col = rayColor(r);

    // gamma correction
    col = pow(col, vec3(1.0 / 2.2));

    fragColor = vec4(col, 1.0);
}