#include "sdf.glsl"

struct ray
{
    vec3 origin;    // This is the origin of the ray
    vec3 direction; // This is the direction the ray is pointing in
};

// TASK 2.1
void compute_camera_frame(vec3 dir, vec3 up, out vec3 u, out vec3 v, out vec3 w)
{

// ################ Edit your code below ################
    w = -normalize(dir);
    u = normalize(cross(up, w));
    v = cross(w, u);
}

// TASK 2.2
ray generate_ray_orthographic(vec2 uv, vec3 e, vec3 u, vec3 v, vec3 w)
{

// ################ Edit your code below ################
    vec3 orig = e + uv.x * u + uv.y * v;
    return ray(orig, -w);
}

// TASK 2.3
ray generate_ray_perspective(vec2 uv, vec3 eye, vec3 u, vec3 v, vec3 w, float focal_length)
{

// ################ Edit your code below ################
    vec3 dir = -focal_length * w + uv.x * u + uv.y * v;
    return ray(eye, normalize(dir));
}

bool ray_march(ray r, float step_size, int max_iter, out vec3 hit_loc, out int iters)
{

// ################ Edit your code below ################

    // TODO: implement ray marching

    // it should work as follows:
    //
    // while (hit has not occured && iteration < max_iters)
    //     march a distance of step_size forwards
    //     evaluate the sdf
    //     if a collision occurs (SDF < EPSILON)
    //         return hit location and iteration count
    // return false
    vec3 p = r.origin;
    float epsilon = 0.0;
    iters = 0;
    while (iters < max_iter) {
        p += step_size * r.direction;
        float dist = world_sdf(p);
        if (dist < epsilon) {
            hit_loc = p;
            return true;
        }
        iters++;
    }
    iters = max_iter;
    return false;

}

bool sphere_tracing(ray r, int max_iter, out vec3 hit_loc, out int iters)
{

// ################ Edit your code below ################

    //hit_loc = r.origin + r.direction * (-r.origin.y / r.direction.y);
    //iters = 1;
    //return true;

    // TODO: implement sphere tracing

    // it should work as follows:
    //
    // while (hit has not occured && iteration < max_iters)
    //     set the step size to be the SDF
    //     march step size forwards
    //     if a collision occurs (SDF < EPSILON)
    //         return hit location and iteration count
    // return false

    vec3 p = r.origin;
    float epsilon = 0.001;
    iters = 0;
    float step_size = 0.0;
    while (iters < max_iter) {
        step_size = world_sdf(p);
        p += step_size * r.direction;
        if (step_size < epsilon) {
            hit_loc = p;
            return true;
        }
        iters++;
    }
    iters = max_iter;
    return false;
}