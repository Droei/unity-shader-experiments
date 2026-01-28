![Banner image so I can push an images folder to main](images/Start.png)

# Unity Shader Experiments

This repository contains **Unity Shader Graph experiments**.

- **Main branch**: a clean template with minimal setup for testing shaders.  
- **Experiment branches**: individual shader projects based on the main branch.  

Branches can include shaders from tutorials or my own creations. The goal of this repository is to **document my experiments and track my learning progress**.

---

# PERLIN NOISE

Lets cook us up some Perlin Noise, I have this one thing I want to really do with Perlin Noise for my thesis and with this I want to get that done!
The idea is that Perlin noise draws a vector (An Euclidean one I believe) on each left bottom point of a grid to create its blobs. I want to write a perlin noise algorithm that wil take a big grid and only draw vectors on the outer edges of the grid making it so I can get one big blob that is made up out of a 10x10 grid for example, I have not much of a clue how but that's what this deep dive will be for!!!! LETSGOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO

this page seems great for this! https://adrianb.io/2014/08/09/perlinnoise.html
So guess I'm gonna do what I do best: Read it, don't understand any of it and then just disect it bit by bit!

Guess first we'll have an example showing different ways to apply perlin noise in different dimensions
![](images/PelinNoise/1.png)

Altough I do know Minecraft is made with 3D perlin Noise, the picture shown here does not excentuate the 3D'ness of perlin noise (maybe I little on the mountain on the back) and if I remember correctly Minecraft at first was actually made with 2D perlin Noise the moment they started introducing caves tho they started using 3D Perlin Noise:
![](images/PelinNoise/2.jpg)
As this is the moment where depth is actually introduced into its procedrual world algorithm!

Perlin noise is the baseline of natural looking randomness as each value wil come from its previous value!

Alright so pretty clear. We take our uv which is basically just x0, y0 to x1, y1 and it has its blue dot which has an input coordinate, from previous I know this is probably 1 pixel that we calculate our thing for!
![](images/PelinNoise/3.png)

Now for each of these coordinates we generate a gradient vector. According to the article this defines a positive direction and a negative, so I guess what it points to is 1 and opposite side goes to 0.
And once again the pseudorandom stuff which basically means that we aren't using a random number for every pixel but always have the same for each coordinate in the grid which makes it possible to apply the same calculations for each pixel in each grid! 

really zoning out man I don't understand shit.
LETS GET TO PROGRAMMING
![](images/PelinNoise/4.png)

## PROOOOGRRAAMMMIIIIIIIINNGNGNGNGNGNG

AAALLLRIIIGGGHHHHTTT SOOO HERE WE ARE!!!!!
PERLIN NOISE CODE IN ITS MOST MESSY BARE FORM INH HLSL Lets disect this bad boy!

```hlsl
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
```

![](images/PelinNoise/5.png)

Lets get to disecting
![](images/PelinNoise/6.jpg)

First we take what we already know which is our pseudo random hash that we will use to get a random number for each pixel:

```hlsl
float2 PerlinHash2(float2 p)
{
    p = float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    );
    return frac(sin(p) * 43758.5453);
}
```

Alright now lets create some shader magic!
First of all lets start with a very barebones version of our shader!
Lets see what we can learn from cutting away everything but our first gradient function

```hlsl
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
    float gradient = PerlinHash2(cell);
    Noise = gradient;
}
```

so first off we ofcorse create cells. Our UV is currently not multiplied so its just a value between 0 and 1 so our UV will always be 0,0. With the voronoi I went deeper into the subject.

then our fancy gradient line which is just 1 value, as expected we loop through every pixel with exactly the same values so it will all be black!!! 
BUT!!! Once we zoom out by multiplying the size of our gradient we will see our random values increasing as we don't only have one cell anymore but instead working with multiple! Once again we went over that with Voronoi!

![](images/PelinNoise/7.png)

So yeah we aren't there yet ofcorse but now it should start to make sense again what's happening, we have all these random numbers being pulled based on in what grid the pixel resides and then we assign it a value based on its grid location.
Ofcorse there is no gradient or blobs yet but we are getting us some nice random colors to work with aka. cell-based randomness which as you suspect is pretty handy when it comes to random grids!
Think about it you have a game that has a grid of 100x100 what would be fastest assigning each grid a random value through math or a for loop? Honestly I don't know for sure cuz its still every pixel we're looping over but on the other hand doing it this way will be calculating it through the GPU instead of the CPU which ofocrse gives us less cores. Modern very high end cpu's give us 96 core's while modern very high end gpu's give us 21,760 processing cores which ofcorse makes a big difference! when it comes to processing highly parallelised tasks which ofc is not a CPU's job. So Idk its not a component or optimization deep dive but I think the GPU wins this one.

So what's next.... WELLL WE MAKE GRADIENTS!!!

```hlsl
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

    float v0 = PerlinHash2(cell);
    float v1 = PerlinHash2(cell + float2(1, 0));

    Noise = lerp(v0, v1, local);
}
```
![](images/PelinNoise/8.png)

As you can see, we now interpolate between two random cell values along the X axis.
Instead of each cell being a flat random value, the noise smoothly transitions from the current cell to its neighbor on the right.
![](images/PelinNoise/9.png)

So how did we do this. First what did we add? Well a lot so I'm not gonna mess around. Instead lets go over everything one by one!
```hlsl
    float2 cell = floor(UV);
    float2 local = frac(UV);
```

Firsy of all for each pixel we get its global coordinates and local ones.
The global ones are the cell itself and the local ones are the value within the cell! 
So what we do is we use floor to get the cell number as we understand by now and we use frac to get a value between 0 and 1 to get its position in the cell.
Quick example: a pixel in [3.7, 5,9]. Its cell value will be [3,5] and its local value will be [.7,.9] we basically just split it up!

Next up we do:
```hlsl
    float v0 = PerlinHash2(cell);
    float v1 = PerlinHash2(cell + float2(1, 0));
```
The first line is just as the last one ofcorse! where we just assign a random value to the cell.
In the second line we check what the value is on our right because float 1,0 is ofcorse [x1,y0] so if we have a pixel in [3,5] we will also get what random value we get for the [4,5] coordinate

Now we got our values its time to make it into a gradient: `Noise = lerp(v0, v1, local);` 
So what do we have right now!!!!
- v0: Our random grey value our cell received
- v1: The random grey value the cell on our right has received
- local: the position of our pixel in the grid (which is ofcorse a normalised value between 0 and 1)

So what does lerp do: It will put v0 on the outer left edge and v1 on the outer right edge. It will then use local to detemine the how far to the right the pixel is which it'll use to determine the value so:
- .01 is just completely v0
- .25 is mostly v0 and a bit of v1
- .5  is a perfect 50/50 between v0 and v1
- .99 is just completely v1

Now one more interesting thing. When counting with float2 in hlsl in float situaltions it'll default to its x value.
This ofcorse means that by specifically taking the x value and doing + float(0,1) instead of (1,0) we can do our gradient stuff over the y axis instead!
```hlsl
void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float v0 = PerlinHash2(cell).y;
    float v1 = PerlinHash2(cell + float2(0, 1)).y;

    Noise = lerp(v0, v1, local.y);
}
```

![](images/PelinNoise/10.png)

Now that we know how to lerp and need it to be in a 2D way its time to add our other sides and lerp em all together!
```hlsl
void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float v0 = PerlinHash2(cell).x;
    float v1 = PerlinHash2(cell + float2(1, 0)).x;
    float v2 = PerlinHash2(cell + float2(0, 1)).x;
    float v3 = PerlinHash2(cell + float2(1, 1)).x;

    float ix0 = lerp(v0, v1, local.x);
    float ix1 = lerp(v2, v3, local.x);

    Noise = lerp(ix0, ix1, local.y);
}
```

And honestly at this point its really getting somewhere now! This already can be used as noise!
I experimented a little and look at how decent it already looks

![](images/PelinNoise/11.png)
A lot of potential magic to be added

But now back to business! We now have our 2D gradients rather than in one direction... So what changed?

First of all we added some new values, we have our current value, our right value, our up value and our right up value... As you can see, no negatives
We are working with:
```
[0][X][X]
[0][X][X]
[0][0][0]
```


So why do we only take these values for our gradient. I feel like our 0,1 uv'd perlin noise explains it best!
![](images/PelinNoise/12.png)

As you can see there is one black dot there, when we do our pseudo random algorithm it'll always start with 0 so every [0,0] cell has always been black, this is how our random works but also is handy to have a predictable reference.
As you can see it starts at the left bottom corner, this is our [0,0] position, every grid when we normalise its values will have its 0,0 in the left corner. So we want to make a grid from there... Well what do we look at? 
YEEEEESSS every direction we should check for which wich ofcorse is: Right, UP and Right UP!!! We don't have to check behind us for this grid, its up to the grids that see is from behind to create the gradients in our grid.
Checking what gradiennts that gotta be created are from our back is for [-1,0][-1,-1][0,-1]!!!

Alright so now that we know the value of the grids that matter we just lerp em up! 
```hlsl
    float ix0 = lerp(v0, v1, local.x);
    float ix1 = lerp(v2, v3, local.x);
```

And this one might be confusing so lets disect it. We already know the first line, it just lerps left to right. But what is the second line doing?
```
[0][X][X]
[0][0][0]
[0][0][0]
```

Now that doesn't make much sense right now... So the first lerp lerps from our grid to the right grid giving us our gradient, the one we had last time.
Then we do the same for the data above us. Ofcorse this data is not used as our pixels don't appear there...

BUT OFCORSE this isn't our output!
But for the sports lets quickly check what we get!
![](images/PelinNoise/13.png)
This one we know, what will ix1 give us, I believe nothing at all.
Ooh well will you look at that!!!! It just moves our rows 1 down!
![](images/PelinNoise/14.png)
Which actually does make sense! So we have our pixel that needs a value. And we lerp that to get the gradient but even though we are at 0,0 nothing stops us from looking at [4855421,444545214] and using that to determine our pixels value.
Honestly it makes sense but sometimes the raw "logic" of shaders still gets lost on me, guess it'll get better with experience.

Anyway we got our gradient and we now also know what is happening above us!
```hlsl
    Noise = lerp(ix0, ix1, local.y);
```

So now we just lerp our way through it over the Y axis ofcorse! we take our bottom gradient and our top gradient that we can output as you saw and use both 1D values because its just a line in reality and merge them together creating these nice blurry 2D Squared! Simply amazing!

So we already have a random value for each grid
and we got the ability to draw gradients between every grid,

Well ofcorse we wanna go towards our good ol, blobs! So how will we pull this. There's a few ways we could do this.
A shortcut would be to smooth up our local values by adding:
```hlsl
    float2 f = local * local * (3.0 - 2.0 * local);
```

![](images/PelinNoise/15.png)

Basically this is the math way of doing an ease-in ease-out type of calculation.
Lets disect for the grind! But after that we will do it the right way!

We start with local which is ofcorse our position within the grid.
First we hit em with the `local * local`, the result of this is that it will decrease lower values and increase higher values. In a graph this means ofcorse that at lower values like 0.01 it grows very slow while very fast at .9 for example! Makes sense right because .01 \* 0.01 = an increment of 0.0001 while .9 \* .9  increments by 0.81 which explains how we make increments go higher the further we go to the left where our normalised x value goes higher.
then we multiply our ease in with out ease out ofcorse.... So what do we have for ease out? `(3.0 - 2.0 * local)` 

So to really illustrate this lets take it with and without because honestly it might not make sense at first.
With that line
![](images/PelinNoise/16.png)
Without:
![](images/PelinNoise/17.png)
As you can see there's a lot of sharp edges aroundour squares now and you can clearly identify them. 
That's where `(3.0 - 2.0 * local)` comes in. Just so we are on one line what this does.
- 3 - 2 \* 0  = 3 - 0 = 3
- 3 - 2 \* .25  = 3 - 0.5 = 2.5
- 3 - 2 \* .5 = 3 - 1 = 2
- 3 - 2 \* .75 = 3 - 1.5 = 1.5
- 3 - 2 \* 1  = 3 - 2 = 1

So what does this mean? Well lets now multiply those values with our `local * local`
- 0 \* 3 = 0
- .0625 \* 2.5 = 0.15625
- .25 \* 2 = .5
- .5625 \* 1.5 =  0.84375
- 1 \* 1 = 1

As you can see, the local value is being adjusted to smoothened. Best illustrated by when local = .25 and .75, you can clearly see how it goes .1 lower and with .75 going .1 higher already showing how its consistently smoothening out towards the end speeding up around .5 and slowing down towards the end! No fancy functions just raw math and logic!
We can ofcorse ease it by increasing the amount of eases, a real brutal example is this: `float2 f = local * local * local * (local * (local * 6 - 15) + 10);` I know but lets get back to making perlin noise now because I sweated way to long on understanding this one!
But ofcorse so you remember!!! We will use something similar later!!!!!

Alright lets introduce some new values and see what they do:
```hlsl
void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float v0 = PerlinHash2(cell).x;
    float v1 = PerlinHash2(cell + float2(1, 0)).x;
    float v2 = PerlinHash2(cell + float2(0, 1)).x;
    float v3 = PerlinHash2(cell + float2(1, 1)).x;

    float2 d00 = local - float2(0, 0);
    float2 d10 = local - float2(1, 0);
    float2 d01 = local - float2(0, 1);
    float2 d11 = local - float2(1, 1);

    float v00 = dot(v0, d00);
    float v10 = dot(v1, d10);
    float v01 = dot(v2, d01);
    float v11 = dot(v3, d11);

    float ix0 = lerp(v00, v10, local.x);
    float ix1 = lerp(v01, v11, local.x);

    Noise = lerp(ix0, ix1, local.y);
}
```
![](images/PelinNoise/18.png)

And honestly I really wanna get them some new names so shits clearer cuz holy shit tf is this.
So I always am very religious over naming. I feel like if you can't figure write what a function does in it's name ur probably writing a shitty function, and now I'll apply this logic to the code. It'll be way easier to understand what each line does when its actually written in something that describes it's functionality in the current code (I will also change this accordingly as new code comes in, we're almost there tho!)

![](images/PelinNoise/19.jpg)

```hlsl
void PerlinNoise2D_float(float2 UV, out float Noise)
{
    float2 cell = floor(UV);
    float2 local = frac(UV);

    float CellValue00 = Hash2(cell).x;
    float CellValue10 = Hash2(cell + float2(1, 0)).x;
    float CellValue01 = Hash2(cell + float2(0, 1)).x;
    float CellValue11 = Hash2(cell + float2(1, 1)).x;

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
```

Now lets disect our code so we can clearly see where we at!!!!
Lets say we are a lonely pixel residing at [3.8, 5.7], from here on we are gonna calculate it all!

First we get a random value based on our cells and the relevant ones around it, as we already know 3,5 4,5 etc etc

Now here starts some new magic!1
We will now get the distance from each corner in the cell that our pixel resides!
So our pixel resides in the cell 3,5 at locatoin .8,.7.
Lets hit it with `float2 PixelDistanceFrom10Corner = local - float2(1, 0);`
The result will be [-.2,.7]

So now we have the dot product between that distance between the random value of cell 4,5 and the distance our pixel has to it. 
Lets say that cell has as value .4 lets do our dot product. We have dot(.4, [-.2;.7]) So what do we do with these? Alright well we do this.
In a dot product we first add -.2 and .7 together and we get .5. Then we multiply it by .4 to get .2! Which ofcorse means the result of our distance to that corner is: .2! This is the weighted contribution of corner [1,0] to the pixel’s value

So Basically just to follow up and clearify! Each corner has a contribution value we are calculating there for each cell once (4 times as you see) This value is determined by the dot product of the value of the corner that is connected to the cell we are connected to and the distance of the pixel from that cell. We basically ask "how much do we want this corner to influence the pixel's final value? Later we'll work with vectors and magnitudes to really clean up the random values to vectors that decide on a direction and magnitude!

I asked ChatGPT to generate it in numbers for me so any doubt can finally leave my mind.

```hlsl
CellValue00 = 0.3  // bottom-left corner [0,0] → cell [3,5]
CellValue10 = 0.5  // bottom-right corner [1,0] → cell [4,5]
CellValue01 = 0.2  // top-left corner [0,1] → cell [3,6]
CellValue11 = 0.8  // top-right corner [1,1] → cell [4,6]

PixelDistanceFrom00Corner = local - [0,0] = [0.8, 0.7]
PixelDistanceFrom10Corner = local - [1,0] = [-0.2, 0.7]
PixelDistanceFrom01Corner = local - [0,1] = [0.8, -0.3]
PixelDistanceFrom11Corner = local - [1,1] = [-0.2, -0.3]

ProcessedValueForCorner00FromPixel = 0.3 * (0.8 + 0.7) = 0.3 * 1.5 = 0.45
ProcessedValueForCorner10FromPixel = 0.5 * (-0.2 + 0.7) = 0.5 * 0.5 = 0.25
ProcessedValueForCorner01FromPixel = 0.2 * (0.8 + -0.3) = 0.2 * 0.5 = 0.1
ProcessedValueForCorner11FromPixel = 0.8 * (-0.2 + -0.3) = 0.8 * -0.5 = -0.4
```
Also interesting to note is that -0.4 as a result will actually give the opposite result 

Which is ofcorse assigned when we start lerping those bad boys!!!!
```hlsl
    float LeftToRightGradientAtPixelCell = lerp(ProcessedValueForCorner00FromPixel, ProcessedValueForCorner10FromPixel, local.x);
    float LeftToRightGradientAbovePixelCell = lerp(ProcessedValueForCorner01FromPixel, ProcessedValueForCorner11FromPixel, local.x);

    Noise = lerp(LeftToRightGradientAtPixelCell, LeftToRightGradientAbovePixelCell, local.y);
```

And now we ofcorse do what we've been doing all this time, which is ofcorse make gradients out of our values.
Honestly its the same as always so I can't go into detail again what it did.

So now we need to add one more thing, and that is our “arrows” or vectors.
These vectors allow pixels to be influenced more strongly in certain directions than others.
In the previous version, each corner influenced pixels uniformly in all directions, but now each corner has a preferred direction, giving some influences more priority than others.
This directional influence is why, in the before-and-after comparison, we see certain dark regions being pulled together and connected, while others become thinner. The noise becomes more coherent because corner influences can reinforce or cancel each other depending on direction, resulting in smoother, more natural-looking patterns.
![](images/PelinNoise/18.png)
![](images/PelinNoise/20.png)

This is where it becomes clear that Perlin noise doesn’t increase the strength of influence, it changes its direction.

So now what did we add?
Not much honestly.

```hlsl
float2 PerlinVector(float2 cell)
{
    float2 g = Hash2(cell) * 2.0 - 1.0;
    return normalize(g);
}
```

```hlsl
    float2 VectorValue00 = PerlinVector(cell).x;
    float2 VectorValue10 = PerlinVector(cell + float2(1, 0));
    float2 VectorValue01 = PerlinVector(cell + float2(0, 1));
    float2 VectorValue11 = PerlinVector(cell + float2(1, 1));
```

I added a new function which I basically used to transfer this random value to a vector. And I changed our cellValue to VectorValue and made it a float2 because now it will actually be a vector2 rather than a singular value!.
So what is happening in perlinVector?

Alright so this is where all those perlin noise arrows come from so believe it or not but this lil bro is a BIIIIIG deal.
![](images/PelinNoise/21.jpg)

Lets say we have a pixel inside cell [3,5] and we hash it and guess it returns us with [0.83, .21] nothing new here, this is the first part of our PerlinVectorFunction.
Then here's where the magic happens. It remaps the range of the arrow. Instead of only being able to point in the opposite direction of the gradient is it now also able to turn around, 360 degrees!
`* 2.0 - 1.0` how is this that powerfull to give soo much flexibility you might ask? Well first of all by now you should know that one simple mathmatical thingy can open up crazy new possibility's as simple as this line! You gotta know that by now! But its ok cuz I was also very curious hahaha.

Anyway lets say we get from our hash [0,1] if we do this \* 2 - 1 we get [-1, 1] which masically means the arrow points to the left and up! Now in our example of [0.83, .21] \* 2 - 1 we get as a result [.66,-.58] pointing almost at 5 o'clock I believe.
![](images/PelinNoise/22.jpg)

Now we normalise our value, and this I find a bit tricky `return normalize(g);` normalising is something that always comes back but never makes sense on first try to me.
But basically we normalise to equalise the playingfield of each corner, by ensuring that the square root of (x² + y²) is 1! this way only direction of the influence matters and nothing else, if we don't do this some values will overlap with stronger influences making the whole noise inconsistent!

Alright lets just write out a normalising algorithm cuz JEEEEEEEEEESSHHHH.
So this is our value [0.66, -0.58] good ol' x and y coordinate nothing to weird!
Then you take the square root of both to the power of 2, or basically:
- `sqrt(x*x + y*y)` or `sqrt(0.66² + (-0.58)²)`
- `sqrt(0.4356 + 0.3364)`
- `sqrt(0.772)`
- `0.878`

.878 is the length of our vector and the result of doing `sqrt(x² + y²)`, but ofcorse its not 1 so then we divide those initial values by .878 to get [0.75,-0.66] which has a square root of (x² + y²) is 1.
meaning that we can be sure that its pull will be consistent and equalised! This is how perlin noise has its consistency!

Ending us with somewhat blobby looking noise!!!! 
![](images/PelinNoise/23.png)

AND NOW AT LAST WE ARE BACK WITH SOME PREVIOUS CODE!!!
Because we will once again wanna ease it in and out: `float2 f = local * local * (3.0 - 2.0 * local);` I'm not gonna repeat too much here because my girlfriend is waiting, been clutching this one out in the last 12u and its 1:30am!
But now its all about easing things to determine how hard you want them to connect, there's many easing functions and honestly it would be too much to explain all of them but I will go with this one:  `float2 f = local * local * local * (local * (local * 6 - 15) + 10);`
Basically just the same but the standard easing used in perlin noise! 

Below is an example between the 2 easing lines

`float2 f = local * local * (3.0 - 2.0 * local);`
![](images/PelinNoise/24.png)
`float2 f = local * local * local * (local * (local * 6 - 15) + 10);`
![](images/PelinNoise/25.png)

I don't wanna get all hasty so I'm just getting back to this after, I think she'd get mad if I don't come over now....
Being a boyfriend for a demanding but lovely girl and a massive nerd is a bigger challenge than learning shader math....
Now she's sending me this gif because she had to wait 30 more min.... I love her
![](images/PelinNoise/26.gif)

Anyway back!!! Lets finish this one! So there isn't much other than just making sense of the last part! Which I once again did thanks to the magical cuddles from my girlfriend!
so we have our local value which is basically our location in our cell this just linear usually and its used in our lerp functions to determine how much of each value we take, ofcorse the closer to 0 the more we take from the first value and the closer to 1 the more we take from the second value.

This is normally linear perfectly based on the location making everything linear without anything smoothness to it but these change that smoothing out start and finish (in depth on how was earlier) `float2 f = local * local * (3.0 - 2.0 * local);` which manipulates what is lerped as the current pixel position.

Well that's it I understand it now, but damn what a banger grind this was!!!! Now I hope to tomorrow combine this research with my previous voronoi to write my dream procedural world generation baseline!!!! 
SUPER EXCITIIIING!!!

```hlsl

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


```

More sources to dive into!
https://mrl.cs.nyu.edu/~perlin/noise/
https://mrl.cs.nyu.edu/~perlin/paper445.pdf
