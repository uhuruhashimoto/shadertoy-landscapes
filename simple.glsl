//https://inspirnathan.com/posts/62-shadertoy-tutorial-part-15/ used to figure out how to add an image as textures
//https://www.shadertoy.com/view/4lKcDD used to understand sine mountains


//////////////////////
//
//super simple landscape scene, 
//uses sine waves as mountains
// cs77 final proj, 23S
//based morimea's sine mountains
//JR
//
/////////////////////
#iChannel0 'crayon.jpg'

vec4 circle(vec2 uv, vec2 pos, float radius, vec3 color) {
	float d = length(pos - uv) - radius;
	float t = clamp(d, 0.0, 1.0);
	return vec4(color, 1.0 - t);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 res = iResolution;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    vec3 col = (vec3(0.7, 0.8, 1.0));

    //the base of this for loop is from the sine mountain source, but not direct
    for (float i = 0.0; i < 4.0; i ++) //four waves of hills
    {
    	float hills = sin((uv.x * pow(5.0 - i, 1.0) + iTime * 0.9) - 1.5 * i - 0.5) *0.08 + 0.4 - i * 0.04; //define the sound waves
		if (uv.y < hills)
   		{
            //apply the color to these waves
			col = vec3(0.4, 0.9, 0.6) * (i / 22.0) * 0.7;
    	}
    }

    vec3 sunColor = vec3(1.0, 1.0, 0.4);
    //adding some texture for movement
    vec4 crayon = texture(iChannel0, vec2(cos(iTime*0.2)*uv.y, sin(iTime*0.2)*uv.x)*0.1);
    vec4 sun = circle(fragCoord.xy, res.xy*(vec2((sin(iTime)*0.05)+0.7, (cos(iTime)*0.04)+0.8)), 0.15*res.y, sunColor);
    
    vec4 sky = vec4(col, 1.0);
    sky = vec4(mix(sky.rgb,crayon.rgb,0.1),1.0);
    vec4 final = mix(sky, sun, sun.a);
    final = vec4(mix(final.rgb,crayon.rgb/2.0,0.1),1.0);
    // Output to screen
    fragColor = final;
}

