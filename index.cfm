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

            #PopUpContainer {
                position: absolute;
                background-color: #4CAF50; 
                z-index: 200;
                display: none;
                border-style: solid;
                border-width: 0.3em;
                border-color: #4CAF50;
                border-radius: 0.2em;
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
                width: 400px;
                height: 300px;
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

            .ImageLinkContainer {
                position: absolute;
                z-index: 99;
                color: white;
                width: 400px;
                height: 300px;
                justify-content: center;
                align-items: center;
                background: rgba(0, 0, 200, 0.5);
                border-radius: 0.2em;
                border-style: solid;
                border-width: 0.2em;
                border-color: white;
                display: none;
            }

            .ImageLinks {
                text-align: center;
                border-radius: 0.2em;
                background-color: #4CAF50;
                color: white;
                padding: 0.5em;
            }

            .ImageLinks:hover {
                cursor: pointer;
            }

            .loader {
                position: absolute;
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                z-index: 100;
                width: 400px;
                height: 300px;
                border-radius: 0.2em;
                border-style: solid;
                border-width: 0.2em;
                border-color: white;
            }
        </style>

        <script type="text/javascript">
            "use strict";

            const images = {};

            <cfoutput>
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

            window.onload = function() {
                Object.freeze(images);
                let popUpElement = document.querySelector("#PopUpContainer").style.top = window.innerHeight * 0.05 + "px";

                document.querySelectorAll(".OpenImagePopUp").forEach(element=> element.addEventListener("click", openImagePopUp));
                document.querySelectorAll(".OpenImageNewTab").forEach(element=> element.addEventListener("click", openImageNewTab));

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
                        document.querySelector(`section[data-imageid='${ID}'] progress`).style.display = "none";
                        document.querySelector(`section[data-imageid='${ID}'] img`).src = "no_image.png";
                        throw new Error(`Server did not return status 200 | ${response.status} | ${ID}`);
                    }
                    else {
                        images[ID].size = parseInt(response.headers.get("Content-Length"));
                        document.querySelector(`section[data-imageid='${ID}'] progress`).max = images[ID].size;
                        readImageStream(response.body.getReader(), ID);
                    }
                })
                .catch(error=> {
                    console.error(error);
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
                document.querySelector(`section[data-imageid='${ID}'] .loader`).style.display = "none";
                let imageElement = document.querySelector(`section[data-imageid='${ID}'] img`);

                imageElement.style.display = "block";
                imageElement.src = images[ID].data;
                imageElement.onerror = function() {this.src = "no_image.png"};
                imageElement.addEventListener(
                    "click",
                    ()=> document.querySelector(`section[data-imageid='${ID}'] .ImageLinkContainer`).style.display = "flex"
                );

                loadImages();
            };

            const openImagePopUp = function() {
                console.log(images[this.dataset.imageid].data);

                let popUpElement = document.querySelector("#PopUpContainer");
                let imageElement = popUpElement.querySelector("img");
                imageElement.onload = onPopupImageLoaded;
                imageElement.src = images[this.dataset.imageid].data;
            };

            const openImageNewTab = function() {
                window.open(images[this.dataset.imageid].data, "_blank");
            };

            const onPopupImageLoaded = function() {
                let popUpElement = document.querySelector("#PopUpContainer");
                console.log(popUpElement.querySelector("img").width);
                let widthDifference = window.innerWidth - popUpElement.querySelector("img").width;

                if (widthDifference > 10)
                    popUpElement.style.left = widthDifference / 2 + "px";

                popUpElement.style.display = "block";
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
                <section class="ImageLinkContainer">
                    <section>
                        <div class="ImageLinks OpenImagePopUp" data-imageid="#imageID#" >OPEN IN POPUP</div>
                        <br/>
                        <div class="ImageLinks OpenImageNewTab" data-imageid="#imageID#" >OPEN IN NEW TAB</div>
                    </section>
                </section>

                <section class="loader" >
                    <div>LOADING:</div>
                    <progress value="0" max="100" ></progress>
                </section>

                <div class="ImageWrapper">
                    <img src="" validate="never" referrerpolicy="no-referrer" >
                </div>
            </section>

        </cfloop>

        <section id="PopUpContainer" >
            <div>CLOSE</div>
            <img src="" validate="never" referrerpolicy="no-referrer" >
        </section>

    </cfoutput>
    </body>

</html>