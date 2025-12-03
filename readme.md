![Banner image so I can push an images folder to main](images/Start.png)

# Unity Shader Experiments

This repository contains **Unity Shader Graph experiments**.

- **Main branch**: a clean template with minimal setup for testing shaders.  
- **Experiment branches**: individual shader projects based on the main branch.  

Branches can include shaders from tutorials or my own creations. The goal of this repository is to **document my experiments and track my learning progress**.

---

## Foreword

Source: https://www.youtube.com/watch?v=pFQ2-HFG_hY

This is gonna be a big one but honestly its such a golden source of info involving many interesting steps, new nodes and even HLSL!!!!
I'm both devastated and super excited to disect this lava shader!!!!

![Lava shader](images/1-lava-shader.png)

Well here are the nodes we'll be working with!

![Lava shader](images/2-lava-shader-nodes.png)
![Lava shader nodes](images/3-lava-shader-properties.png)

This might be the most intimidating/overwelming thing I've ever seen...
Ooh wait my girlfriend exists....
Anyway lets disect its intricacies by rebuilding the shader from the ground up and see what we can learn!

## Disecting the shader!

### Voronoi
So first we start with the core of this lava shader (The reason I choose to look for a lava shaders was because I just knew it would have these kind of golden insights! 
The voronoi pattern!!! I truly intend to disect this one as I inten to use Voronoi as the bottom layer of my procedural world generation algorithm, lets dive right into it!
For starters we used a HLSL script for the voronoi, so why don't we use the unity given voronoi... Well lets just check it out what it gives us!

![Voronoi in Unity](images/4-voronoi-in-Unity.png)

So we got our voronoi texture with some nice settings and we can also take out a flat surfaces
LETS GO AND TWIRL EM UP BABYYYY (I'm soo happy I took the time to understand UV's last week!!!

![Voronoi twirl in Unity](images/5-VORONOI-twirl.png)

Anyway as you can see in our earlier example we have lava lines on our shader and those are not being outputted.

![Lava shader](images/1-lava-shader.png)

So I'm all up for writing some voronoi code but in this case why? Can't we just smoothstep our way out of this problem?
Answer: Nope because for some reason vornoi's are balls not whatever shape is displayed???? Crazy!!!!

![Lava shader](images/6-smoothstep-voronoi.png)

So lets take a step back and learn how Vornoi works for this I'm taking Inigo Quilez on my left monitor!: https://iquilezles.org/articles/voronoise .
Two of the most common building blocks for procedural generation are noise and ofcorse there are many generations with Perlin noise (those blobs) to be the most relevant! And after that comes Voronoi noise which is the star of today's show!
Voronoi ofcorse has its own set of variantions but the concept is that it creates a grid and then places a point on a random position in each cell. In this article it says perlin noise also works with a grid but one has organisators and voronoi has those generators jittered somewhere on the grid? I don't really get it so lets maybe take another step back and figure out the difference between perlin noise and vornoi noise!

So first of all: Both perlin noise and Vornoi Noise work in a grid! But what is stored on a grid is different, so as you see below here is the core difference! 
Perlin noise is depicted with arrows, what do these arrows mean? Perlin noise takes each corner (named lattice point) and gives it a direction and magnitude, this decides in what direction the noise goes and how far its pulled (I'm just assuming the magnitude is some kind of normalised value) it then gets blended with all other noise values to get the blobs we know & love. Vornoi works with finding the closest feature point to each location (feature points are the random dots drawn on each sell in the grid), these feature points are the centers of the cell. A big plot twist tho, Vornoi doesn't actually use the grid like for example noise does, noise lives on its grid while Vornoi generates a grid to more easily check what points are generated nearby rather than with perlin noise where the grid is the foundation of the algorithm. So in short: Vornoi sets random dots on a place and uses a grid to help itself with finding other points in their neigborhood, basically if you take it away its concept can still work at a significant performance cost. While perlin noise relies on the intersections of the grid to find where to point its arrows to and create the blobs!

![Lava shader](images/7-vornoi-grid.jpg)
![Lava shader](images/8-perlin-noise-grid.png)

Haha it's not done yet, but almost! So we have our points and the unique data it contains so what happens with that data? So with perlin we use something named Lattice points and those arrows. SOOOOOOOOOOOOOOOOOO after a bit of looking I found such a wonderfull picture that really shows how these arros work! So As you can see the white value increases in what direction the arrow points for example at coordinate [x3,y1][x3,y2][x3,y3] you can see a beautifull long black blob as the arrow points point in the opposite direction meaning no gradient is being formed in that direction. Ofcorse to smooth things out there will be soft gradients going in the opposite direction I guess if an arrow points to [y0.5,x0.5] it'll  draw a gradient with the whitest point being 0.5 0.5 and the darkest being -0.5 -0.5 (the opposite) something like that I bet!

![Lava shader](images/9-perlin-noise-grid.png)

Vornoi is a little different! Lets see how it works! First of all Vornoi does not take an angle to create gradients like Perlin noise does!


Its very cool to see, when I set out on this journey I started with Inigo Quilez's articles but I ofcorse didn't really understand anything really or more like: I couldn't place his insight anywhere to make procedurally generated worlds... But now I'm quite a bit further in my journey and I see exacly why its sooo relevant, its such an amazing step forward to finally come back here and built more relevant understandings!




```hlsl
inline float2 randomVector (float2 UV, float offset)
{
    float2x2 m = float2x2(15.27, 47.63, 99.41, 89.98);
    UV = frac(sin(mul(UV, m)) * 46839.32);
    return float2(sin(UV.y*+offset)*0.5+0.5, cos(UV.x*offset)*0.5+0.5);
}

// Based on code by Inigo Quilez: https://iquilezles.org/articles/voronoilines/
void CustomVoronoi_float(float2 UV, float AngleOffset, float CellDensity, out float DistFromCenter, out float DistFromEdge)
{
    int2 cell = floor(UV * CellDensity);
    float2 posInCell = frac(UV * CellDensity);

    DistFromCenter = 8.0f;
    float2 closestOffset;

    for(int y = -1; y <= 1; ++y)
    {
        for(int x = -1; x <= 1; ++x)
        {
            int2 cellToCheck = int2(x, y);
            float2 cellOffset = float2(cellToCheck) - posInCell + randomVector(cell + cellToCheck, AngleOffset);

            float distToPoint = dot(cellOffset, cellOffset);

            if(distToPoint < DistFromCenter)
            {
                DistFromCenter = distToPoint;
                closestOffset = cellOffset;
            }
        }
    }

    DistFromEdge = 8.0f;

    for(int y = -1; y <= 1; ++y)
    {
        for(int x = -1; x <= 1; ++x)
        {
            int2 cellToCheck = int2(x, y);
            float2 cellOffset = float2(cellToCheck) - posInCell + randomVector(cell + cellToCheck, AngleOffset);

            float distToEdge = dot(0.5f * (closestOffset + cellOffset), normalize(cellOffset - closestOffset));

            DistFromEdge = min(DistFromEdge, distToEdge);
        }
    }
}
```