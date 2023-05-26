
// returns the signed distance to a sphere from position p
float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

// Returns the signed distance to a line segment.
//
// p is the position you are evaluating the distance to.
// a and b are the end points of your line.
//
float sdLine(in vec2 p, in vec2 a, in vec2 b)
{
    vec2 ab = b - a;
    vec2 ap = p - a;
    vec2 bp = p - b;
    float coeff = dot(ap, ab) / (length(ab) * length(ab));
    vec2 x = coeff * ab + a;
    vec2 proj = p - x;
    if (coeff < 0.0 || coeff > 1.0) {
        return min(length(ap), length(bp));
    }
    return length(proj);
}

// Returns the signed distance from position p to an axis-aligned box centered at the origin with half-length,
// half-height, and half-width specified by half_bounds
float sdBox(vec3 p, vec3 half_bounds)
{
    // Credit: watched first few minutes of https://www.youtube.com/watch?v=62-pRVZuS5c on derivation 
    // to understand the quadrant idea

    // calculate the distance to the point without sign (putting pt
    // in the top right quadrant)
    vec3 dist_out = abs(p) - half_bounds;

    // if we're inside the box, the closest side is our distance, which
    // is the dist closest to 0 if they're negative
    float dist_in = max(dist_out.x, max(dist_out.y, dist_out.z));

    // make sure the distance out is out
    dist_out = max(dist_out, 0.0);

    // make sure the distance inside is in
    dist_in = min(dist_in, 0.0);

    return length(dist_out) + dist_in;
}


// Returns the signed distance from position p to a 
// cylinder or radius r with an axis connecting the two points a and b.
float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 ba = b - a;
    vec3 pa = p - a;
    float paba = dot(pa, ba);
    float baba = dot(ba, ba);
    float l = paba / baba;

    // clip
    if (l > 1.0 ) {
        vec3 proj = p - ((l * ba) + a);
        float y = (l - 1.0) * length(ba);
        float x =  length(proj) - r;
        // turn off x distance if we're above the capped ends
        x = max(x, 0.0);
        return sqrt(x*x + y*y);

    } else if (l < 0.0) {
        vec3 proj = p - ((l * ba) + a);
        float y = (l) * length(ba);
        float x =  length(proj) - r;
        // turn off x distance if we're above the capped ends
        x = max(x, 0.0);
        return sqrt(x*x + y*y);
    } else {
        // clip to projection on body of cylinder
        l = min(l, 1.0);
        l = max(0.0, l);
        vec3 proj = p - ((l * ba) + a);
        float lat = length(proj) - r;
        if (lat <= 0.0) {
            float top = -l * length(ba);
            float bot = -(1.0 - l) * length(ba);
            return max(top, max(bot, lat));
        }
        return lat;
    }

}


// Returns the signed distance from position p to a cone with axis connecting points a and b and (ra, rb) being the
// radii at a and b respectively.
float sdCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    vec3 ba = b - a;
    vec3 pa = p - a;
    float paba = dot(pa, ba);
    float baba = dot(ba, ba);
    float l = paba / baba;

    // above b
    if (l > 1.0 ) {
        vec3 proj = p - ((l * ba) + a);
        float y = (l - 1.0) * length(ba);
        float x =  length(proj) - rb;
        // turn off x distance if we're above the capped ends
        x = max(x, 0.0);
        y = max(y, 0.0);
        float side = sqrt(x*x + y*y);

        float r = ra - (ra - rb) * l;
        float lat = length(proj) - r;

        return max(side, lat);

    // below a
    } else if (l < 0.0) {
        vec3 proj = p - ((l * ba) + a);
        float y = (l) * length(ba);
        float x =  length(proj) - ra;
        // turn off x distance if we're above the capped ends
        x = max(x, 0.0);
        return sqrt(x*x + y*y);
    } else {
        // clip to projection on body of cylinder
        l = min(l, 1.0);
        l = max(0.0, l);
        vec3 proj = p - ((l * ba) + a);
        float r = ra - (ra - rb) * l;
        float lat = length(proj) - r;
        if (lat <= 0.0) {
            float top = -l * length(ba);
            float bot = -(1.0 - l) * length(ba);
            return max(lat, max(top, bot));
        }
        return lat;
    }
}

float opSmoothUnion(float d1, float d2, float k)
{
    float h = max((k - abs(d1-d2)), 0.0);
    return min(d1, d2) - h*h/(4.0 * k);
}

float opSmoothSubtraction(float d1, float d2, float k)
{
    float h = max(k - (abs(d1+d2)), 0.0);
    return max(-d1, d2) + h*h/(4.0 * k);
}

float opSmoothIntersection(float d1, float d2, float k)
{
    float h = max((k - abs(d1-d2)), 0.0);
    return max(d1, d2) + h*h/(4.0 * k);
}

float opRound(float d, float iso)
{
    return d - iso;
}


// returns the signed distance to an infinite plane with a specific y value
float sdPlane(vec3 p, float z)
{
    return p.y - z;
}

float world_sdf(vec3 p)
{
    return sdPlane(p, 0.f);
}


vec3 computeNormal(vec3 p)
{

// ################ Edit your code below ################

    const float h = 1e-5;
    const vec2 d10 = vec2(1, 0);
    float sdp = world_sdf(p);
    vec3 px = p + h * d10.xyy;
    vec3 py = p + h * d10.yxy;
    vec3 pz = p + h * d10.yyx;
    float x = world_sdf(px);
    float y = world_sdf(py);
    float z = world_sdf(pz);
    return normalize(vec3(x - sdp, y - sdp, z - sdp));
}