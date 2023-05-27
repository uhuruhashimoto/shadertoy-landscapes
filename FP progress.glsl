float hypot(float x, float y)
{
	return sqrt(x * x + y * y);
}

vec3 sky(vec2 uv){

    float PI = 3.14159265;

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
    return col;

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Output to screen
    fragColor = vec4(sky(uv),1.0);
}


