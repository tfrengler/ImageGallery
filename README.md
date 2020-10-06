# ImageGallery

My take on an image gallery. Take it as a hobbyist learning project, and not any kind of defacto good way to go about making something like this.

As with almost all my projects this is my idea of how to make an image gallery and came about when I wanted to share a number of images with a group of people online. It's not hacky, or hastily put together, but it was deliberately kept simple.

It's a static gallery: you can't upload, edit, filter/sort or anything like that. It's meant to be a read-only gallery of a collection of images that doesn't change (often at least).

One thing I discovered is that when working with images it's easy - if you aren't careful - to use a lot of resources on the client's side. Lesson's learned:

* Use thumbnails! Don't just use the full size images and scale them down with CSS on the overview of images. This way I managed to use 2 GB of RAM in my browser tab... Create scaled down versions that you load in instead.
* Lazy load (thumbnail)images if possible, and in the right order. At first I just generated the full overview and set the src-attrib of the img-tags to their thumbnail elements. On slower connections this took a long time to load, and often thumbnails at the bottom of the page loaded first, which wasn't ideal. Using the JS IntersectionObserver API I managed to lazy load the thumbnails, and with a custom download queue, they loaded in order as they were revealed on the page
* Think of fallback's when images won't load. A simple case of replacing the faulty image with an "error"-image, but well worth doing
* When loading images via fetch() (meaning they'll likely be blob's) make sure to release the object URL's when not needed anymore, or you effectively have a memory leak, causing the page to use progressively more RAM as the user opens images
* Since the image gallery is static ensure that the fetch-requests are cached, so that the next time a user loads the gallery, they don't have to re-download the images and they can be fetched from disc cache
