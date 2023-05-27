#iChannel0 'Mountain_2__mp.jpg'
mat2 rot2D(float theta)
{
    return mat2(cos(theta), sin(theta), -sin(theta), cos(theta));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	// convert from pixel space to homogenous coordinate (-1 to 1 on each axis)
	vec2 p = -1.0 + 2.0*fragCoord.xy/iResolution.xy;

    mat2 mRot = rot2D(iTime);
    
	// define ray (we cast outward from the center, perspective)
	// ** fiddle with this to alter your view (or camera, if you will) **
	vec3 origin = vec3(0.0, 0.0, 0.0);
	vec3 direction = vec3(p.x, p.y, 1.0);
    direction.xy *= mRot; // rotate around Z
	normalize(direction);

	// define plane (by a normal and a distance to from center)
	// this one faces us directly (on Z-axis) and is almost right in front
	vec3 normal = vec3(0.0, 0.0, -1.0);
	float dist = 2. + sin(iTime);

	// what we want to know is the intersection point:
	// - a plane equation looks like this: ax+bx+cz + d = 0
	// - we can substitute a, b and c for the plane's normal and d for the distance (dist)
	// - that leaves us with unknown x, y and z which is the intersection point
   
	// we need to solve this:
	// the point can be expressed as: intersection = origin + t*direction
	// since we already know 2 of those, that leaves us with finding t
	
	// to find t (skipping the process of solving, Google and do it manually or use Matlab):
	float denominator = dot(direction, normal);
	if (abs(denominator) > 0.001) // if it's practically zero, we did not hit it! (*)
	{
		float t = (dot(origin, normal) + dist) / denominator;
	
		// and now we can calculate the intersection point like described above:
		vec3 hit = origin + t*direction;
	
		// mapping this to meaningful 2D UVs depends on the plane
		// we use X and Y as we intersect with Z, if the plane normal were 0,1,0 we'd use X and Z
		vec2 uv = hit.xy;
		fragColor = texture(iChannel0, uv);
	}
	else
	{
		// no intersection
		fragColor = vec4(0.0, 0.0, 0.0, 1.0);
	}
	
	// now, how to run this on older hardware?
	// - the intersection check (*) is usually not necessary, so don't bother
	// - a lot of values are fixed to 0, 1 and -1 so they cancel out a *lot* of operations
	//   (note that fiddling with for ex. your plane or origin may change things)
	// - all the "obvious" optimizations for those platforms, I did this in assembly on a 486DX PC with
	//   a rotating camera, depth (t) shading et cetera
}