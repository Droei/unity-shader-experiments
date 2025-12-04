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

Vornoi is a little different! Lets see how it works! First of all Vornoi does not take an angle to create gradients like Perlin noise does! First of all Vornoi has no gradient stored or generated anywhere unline Perlin noise! Instead Vornoi noise is purely built up out of feature points (those random points) and distances between your sample point and feature point. So just to clearify a sample point is literally just any value where you want to know the value of the noise. For example noise(x, y) returns 1 random value of the noise on that position, the x,y is the sample point. The feature point on the other hand are those random dots that appear. So what do they do how do they relate? SOOOOOOOOOOOOOOOOOO I'm gonna cook this one up in photoshop so I can visualise it! Nvm I'll use Illustrator.

![Lava shader](images/10-vornoi-explanation.png)

Anyway SO HERE YOU HAVE VORNOI NOISE!!!! This is what you get:
- Feature points: Each grid got a random feature point, this is just 1 pixel/point on in each grid!
- Sample points: Every pixel that is being evaluated so basically just a position that's being inputted in the vornoi (as you can see vornoi noise is not that gradient like stuff you would expect yet)
- Dinstances: every distance between your sample point and all feature points
- Vornoi value: this is the distance from the sample point to the closest feature point, usually that's the one that the grid is in but it's definitly not uncommon for a sample point to have a feature point in another grid!

So **this is vornoi noise** no gradients or polygons or anything this is what we get, but with this data we can make all those fancy sell things we want to make! So what really happens, we have all this data, how do we make a little sharp blob? First we get the closest feature point, it'll check all 9 grid cells around the sample points and collecdt the distances, then we get the minimum distance! 

Alright I basically completely got lost for a bit. In my previous example I had 1 sample point to calculate, but this actually happens for every coordinate in a grid, meaning if each grid has 100 coordinates there will be 99 sample points and 1 feature points! each coordinate will see its distance to its closest feature point and will be assigned a number, furthest away will receive a 1 while closest by will be 0, that's ofcorse why everything starts as a black perfect circle and as you go further away it'll change in our cell like structures because then other feature points will start being closer meaning the sample points will start looking at them for distance! and that's how we get those vornoi tiles! So we will manually assign a max radius so basically if we set the max of .5 if we keep increasing away from the feature point we can clamp everything to 1 over .5 so we will have our gradient and everything beyond the value of .5 will clamp to 1 giving us a fixed radius. Another way to have it be black at the start and white at the edge is by doing `currentFeaturePoint/closestFeaturePoint` this value we can then use to find the outer most value we can then do `sampleValue = normalise(distanceFromClosestFeaturePoint, currentFeaturePoint/closestFeaturePoint)` this way instead of just basing the sample points value on the distance between it and the feature point closest it'll always normalise its value between 0 and 1 meaning the furthest possible distance away will always be 1 (even if its maybe 0.75 or smth) and closest will always be 0!!! I don't know how clear it is but it is to me now!

Now Imma hit the gym... I ate soo much sugar to get through this one omfg, I'm soo happy I understand it now but this stuff was way more complex than I thought, but now I have all the tools to disect the next code!!!!

Its very cool to see, when I set out on this journey I started with Inigo Quilez's articles but I ofcorse didn't really understand anything really or more like: I couldn't place his insight anywhere to make procedurally generated worlds... But now I'm quite a bit further in my journey and I see exacly why its sooo relevant, its such an amazing step forward to finally come back here and built more relevant understandings!

Alright now I'm very excited to finally get to disecting the code!!!
But honestly I prefer to not just take the code and go over each line, instead I will try to  write my own Vornoi HLSL code! Here we go!!!


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

So here we go this is where we are for now!
Seems like you always need to add _float on the back and for example doing out float2 and setting name to _float2 does not work but hey at least we seeing light in the graph editor!
```hlsl
void DoVornoi_float(float2 UV, out float test)
{
    test = 1.0;
}

```

![Own Vornoi 1](images/11-doVornoi-1.png)

So what do we have right now, we sent in an uv (our grid btw, this is where we will draw dots in) and test for out. I don't know how I can out anything else but I believe float will be fine and I'll figure out other outputs when its relevant! So now guess I'll try to disect from the above code what places random dots on the grid. So I'm currently reading up on Inigo Quilez on SmoothVornoi, I feel like it'll be a good place to start. The above code is also looking to introduce egdes etc but honestly I don't want to bother with that, when trying to learn it is important to not go to fast, you can achieve more by aiming to: ONLY HAVE DOTS (Feature points) over anything!

![Own Vornoi 1](images/12-lets-cook.gif)

First we want a random number generator! So throughout my shader journey I've seen some cool ways of generating pseudo random values so the basic concept is that you squash a sine wave on top of eachother so hard it returns seemingly random values as there will be points spawned all over the place! This is a great source: https://thebookofshaders.com/10/

![Random](images/13-pseudo-random.png)
![Random](images/14-pseudo-random.png)

Now this example is only in one dimension so guess what? Yeah ofcorse we are not getting at all what we wanted! (I have some other code down already to visualise this well, I already set up a very basic grid that shows the dots in a vornoi way. Ikr, couldn't believe my eyes that I'm actually going forward with this lmfao.

```hlsl
	float2 hash2(float2 p)
	{
		return frac(sin(p) * 10000.0);
	}
```

![Random](images/15-pseudo-random-result.png)

So now we need to make this fancy thing work with 2D values. For this the dot() function will be doing some heavy damn lifting. So first of all, what does Dot() do? Well very simple actually it multiplies each component and then adds them. So basically if we have: `dot( float2(x, y), float2(A, B) )` it'll do `x * A + y * B` simple enough right? Basic math. But ofcorse we are working with a grid so ofcorse x,y will be different, if our uv grid is 12 it'll for each grid position get the dot product ofcorse. So when we feed the values of these completely messed up lines in a sine we will get some kind of tv noise. Because once again its not just being messed up up and down but also left and right as we gave both sides a big messy bunch of values!

![Random](images/16-tv-noise.png)

So now to put in into hlsl, is almost the same as the GLSL above! We first do the float2 multiplication (in GLSL you can just multiplay a vec2 with vec2 in HLSL they need to be split up). So we use some seemingly random numbers to multiply our grid pos with! I had MrGPT choose them for me but basically to prevent any weirdness MrGPT made sure they:
- Are not multiplies of eachother
- Are not small
- Avoid obvious patterns (Making sure they don't line up in any obvious way)
- Make sure the dot products are far apart

```hlsl
	float2 hash2(float2 p)
	{
		p = float2(dot(p, float2(127.1, 311.7)),
				   dot(p, float2(269.5, 183.3)));
		return frac(sin(p)*100000.0);
	}
```

We then bash this back in our previous sin but this time our values are actually already mixed up before they get jittered the shit out of them creating our beautifull random dot positions!

![Working random positions](images/17-working-balls.png)

Now time for bed, I have a physical board game to pitch tomorrow! (Honestly I never thought I'd enjoy making physical games but honestly my teachers passion is really captivating and I started really to appreciate it like an artform, I always grind sooo hard to built my technical foundation but making a physical game is just all about the idea without all the headacackes of trying to rewrite a Vornoi and stuff, its been a great journey so far becoming a game designer!)

PS. frac makes all values positive so a sine goes in a circle between -1 and 1 but frac makes everything under 0 -> positive so that's why we only get positive values in out hash2