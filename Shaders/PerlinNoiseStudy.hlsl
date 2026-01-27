float2 PerlinHash2(float2 p)
{
    p = float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    );
    return frac(sin(p) * 43758.5453);
}

void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float2 f = local * local * (3.0 - 2.0 * local);

    float v0 = PerlinHash2(cell).x;
    float v1 = PerlinHash2(cell + float2(1, 0)).x;
    float v2 = PerlinHash2(cell + float2(0, 1)).x;
    float v3 = PerlinHash2(cell + float2(1, 1)).x;

    float ix0 = lerp(v0, v1, f.x);
    float ix1 = lerp(v2, v3, f.x);

    Noise = lerp(ix0, ix1, f.y);
}


