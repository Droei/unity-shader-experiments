#ifndef PERLIN_NOISE_2D_SG
#define PERLIN_NOISE_2D_SG

float2 PerlinHash2(float2 p)
{
    p = float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    );
    return frac(sin(p) * 43758.5453);
}

float2 PerlinGradient(float2 cell)
{
    float2 g = PerlinHash2(cell) * 2.0 - 1.0;
    return normalize(g);
}

float2 PerlinFade(float2 t)
{
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float2 g00 = PerlinGradient(cell + float2(0, 0));
    float2 g10 = PerlinGradient(cell + float2(1, 0));
    float2 g01 = PerlinGradient(cell + float2(0, 1));
    float2 g11 = PerlinGradient(cell + float2(1, 1));

    float2 d00 = local - float2(0, 0);
    float2 d10 = local - float2(1, 0);
    float2 d01 = local - float2(0, 1);
    float2 d11 = local - float2(1, 1);

    float v00 = dot(g00, d00);
    float v10 = dot(g10, d10);
    float v01 = dot(g01, d01);
    float v11 = dot(g11, d11);

    float2 f = PerlinFade(local);

    float vx0 = lerp(v00, v10, f.x);
    float vx1 = lerp(v01, v11, f.x);

    Noise = lerp(vx0, vx1, f.y);
}

#endif
