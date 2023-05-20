// pre-defined constants
#define EPSILON 1e-4
#define PI 3.1415926535897932384626433832795

// The animation which you see is of a 2D slice of a 3D object. The objects exist in [-1, 1] space
// and the slice is continuously moved along z=[-1,1] using a cosine. This method renders what the
// current z value is as a progress bar at the bottom of the animation for reference.
vec3 shade_progress_bar(vec2 p, vec2 res, float z)
{
    // have to take account of the aspect ratio
    float xpos = p.x * res.y / res.x;

    if (xpos > z - 0.01 && xpos < z + 0.01)
        return vec3(1.0);
    else
        return vec3(0.0);
}