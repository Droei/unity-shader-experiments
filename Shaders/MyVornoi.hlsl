float2 hash2(float2 p)
{
    p = float2(dot(p, float2(127.1, 311.7)),
               dot(p, float2(269.5, 183.3)));
    return frac(sin(p)*100000.0);
}

void DoVornoi_float(float2 UV, out float solids, out float gradients, out float edges)
{
    float scale = 7.0;

    float2 cell = floor(UV * scale);

    float minDist = 1e9;
    float secondMinDist = 1e9;
    
    float2 winnerCell = 0;

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            float2 neighborCell = cell + float2(x, y);

            float2 featurePoint = hash2(neighborCell);
            float2 featureUV = (neighborCell + featurePoint) / scale;

            float d = distance(UV, featureUV);

            if (d < minDist)
            {
                secondMinDist = minDist;
                minDist = d;
                winnerCell = neighborCell;
            }
            else if (d < secondMinDist)
            {
                secondMinDist = d;
            }
        }
    }

    solids = hash2(winnerCell);
    gradients = minDist;
    edges = secondMinDist - minDist;
}

