<cfset sortedFileNames = [] />
<cfset fileNameToImageIDMap = {} />

<cfloop collection=#application.images# item="imageID" >
    <cfset currentImage = application.images[imageID] />
    <cfset arrayAppend(sortedFileNames, currentImage.name) />
    <cfset fileNameToImageIDMap[currentImage.name] = imageID />
</cfloop>

<cfset arraySort(sortedFileNames, "text", "asc") />

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

            #NotificationContainer {
                position: fixed;
                top: 0;
                background-color: #4CAF50; 
                color: white;
                border-radius: 0.2em;
                padding: 0.5em;
                left: 50%;
                transform: translateX(-50%);
                margin-top: 1em;
                z-index: 1000;
                font-size: 2em;
                display: none;
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
                font-size: 3em;
            }

            #PopUpClose:hover {
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

            .ImageWrapper img, #PopUpContainer img {
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
        <script type="text/javascript" <cfif structKeyExists(request, "nonce")>nonce="#request.nonce#"</cfif>>
            "use strict";

            const images = {};

            <cfloop array=#sortedFileNames# index="imageName" >
                <cfset currentImageID = fileNameToImageIDMap[imageName] />

                images["#currentImageID#"] = Object.seal({
                    name: "#imageName#",
                    data: ""
                });
            </cfloop>
            </cfoutput>

            const loadList = Object.keys(images);

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
                    else response.blob().then(file=> onImageLoaded(ID, file));
                })
                .catch(error=> {
                    console.error(error);
                    window.setTimeout(loadImages, 100);
                });

            };

            const onImageLoaded = function(ID, file) {
                images[ID].data = URL.createObjectURL(file);
                document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";

                let imageElement = document.querySelector(`img[data-imageid='${ID}']`);
                imageElement.style.display = "block";

                imageElement.onerror = function() {
                    this.src = "no_image.png";
                    document.querySelector("#Overlay").style.display = "block";
                    onPopupImageLoaded();
                };

                imageElement.src = images[ID].data;
                imageElement.addEventListener("click", onClickImage);

                window.setTimeout(loadImages, 100);
            };

            const onClickImage = function(event) {
                document.querySelector("#ImageDisplayName").innerText = images[event.srcElement.dataset["imageid"]].name;
                document.querySelector("#PopUpContainer img").src = `Data/${images[event.srcElement.dataset["imageid"]].name}.jpg`;
                
                document.querySelector("#Overlay").style.display = "block";
                document.querySelector("#NotificationMessage").innerText = "Loading full image...";
                document.querySelector("#NotificationContainer").style.display = "block";
            };

            const onPopupImageLoaded = function() {
                let popUpElement = document.querySelector("#PopUpContainer");
                popUpElement.style.top = window.pageYOffset + "px";
                let widthDifference = window.innerWidth - popUpElement.querySelector("img").width;

                if (widthDifference > 10)
                    popUpElement.style.left = widthDifference / 2 + "px";
                else
                    popUpElement.style.left = "";

                document.querySelector("#NotificationContainer").style.display = "none";
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

        <cfif structKeyExists(URL, "debuggery") AND structKeyExists(URL, "dumpImages") >
            <cfdump var=#application.images# expand="false" />
        </cfif>

        <cfloop array=#sortedFileNames# index="imageName" >
            <cfset currentImageID = fileNameToImageIDMap[imageName] />

            <section class="ImageContainer" data-imageid="#currentImageID#" >

                <section class="Loader" >
                    <div>LOADING</div>
                </section>

                <div class="ImageWrapper">
                    <img data-imageid="#currentImageID#" src="" validate="never" referrerpolicy="no-referrer" >
                </div>
            </section>

        </cfloop>

        <section id="Overlay"></section>
        <div id="NotificationContainer" >
            <span id="NotificationMessage">NOTIFY ME!</span>
        </div>

        <section id="PopUpContainer" >
            <div id="PopUpClose" >CLOSE</div>
            <img src="" validate="never" referrerpolicy="no-referrer" />
            <div id="ImageDisplayName" ></div>
        </section>

    </cfoutput>
    </body>

</html>