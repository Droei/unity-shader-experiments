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

    float CellValue00 = PerlinHash2(cell).x;
    float CellValue10 = PerlinHash2(cell + float2(1, 0)).x;
    float CellValue01 = PerlinHash2(cell + float2(0, 1)).x;
    float CellValue11 = PerlinHash2(cell + float2(1, 1)).x;

    float2 PixelDistanceFrom00Corner = local - float2(0, 0);
    float2 PixelDistanceFrom10Corner = local - float2(1, 0);
    float2 PixelDistanceFrom01Corner = local - float2(0, 1);
    float2 PixelDistanceFrom11Corner = local - float2(1, 1);

    float ProcessedValueForCorner00FromPixel = dot(CellValue00, PixelDistanceFrom00Corner);
    float ProcessedValueForCorner10FromPixel = dot(CellValue10, PixelDistanceFrom10Corner);
    float ProcessedValueForCorner01FromPixel = dot(CellValue01, PixelDistanceFrom01Corner);
    float ProcessedValueForCorner11FromPixel = dot(CellValue11, PixelDistanceFrom11Corner);

    float LeftToRightGradientAtPixelCell = lerp(ProcessedValueForCorner00FromPixel, ProcessedValueForCorner10FromPixel, local.x);
    float LeftToRightGradientAbovePixelCell = lerp(ProcessedValueForCorner01FromPixel, ProcessedValueForCorner11FromPixel, local.x);

    Noise = lerp(LeftToRightGradientAtPixelCell, LeftToRightGradientAbovePixelCell, local.y);
}

