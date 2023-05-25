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



// ---------------------- CAMERA ------------------------ //
ray camera_generate_ray(vec2 uv, vec3 eye, camera cam, float focal_length)
{
    vec3 dir = -focal_length * cam.w + uv.x * cam.u + uv.y * cam.v;
    return ray(eye, normalize(dir));
}

void camera_setup_coord_frame(vec3 dir, vec3 up, inout camera cam)
{
    cam.w = -normalize(dir);
    cam.u = normalize(cross(up, cam.w));
    cam.v = cross(cam.w, cam.u);
    cam.w = 0.5*cam.w;
}