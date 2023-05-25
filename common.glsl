// Contains structs and constants necessary for the ray tracer
// some constant values credited to Wojciech Jarosz

#define EPSILON 1e-3
#define MAX_FLOAT 3.402823466e+38
#define MAX_RECURSION 50
#define PI 3.1415926535897932384626433832795

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