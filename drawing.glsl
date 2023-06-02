//https://stock.adobe.com/images/abstract-hand-drawn-pencil-hatching-on-white-background-closeup/300715366 crayon texture for kid drawing scene
//https://inspirnathan.com/posts/62-shadertoy-tutorial-part-15/ used to figure out how to add an image as textures
//https://thebookofshaders.com/11/ used to figure out how to move lines

//////////////////////
//
//Kid drawing landscape scene, 
//uses a noise texture to manipulate line segments/shapes to look like an animated drawing
// cs77 final proj, 23S
//JR
//
/////////////////////


#iChannel0 'crayon.jpg'

//from when we did sdfs
float sdLine(in vec2 p, in vec2 a, in vec2 b) //from sdf file
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

//edited from sphere func from sdf unit
float sdCircle(vec2 p, vec2 center, float radius)
{
    return length(p - center) - radius;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    float off = floor(iTime * 8.0) * 0.1;

    //TEXTURE: channel, noise frequency*the offset movement, - thickness, noise
    //this texture is based on "thebook of shaders" reference above, not direct
    uv += (texture(iChannel0, uv / 6.0 + off, 0.0).rg - 0.5) * 0.01;

    //Sun
    float sunray = min(sdLine(uv, vec2(0.65, 0.65), vec2(0.95, 0.95)), sdLine(uv, vec2(0.65, 0.95), vec2(0.95, 0.65)));
    sunray = min(min(sunray, sdLine(uv, vec2(0.8, 0.97), vec2(0.8, 0.6))), sdLine(uv, vec2(0.6, 0.8), vec2(0.98, 0.8)));
    sunray += (textureLod(iChannel0, uv / 2.0 + off, 0.55).b - 0.8) * 0.008;
    float sun = sdCircle(uv, vec2(0.8, 0.8), 0.095); // Center: (0.75, 0.75), Radius: 0.1
    sun += (texture(iChannel0, uv / 2.5 + off, 0.55).b - 1.8) * 0.008;
    sun = min(sun, sunray);
    
    //Sky
    float sky = min(sdLine(uv, vec2(0.1, 0.85), vec2(0.5, 0.83)), sdLine(uv, vec2(0.0, 0.95), vec2(0.7, 0.95)));
    sky = min(min(sky, sdLine(uv, vec2(0.1, 0.85), vec2(0.6, 0.95))), sdLine(uv, vec2(0.05, 0.70), vec2(0.5, 0.83)));
    sky = min(min(sky, sdLine(uv, vec2(0.05, 0.70), vec2(0.65, 0.72))), sdLine(uv, vec2(0.0, 0.6), vec2(0.6, 0.6)));
    sky = min(min(sky, sdLine(uv, vec2(0.6, 0.6), vec2(0.1, 0.45))), sdLine(uv, vec2(0.6, 0.72), vec2(0.1, 0.6)));
    sky = min(min(sky, sdLine(uv, vec2(0.1, 0.45), vec2(0.95, 0.55))), sdLine(uv, vec2(0.0, 0.35), vec2(0.95, 0.55)));
    sky = min(sky, sdLine(uv, vec2(0.65, 0.4), vec2(0.95, 0.55)));
    sky += (texture(iChannel0, uv / 2.5 + off, 0.75).b ) * 0.009;

    //Darker sunrays
    float skydet = min(sdLine(uv, vec2(0.73, 0.65), vec2(0.71, 0.6)), sdLine(uv, vec2(0.98, 0.73), vec2(0.93, 0.75)));
    skydet = min(skydet, sdLine(uv, vec2(0.93, 0.85), vec2(0.98, 0.87)));
    skydet = min(skydet, sdLine(uv, vec2(0.88, 0.62), vec2(0.85, 0.67)));
    skydet = min(skydet, sdLine(uv, vec2(0.85, 0.93), vec2(0.87, 0.97)));
    sky += (texture(iChannel0, uv / 5.0 + off, 0.75).b - 5.0) * 0.009;

    //foreground mountains
    float ground = min(sdLine(uv, vec2(0.0, 0.15), vec2(0.1, 0.3)), sdLine(uv, vec2(0.1, 0.3), vec2(0.2, 0.15)));
    ground = min(min(ground, sdLine(uv, vec2(0.2, 0.15), vec2(0.25, 0.2))), sdLine(uv, vec2(0.25, 0.2), vec2(0.4, 0.1)));
    ground = min(min(ground, sdLine(uv, vec2(0.4, 0.1), vec2(0.65, 0.3))), sdLine(uv, vec2(0.65, 0.3), vec2(0.95, 0.1)));
    ground = min(ground, sdLine(uv, vec2(0.95, 0.1), vec2(1.1, 0.2)));
    ground += (texture(iChannel0, uv / 2.5 + off, 0.55).b - 2.8) * 0.008;

    //background mountains
    float back = min(sdLine(uv, vec2(0.15, 0.25), vec2(0.35, 0.4)), sdLine(uv, vec2(0.35, 0.4), vec2(0.5, 0.3)));
    back = min(min(back, sdLine(uv, vec2(0.5, 0.3), vec2(0.54, 0.35))), sdLine(uv, vec2(0.54, 0.35), vec2(0.6, 0.29)));
    back = min(min(back, sdLine(uv, vec2(0.73, 0.28), vec2(0.85, 0.4))), sdLine(uv, vec2(0.85, 0.4), vec2(1.0, 0.3)));
    back += (texture(iChannel0, uv / 2.5 + off, 0.55).b - 2.8) * 0.008;
    //mountain details
    float detail = min(sdLine(uv, vec2(0.9, 0.1), vec2(0.65, 0.1)), sdLine(uv, vec2(0.7, 0.03), vec2(0.03, 0.03)));
    detail = min(min(detail, sdLine(uv, vec2(0.4, 0.15), vec2(0.4, 0.25))), sdLine(uv, vec2(0.95, 0.15), vec2(0.95, 0.2)));
    detail = min(min(detail, sdLine(uv, vec2(0.1, 0.05), vec2(0.1, 0.15))), sdLine(uv, vec2(0.14, 0.075), vec2(0.25, 0.075)));
    detail = min(min(detail, sdLine(uv, vec2(0.58, 0.05), vec2(0.58, 0.15))), sdLine(uv, vec2(0.28, 0.05), vec2(0.28, 0.09)));
    detail = min(min(detail, sdLine(uv, vec2(0.5, 0.05), vec2(0.5, 0.08))), sdLine(uv, vec2(0.75, 0.16), vec2(0.75, 0.12)));
    detail = min(detail, sdLine(uv, vec2(0.8, 0.04), vec2(0.98, 0.04)));
    back = min(back, detail);

    //darker/smaller sky lines
    float cloud = min(sdLine(uv, vec2(0.02, 0.45), vec2(0.55, 0.47)), sdLine(uv, vec2(0.1, 0.95), vec2(0.5, 0.95)));
    cloud = min(min(cloud, sdLine(uv, vec2(0.3, 0.65), vec2(0.7, 0.65))), sdLine(uv, vec2(0.4, 0.85), vec2(0.6, 0.85)));
    cloud = min(min(cloud, sdLine(uv, vec2(0.65, 0.54), vec2(0.9, 0.54))), sdLine(uv, vec2(0.05, 0.75), vec2(0.3, 0.75)));
    cloud += (texture(iChannel0, uv / 2.5 + off, 0.55).b - 2.0) * 0.008;


    //initialize all the different colors
    vec3 col1 = vec3(0.9, 0.9, 0.9);
    vec3 col2 = vec3(1.0, 1.0, 0.9);
    vec3 col3 = vec3(1.0, 0.9, 1.0);
    vec3 col4 = vec3(0.9, 1.0, 1.0);
    vec3 col5 = vec3(1.0, 1.0, 0.95);
    vec3 col6 = vec3(1.0, 1.0, 1.0);

    if(sun < 0.01)
        col1 = vec3(1.0, 0.85, 0.4); //light yellow
    if(sky < 0.01)
        col2 = vec3(0.6, 0.7, 01.0); //light blue
    if(ground < 0.01)
        col3 = vec3(0.4, 0.7, 0.6); //light green
    if(back < 0.01)
        col4 = vec3(0.3, 0.6, 0.5); //dark green
    if(cloud < 0.01)
        col5 = vec3(0.7, 0.7, 0.9); //dark blue
    if(skydet < 0.01)
        col6 = vec3(0.9, 0.75, 0.4); //dark yellow


    //combine all the colors
    vec3 allc = col1*col2*col3*col4*col5*col6; 

    fragColor = vec4(allc, 1.0);
}