
float2 Hash2(float2 p)
{
    p = float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    );
    return frac(sin(p) * 43758.5453);
}

float2 PerlinVector(float2 cell)
{
    float2 g = Hash2(cell) * 2.0 - 1.0;
    return normalize(g);
}

void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float2 VectorValue00 = PerlinVector(cell);
    float2 VectorValue10 = PerlinVector(cell + float2(1, 0));
    float2 VectorValue01 = PerlinVector(cell + float2(0, 1));
    float2 VectorValue11 = PerlinVector(cell + float2(1, 1));

    float2 PixelDistanceFrom00Corner = local - float2(0, 0);
    float2 PixelDistanceFrom10Corner = local - float2(1, 0);
    float2 PixelDistanceFrom01Corner = local - float2(0, 1);
    float2 PixelDistanceFrom11Corner = local - float2(1, 1);

    float ProcessedValueForCorner00FromPixel = dot(VectorValue00, PixelDistanceFrom00Corner);
    float ProcessedValueForCorner10FromPixel = dot(VectorValue10, PixelDistanceFrom10Corner);
    float ProcessedValueForCorner01FromPixel = dot(VectorValue01, PixelDistanceFrom01Corner);
    float ProcessedValueForCorner11FromPixel = dot(VectorValue11, PixelDistanceFrom11Corner);

    float2 f = local * local * local * (local * (local * 6 - 15) + 10);

    float LeftToRightGradientAtPixelCell = lerp(ProcessedValueForCorner00FromPixel, ProcessedValueForCorner10FromPixel, f.x);
    float LeftToRightGradientAbovePixelCell = lerp(ProcessedValueForCorner01FromPixel, ProcessedValueForCorner11FromPixel, f.x);

    Noise = lerp(LeftToRightGradientAtPixelCell, LeftToRightGradientAbovePixelCell, f.y);
}

