<!DOCTYPE html>
<html>

    <head>
        <title>Vanguard Image Gallery</title>
        <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
        <meta name="author" content="Thomas Frengler" />

        <style>
            @font-face {
                font-family: Warcraft;
                src: url("MORPHEUS.TTF");
            }

            #Overlay {
                z-index: 150;
                position: absolute;
                background: rgba(0,0,200,0.5);
                top: 0;
                left: 0;
                display: none;
            }

            #PopUpContainer {
                position: absolute;
                background-color: #4CAF50; 
                z-index: 200;
                display: none;
                border-style: solid;
                border-width: 0.3em;
                border-color: #4CAF50;
                border-radius: 0.2em;
                margin-top: 2em;
            }

            #PopUpContainer div {
                text-align: center;
                background-color: #4CAF50;
                color: white;
                padding-bottom: 0.5em;
            }

            #PopUpContainer div:hover {
                color: yellow;
                cursor: pointer;
            }

            .ImageContainer {
                border-style: solid;
                border-width: 0.1em;
                border-color: #4CAF50;
                border-radius: 0.2em;
                display: inline-block;
                padding: 0.5em;
                margin: 0.2em;
                background-color: #4CAF50;
            }

            .ImageWrapper {
                width: 25em;
                height: 18.75em;
                border-radius: 0.2em;
                border-style: solid;
                border-width: 0.2em;
                border-color: white;
                background-color: white;
            }

            .ImageWrapper img {
                display: none;
                border-radius: inherit;
            }

            img {
                width: auto;
                height: auto;
                max-width: 100%;
                max-height: 100%;
                margin-left: auto;
                margin-right: auto;
            }

            .ImageWrapper img:hover {
                cursor: pointer;
            }

            body {
                background-color: black;
                font-family: "Warcraft", sans-serif;
            }

            h1 {
                text-align: center;
                font-size: 4em;
                color: blue;
                text-shadow: 1px 1px 2px white;
            }

            .Loader {
                position: absolute;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                z-index: 100;
                width: 25em;
                height: 18.75em;
                border-radius: 0.2em;
                border-style: solid;
                border-width: 0.2em;
                border-color: white;
            }
        </style>

        <cfoutput>
        <script type="text/javascript" nonce="#request.nonce#">
        
            "use strict";

            const images = {};

            <cfloop collection=#application.images# item="imageID" >
                <cfset currentImage = application.images[imageID] />

                images["#imageID#"] = {
                    name: "",
                    loaded: 0,
                    size: 0,
                    data: "",
                    chunks: new Set()
                };

                images["#imageID#"].name = "#currentImage.name#";
                Object.seal(images["#imageID#"]);
            </cfloop>
        </cfoutput>

            // const loadList = Object.keys(images);
            const loadList = ["B11A76442E59B301260D8B0B6EF71FF3","9A6C6E2034CBCF9F98E991AE4C30B16D","7FEE369F49E91AFC4053091CCC89DE0F"];
            // const loadList = [];

            window.onload = function() {
                Object.freeze(images);
                
                document.querySelector("#PopUpClose").addEventListener("click", ()=> {
                    document.querySelector("#PopUpContainer").style.display = "none";
                    document.querySelector("#Overlay").style.display = "none";
                });

                document.querySelector("#PopUpContainer img").onload = onPopupImageLoaded;

                const body = document.body;
                const html = document.documentElement;

                var documentHeight = Math.max( body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight );
                var documentWidth = Math.max( body.scrollWidth, body.offsetWidth, html.clientWidth, html.scrollWidth, html.offsetWidth );

                let overlayElement = document.querySelector("#Overlay");
                overlayElement.style.height = documentHeight + "px";
                overlayElement.style.width = documentWidth + "px";

                <cfif NOT structKeyExists(URL, "debuggery") >
                    loadImages();
                </cfif>

                console.log("Init done");
            };

            const loadImages = function() {
                if (!loadList.length) {
                    console.log("Done loading images");
                    return;
                }

                fetchImage(loadList.shift());
            };

            const fetchImage = function(ID) {
                if (!document.querySelector(`section[data-imageid='${ID}']`)) {
                    loadImages();
                    return;
                };

                const request = new Request(`GetImage.cfm?ImageID=${ID}`, {
                    cache: "force-cache",
                    mode: "same-origin",
                    method: "GET",
                    redirect: "error",
                    headers: new Headers({
                        accept: "image/jpeg"
                    })
                });

                fetch(request).then(response=> {
                    if (response.status !== 200) {
                        
                        let imageElement = document.querySelector(`img[data-imageid='${ID}']`);

                        imageElement.src = "no_image.png";
                        imageElement.style.display = "block";
                        document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";

                        throw new Error(`Server did not return status 200 | ${response.status} | ${ID}`);
                    }
                    else {
                        images[ID].size = parseInt(response.headers.get("Content-Length"));
                        document.querySelector(`section[data-imageid='${ID}'] progress`).max = images[ID].size;
                        readImageStream(response.body.getReader(), ID);
                    }
                })
                .catch(error=> {
                    // window.alert(error);
                    loadImages();
                });

            };

            const readImageStream = function(reader, ID) {
                return reader.read().then(result=> {
                    
                    if (result.done) {
                        onImageLoaded(ID);
                        return;
                    };

                    // retrieve the multi-byte chunk of data
                    images[ID].chunks.add(result.value);
                    // report our current progress
                    images[ID].loaded += result.value.byteLength;
                    document.querySelector(`section[data-imageid='${ID}'] progress`).value = images[ID].loaded;
                    
                    // go to next chunk via recursion
                    return readImageStream(reader, ID);
                });
            };

            const onImageLoaded = function(ID) {
                try {
                    let file = new Blob(images[ID].chunks, {type: "image/jpeg"});
                    images[ID].data = URL.createObjectURL(file);
                }
                catch(error) {
                    images[ID].data = "error";
                };

                images[ID].chunks.clear();
                document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";
                let imageElement = document.querySelector(`img[data-imageid='${ID}']`);

                imageElement.style.display = "block";
                imageElement.onerror = function() {this.src = "no_image.png"};
                imageElement.src = images[ID].data;
                imageElement.addEventListener(
                    "click",
                    (event)=> document.querySelector("#PopUpContainer img").src = images[event.srcElement.dataset["imageid"]].data
                );

                loadImages();
            };

            const onPopupImageLoaded = function() {
                let popUpElement = document.querySelector("#PopUpContainer");
                popUpElement.style.top = window.pageYOffset + "px";
                let widthDifference = window.innerWidth - popUpElement.querySelector("img").width;

                if (widthDifference > 10)
                    popUpElement.style.left = widthDifference / 2 + "px";

                popUpElement.style.display = "block";
                document.querySelector("#Overlay").style.display = "block";
            };
        </script>
    </head>

    <body>
    <cfoutput>

        <section id="Header" >
            <h1>The Theramore Vanguard</h1>
            <hr/>
        </section>

        <cfif structKeyExists(URL, "debuggery") >
            <cfdump var=#application.images# expand="false" />
        </cfif>

        <cfloop collection=#application.images# item="imageID" >
            <cfset currentImage = application.images[imageID] />

            <section class="ImageContainer" data-imageid="#imageID#" >

                <section class="Loader" >
                    <div>LOADING:</div>
                    <progress value="0" max="100" ></progress>
                </section>

                <div class="ImageWrapper">
                    <img data-imageid="#imageID#" src="" validate="never" referrerpolicy="no-referrer" >
                </div>
            </section>

        </cfloop>

        <section id="Overlay"></section>

        <section id="PopUpContainer" >
            <div id="PopUpClose" >CLOSE</div>
            <img src="" validate="never" referrerpolicy="no-referrer" />
        </section>

    </cfoutput>
    </body>

</html>