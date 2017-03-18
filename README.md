# Approach to improve ODM

* ODM creates orthophotos mainly through projecting original images onto the mesh generated. This approach can be significantly improved through homography prinicples used for orthophoto generation. OpenCV functions [`getPerspectiveTransform`](http://docs.opencv.org/2.4/modules/imgproc/doc/geometric_transformations.html#getperspectivetransform) and [`warpPerspective`](http://docs.opencv.org/2.4/modules/imgproc/doc/geometric_transformations.html#warpperspective) can be used in conjunction with [`ODM orthophoto module`](https://github.com/OpenDroneMap/OpenDroneMap/blob/master/modules/odm_orthophoto/src/OdmOrthoPhoto.cpp) to improve quality of orthophotos. As explained in paper authored at ETH Zurich, [True-orthophoto generation from UAV images: Implementation of a combined photogrammetric and computer vision approach](http://search.proquest.com/openview/b414ec24f42a03968ab8826dd3a0425a/1?pq-origsite=gscholar&cbl=2037681), combining both cv and photogrammetric approaches will result in better orthophotos.

# Time estimate 
Automatically setup orthophoto resolution - 1 day

Add masking techniques to fix moving objects - 4 days

Improve point cloud to fix protruding objects - 7-10 days

Fix oblique images - 7 days

Add smoothing and sharpening methods for vegetation issues - 3 days

Add blob detection functions to remove ghost effects - 3 days

Tune feature matching for distorted roads - 2 days

Improve texturing and add hole filling algorithms to fix gaps in orthophotos - 4 days

Add denoising functions - 3 days

Buffer time - 7 days


Adding machine learning algorithms as new features - It's better to work on this after we have reasonable quality orthophotos.

## Orthophoto resolution
Orthophoto resolution is set to `20.0 pixels/meter` in ODM by default, but Ground Sample Distance (GSD) is closely related to camera specifications (focal length, sensor width and resolution) and altitude of the flight. These details can be automatically extracted from EXIF data of the images, and GSD can be calculated using formula (according to [reference book](https://books.google.com/books?id=f3zUKZZ_WjMC&pg=PA30&dq=%22ground+sample+distance%22&lr=&as_drrb_is=q&as_minm_is=0&as_miny_is=&as_maxm_is=0&as_maxy_is=&as_brr=0&ei=57prSuTtN47ilASH0dlQ#v=onepage&q=%22ground%20sample%20distance%22&f=false) and [Pix4D website](https://support.pix4d.com/hc/en-us/articles/202559809#gsc.tab=0)):

                    GSD = (sensor width * flight altitude * 100) / (focal length * image width)  cm/pixel

For our dataset, GSD is calculated to be around `2.93 cm/pixel`, so the orthophoto resolution will be around `33.0-35.0 pixels/meter`. So an optimal run-time parameter to set will be `--orthophoto-resolution 34`.

Another factor that directly affect Orthophoto quality is resize difference of images. If we set `--resize-to` to an integer less than `2000`, main features will be extracted, features of trivial elements are not matched, and the point cloud will different. 

## Run-time parameters to tweak
In addition to parameters mentioned above, for our dataset, we can tweak the following run-time parameters to improve quality of orthophoto:
* --odm_texturing-textureResolution
* --odm_texturing-textureWithSize
* --pmvs-csize
* --pmvs-threshold
* --use-opensfm-pointcloud

The orthophoto created can be found in the link https://www.dropbox.com/s/f9vfnbopmra2xie/odm_orthophoto.tif?dl=0


## Issues in the images

### Moving objects
In our orthophoto, moving cars are distorted. [Masking techniques](http://info.photomodeler.com/blog/tip-75-masking-to-improve-orthophoto-and-3d-textures/) are proven to reduce distortion due to moving objects. Opencv provides a good set of [mask operations] (http://docs.opencv.org/2.4/doc/tutorials/core/mat-mask-operations/mat-mask-operations.html), we can implement them to improve distortion due to moving objects. 

Moving cars          | Distorted moving cars 
:-------------------------:|:-------------------------:
![moving_cars1](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/moving_cars1.JPG "distorted moving cars ") | ![moving_cars2](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/moving_cars2.JPG "")

### Protruding objects
Protruding objects in orthophoto are caused from radial distortion of elements in the point cloud. These can be resolved by improving various [point cloud reconstruction techniques](http://www.sciencedirect.com/science/article/pii/S0965997811001128). 

### Oblique elements
There are various rectification techniques to specifically handle oblique elements as detailed in [publication] (http://www.univie.ac.at/aarg/files/03_Publications/AARG%20News/AARG%20News%2044.pdf#page=12). A good Digital Terrain Model (DTM) is critical in handling oblique elements, [PDAL](http://www.pdal.io/)/[GRASS](https://grass.osgeo.org/) can be used to improve DTM.

Distorted builiding     | Polygon representation of building
:-------------------------:|:-------------------------:
![oblique1](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/oblique_image_1.JPG "distorted building") | ![oblique2](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/oblique_image_2.JPG "polygon representation of building")

### Melting/Watered elements
Computer Vision techniques generally face difficulties in representing textures of vegetation, this problem can be improved by augmenting the image with color balancing techniques. 

Vegetation melted       | Distorted and melted vegetation
:-------------------------:|:-------------------------:
![vegetation1](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/vegetation1.JPG "melted vegetation") | ![vegetation2](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/vegetation2.JPG "")

### Ghost effect
Ghost images or double mapped areas in the image can be removed by occlusion detection mechanisms. This can be achieved through opencv, mainly with [blob detection functions](http://docs.opencv.org/trunk/d0/d7a/classcv_1_1SimpleBlobDetector.html)

Ghost Image     | Distorted ghost Image 
:-------------------------:|:-------------------------:
![ghost_image1](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/ghost_image1.JPG "Ghost image") | ![ghost_image2](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/ghost_image2.JPG "")

### Road 
In our orthophoto, roads are not joined correctly, this is mainly due to inadequate feature matching. ODM sets `--min-num-features` to `4000`, if we set this run-time parameter to `8000`, the feature matching will be more robust and this problem might get corrected.

Distorted road     |  
:-------------------------:|:-------------------------: 
![](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/distorted_road.JPG)

### Gaps/Holes in orthophoto

Gaps in orthophotos are caused by ODM due to texturing models used. [This paper] (http://www.int-arch-photogramm-remote-sens-spatial-inf-sci.net/XL-5-W4/131/2015/isprsarchives-XL-5-W4-131-2015.pdf) proposes a method to automatic texturing by combining a 3D model with texture coordinates and orthographic textures, resulting in filling of most gaps in orthophotos. 
![textures in odm](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/textures_in_odm.png)

Texturing gaps | Incomplete hole filling
:-------------------------:|:-------------------------: 
![gap1](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/gap_orthophoto.JPG "Gaps in texturing") | ![gap2](https://github.com/digvijayky/drone-improvement-approach/blob/master/example_images/gap_orthophoto2.JPG "")

There are many existing hole-filling algorithms that can be used to fill holes in orthophotos, a good algorithm is explained by the authors of the open source software [zpr](http://zpr.sourceforge.net/) in paper [A simpler method for large scale digital orthophoto production] (https://pdfs.semanticscholar.org/4007/b15450eb87b579122c3a2056b210f2b2541b.pdf). ODM implements a naive hole-filling algorithm, but it can be made more robust by adopting the source code for the following zpr hole-filling algorithm.

```
void holefill(char* input, char* output, int threshold)
{
// Capture wrong threshold calls
    if ((threshold < 0) || (threshold > 7))
    {
        cerr << "Error: HoleFilling Threshold must be between 0 and 7 pixels./n"
        << "Aborting HoleFilling algorithm." << endl;
        return;
    }
    int totalpixelscolored = 0;
    //Load Input Image
    IplImage* img1 = 0;
    if ((img1 = cvLoadImage( input, -1)) == 0)
    {
        cerr << "Error: Cannot open the specified input file: " << input << endl;
        return;
    }
    // Display info start.
    cout << "Performing HoleFilling algorithm on file " << input
    << " with a " << threshold << " pixel threshold. Saving to file " << output << endl ;

    RgbImage imgA(img1);
    int width = img1->width -1;
    int height = img1->height -1;

    //Create Target Image
    IplImage* img2=cvCreateImage(cvSize(width,height),IPL_DEPTH_8U,3);
    RgbImage imgB(img2);
    //The pixel we check
    RgbPixelInt mypixel;
    //7 Pixels around our middle pixel
    // 5 6 7
    // 3 M 4
    // 0 1 2
    RgbPixelInt nearpixel[8];
    //near black pixel counter
    int blackpixels = 0;


    //go through all pixels i, j except the ones on the image perimeter
    for (int i = 1; i < width-1; i++)
    {
        for (int j = 1; j < height-1; j++)
        {
            //read the pixel
            mypixel.b = imgA[j][i].b;
            mypixel.g = imgA[j][i].g;
            mypixel.r = imgA[j][i].r;

            if ((mypixel.b == 0) &&
                    (mypixel.g == 0) &&
                    (mypixel.r == 0))
            {
                mypixel.isBlack = 1;
            }
            else
            {
                mypixel.isBlack = 0;
            }

            //if the pixel is black, check all 7 near pixels
            if (mypixel.isBlack)
            {
                blackpixels = 0;
                nearpixel[0].b = imgA[j-1][i-1].b;
                nearpixel[0].g = imgA[j-1][i-1].g;
                nearpixel[0].r = imgA[j-1][i-1].r;
                if ((nearpixel[0].b == 0) &&
                        (nearpixel[0].g == 0) &&
                        (nearpixel[0].r == 0))
                {
                    nearpixel[0].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[0].isBlack = 0;
                }
                nearpixel[1].b = imgA[j-1][i].b;
                nearpixel[1].g = imgA[j-1][i].g;
                nearpixel[1].r = imgA[j-1][i].r;
                if ((nearpixel[1].b == 0) &&
                        (nearpixel[1].g == 0) &&
                        (nearpixel[1].r == 0))
                {
                    nearpixel[1].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[1].isBlack = 0;
                }
                nearpixel[2].b = imgA[j-1][i+1].b;
                nearpixel[2].g = imgA[j-1][i+1].g;
                nearpixel[2].r = imgA[j-1][i+1].r;
                if ((nearpixel[2].b == 0) &&
                        (nearpixel[2].g == 0) &&
                        (nearpixel[2].r == 0))
                {
                    nearpixel[2].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[2].isBlack = 0;
                }
                nearpixel[3].b = imgA[j][i-1].b;
                nearpixel[3].g = imgA[j][i-1].g;
                nearpixel[3].r = imgA[j][i-1].r;
                if ((nearpixel[3].b == 0) &&
                        (nearpixel[3].g == 0) &&
                        (nearpixel[3].r == 0))
                {
                    nearpixel[3].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[3].isBlack = 0;
                }
                nearpixel[4].b = imgA[j][i+1].b;
                nearpixel[4].g = imgA[j][i+1].g;
                nearpixel[4].r = imgA[j][i+1].r;
                if ((nearpixel[4].b == 0) &&
                        (nearpixel[4].g == 0) &&
                        (nearpixel[4].r == 0))
                {
                    nearpixel[4].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[4].isBlack = 0;
                }
                nearpixel[5].b = imgA[j+1][i-1].b;
                nearpixel[5].g = imgA[j+1][i-1].g;
                nearpixel[5].r = imgA[j+1][i-1].r;
                if ((nearpixel[5].b == 0) &&
                        (nearpixel[5].g == 0) &&
                        (nearpixel[5].r == 0))
                {
                    nearpixel[5].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[5].isBlack = 0;
                }
                nearpixel[6].b = imgA[j+1][i].b;
                nearpixel[6].g = imgA[j+1][i].g;
                nearpixel[6].r = imgA[j+1][i].r;
                if ((nearpixel[6].b == 0) &&
                        (nearpixel[6].g == 0) &&
                        (nearpixel[6].r == 0))
                {
                    nearpixel[6].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[6].isBlack = 0;
                }
                nearpixel[7].b = imgA[j+1][i+1].b;
                nearpixel[7].g = imgA[j+1][i+1].g;
                nearpixel[7].r = imgA[j+1][i+1].r;
                if ((nearpixel[7].b == 0) &&
                        (nearpixel[7].g == 0) &&
                        (nearpixel[7].r == 0))
                {
                    nearpixel[7].isBlack = 1;
                    blackpixels++;
                }
                else
                {
                    nearpixel[7].isBlack = 0;
                }
                //decide if we want to color our pixel
                if (blackpixels <= threshold)
                {
                    totalpixelscolored++;
                    //Bilinear Resampling
                    for (int l = 0; l <= 7; l++)
                    {
                        if (!nearpixel[l].isBlack)
                        {
                            mypixel.b += nearpixel[l].b;
                            mypixel.g += nearpixel[l].g;
                            mypixel.r += nearpixel[l].r;
                        }
                    }
                    mypixel.b /= (8 - blackpixels);
                    mypixel.g /= (8 - blackpixels);
                    mypixel.r /= (8 - blackpixels);
                }
            }
            imgB[j][i].b = mypixel.b ;
            imgB[j][i].g = mypixel.g ;
            imgB[j][i].r = mypixel.r ;
        }
    }
    cvReleaseImage(&img1);
    if (!cvSaveImage(output,img2))
    {
        cerr << "\nCould not save output file: " << output << endl;
    }
    cvReleaseImage(&img2);
}
```

## Addition of pre-processing techniques to ODM
* Orthophotos can be distorted due to noise present in the original images. A good amount of preprocessing can result in clear projection of original images, thereby improving quality of orthophoto. Opencv does provide various [denoising functions](http://docs.opencv.org/3.0-beta/modules/photo/doc/denoising.html) to preprocess the images.

## Machine learning!
After improving the point clouds and orthophotos, we can detect, classify and annotate various objects in the point clouds.  In my ML experience, these algorithms are similar to the ones used with images, so they can also be directly applied to orthophotos.

PS: 
One of my [previous work] (https://github.com/digvijayky/Tensorflow-real-time-video-analysis) (to be published) is to annotate images, one of the simple use cases I can think of is where we process an orthophoto for construction site, and generate a sentence like `There are 10 people working near 3 large buildings with 2 cranes nearby. There are 20 bags of cement on the ground and a truck loaded with sand.` 

Thanks!
