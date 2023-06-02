//https://inspirnathan.com/posts/65-glow-shader-in-shadertoy/ used to understand glow

//////////////////////
//
//neon landscape scene, 
//uses a glow to draw line segments
// cs77 final proj, 23S
//based on inspirinathan's glow explanation
//JR
//
/////////////////////


const float PI = 3.1415926;

const int segNum = 14;

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

//edited sphere func from sdfs unit
float sdCircle(vec2 p, vec2 center, float radius)
{
    return length(p - center) - radius;
}

//the base fot this neon function is from neon lesson, but not directr
float neonEffect(vec2 uv, vec2[segNum] lineSegments)
{
    float intensity = 0.0;
    
    for (int i = 0; i < segNum; i += 2)
    {
        vec2 lineStart = lineSegments[i];
        vec2 lineEnd = lineSegments[i + 1];
        
        //angle around current pixel that the neon shines on
        float light = acos(dot(normalize(lineEnd - uv), normalize(lineStart - uv))) / PI;
        
       //time effects the glow, makes it look shiny 
        intensity += pow(light, 25.0 + (sin(iTime * 1.0)*20.0));
    }
    
    return intensity;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 uv = fragCoord / iResolution.xy;

    //line segments for neon effect
    //had to make it a list so that i can draw the neon on instead of it being added after
    vec2[segNum] sun = vec2[](
        vec2(0.65, 0.65), vec2(0.95, 0.95),
        vec2(0.65, 0.95), vec2(0.95, 0.65) ,
        vec2(0.8, 0.97), vec2(0.8, 0.6),
        vec2(0.6, 0.8), vec2(0.98, 0.8),
        vec2(0.65, 0.95), vec2(0.95, 0.65) ,
        vec2(0.8, 0.97), vec2(0.8, 0.6),
        vec2(0.6, 0.8), vec2(0.98, 0.8)
    );
    vec2[segNum] sky = vec2[](
        vec2(0.02+(sin(iTime*0.7)*0.1), 0.47), vec2(0.55+(sin(iTime*0.7)*0.1), 0.47),
        vec2(0.1+(sin(iTime*0.7)*0.2), 0.95), vec2(0.5+(sin(iTime*0.7)*0.2), 0.95),
        vec2(0.3+(sin(iTime*0.7)*0.1), 0.65), vec2(0.7+(sin(iTime*0.7)*0.1), 0.65),
        vec2(0.4+(sin(iTime*0.7)*0.2), 0.85), vec2(0.6+(sin(iTime*0.7)*0.2), 0.85),
        vec2(0.65+(sin(iTime*0.7)*0.1), 0.54), vec2(0.9+(sin(iTime*0.7)*0.1), 0.54),
        vec2(0.05+(sin(iTime*0.7)*0.05), 0.75), vec2(0.3+(sin(iTime*0.7)*0.05), 0.75), 
        vec2(0.2+(sin(iTime*0.7)*0.25), 0.35), vec2(0.85+(sin(iTime*0.7)*0.25), 0.35)
    );
     vec2[segNum] ground = vec2[](
        vec2(0.0, 0.15+(sin(iTime*0.7)*0.05)), vec2(0.1, 0.3+(sin(iTime*0.7)*0.05)),
        vec2(0.1, 0.3+(sin(iTime*0.7)*0.05)), vec2(0.2, 0.15+(sin(iTime*0.7)*0.05)),
        vec2(0.2, 0.15+(sin(iTime*0.7)*0.05)), vec2(0.25, 0.2+(sin(iTime*0.7)*0.05)),
        vec2(0.25, 0.2+(sin(iTime*0.7)*0.05)), vec2(0.4, 0.1+(sin(iTime*0.7)*0.05)),
        vec2(0.4, 0.1+(sin(iTime*0.7)*0.05)), vec2(0.65, 0.3+(sin(iTime*0.7)*0.05)),
        vec2(0.65, 0.3+(sin(iTime*0.7)*0.05)), vec2(0.95, 0.1+(sin(iTime*0.7)*0.05)),
        vec2(0.95, 0.1+(sin(iTime*0.7)*0.05)), vec2(1.1, 0.2+(sin(iTime*0.7)*0.05))
    );
    
    // use neon effect
    float neonsun = neonEffect(uv, sun);
    float neonsky = neonEffect(uv, sky);
    float neonground = neonEffect(uv, ground);

    // output with color 
    vec3 col1 = neonsun * vec3(1.0, 1.0, 0.3);
    vec3 col2 = neonsky * vec3(0.25, 0.5, 1.0); 
    vec3 col3 = neonground * vec3(0.1, 1.0, 0.2); 
    col1+=col2+col3;  
    fragColor = vec4(col1, 1.0);
}
