
//#iKeyboard
#include "hash.glsl"

// map fragment coordinates to world coordinates
vec2 frag2World(in vec2 frag) {
  vec2 uv = frag.xy / iResolution.xy - 0.5;
  return uv * vec2(iResolution.x / iResolution.y, 1.0) * 10.0;
}

float falloff(float t) {
  float t2 = clamp(abs(t), 0.0, 1.0);
  return 1.0 - smoothstep(0.0, 1.0, t2);
}

vec2 grad(vec2 center) {
  float angle = radians(360.0 * hash12(center));
  vec2 g = vec2(cos(angle), sin(angle));
  return g;
}

float bump(vec2 p, vec2 center)
{
  vec2 offset = p - center;

  //float v = isKeyToggled(Key_V) ? 2. * hash12(center) - 1. : dot(offset, grad(center));
  float v = dot(offset, grad(center));

  return falloff(p.x - center.x) * falloff(p.y - center.y) * v;
}

// signed noise
// return value in [-1, 1]
float snoise(vec2 p) {
  float result = 0.0;

  vec2 ll = floor(p);
  result += bump(p, ll + vec2(0,0));
  result += bump(p, ll + vec2(1,0));
  result += bump(p, ll + vec2(1,1));
  result += bump(p, ll + vec2(0,1));

  return result;
}

// void main() {
//   vec2 p = frag2World(gl_FragCoord.xy);

//   float f = snoise(p);
//   f = 0.5 + 0.5 * f;
//   gl_FragColor = vec4(vec3(f), 1.0);

//   // draw integer grid
//   if (isKeyToggled(Key_L))
//     if (abs(fract(p.x)) < dFdx(p.x) || abs(fract(p.y)) < dFdy(p.y))
//       gl_FragColor = vec4(1, 0, 0, 1);
// }