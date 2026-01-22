float2 hash2(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*100000.0);
}

void DoVornoi_float(float2 UV, out float test)
{
    float scale = 7.0;

    float2 gridUV = UV * scale;

    float2 cell = floor(gridUV);

    float2 featurePoint = hash2(cell);
    float2 featureUV = (cell + featurePoint) / scale;
    
    test = distance(UV, featureUV);

}

