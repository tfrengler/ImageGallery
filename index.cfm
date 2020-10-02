<cfparam name="request.nonce" type="string" default="" />
<cfparam name="request.scriptChecksum" type="string" default="" />
<cfparam name="request.styleChecksum" type="string" default="" />

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

        <cfoutput>
        <link rel="stylesheet" type="text/css" href="main.css" <cfif len(request.styleChecksum) GT 0 >integrity="sha384-#request.styleChecksum#"</cfif> />
        <script type="text/javascript" src="main.js" <cfif len(request.scriptChecksum) GT 0 >integrity="sha384-#request.scriptChecksum#"</cfif> ></script>
        
        <style type="text/css" <cfif len(request.nonce) GT 0 >nonce='#request.nonce#'</cfif>>
            ##Header h1 {
                color: #application.config.bannerColor#;
            }
        </style>
        </cfoutput>
        
        <script type="text/javascript" <cfif len(request.nonce) GT 0 ><cfoutput>nonce='#request.nonce#'</cfoutput></cfif> >

            const images = {};

            <cfoutput>
            <cfset indexCounter = 1 />
            <cfloop array=#sortedFileNames# index="imageName" >
                <cfset currentImageID = fileNameToImageIDMap[imageName] />

                images["#currentImageID#"] = Object.seal({
                    name: "#listFirst(imageName, ".")#",
                    data: null,
                    index: #indexCounter#
                });

                <cfset indexCounter++ />
            </cfloop>

            const imageCount = #indexCounter#;
            </cfoutput>

            window.onload = function() {
                "use strict";

                Object.freeze(images);
                
                // The full size image popup
                document.querySelector("#PopUpClose").addEventListener("click", onCloseFullImage);

                document.querySelector("#ImagePrevious").addEventListener("click", ()=> onSwitchImage(true));
                document.querySelector("#ImageNext").addEventListener("click", ()=> onSwitchImage(false));

                document.querySelector("#PopUpContainer img").onload = onPopupImageLoaded;
                document.querySelector("#PopUpContainer img").onerror = onPopupImageError;

                // Setting the overlay size
                const body = document.body;
                const html = document.documentElement;

                var documentHeight = Math.max( body.scrollHeight, body.offsetHeight, html.clientHeight, html.scrollHeight, html.offsetHeight );
                var documentWidth = Math.max( body.scrollWidth, body.offsetWidth, html.clientWidth, html.scrollWidth, html.offsetWidth );

                let overlayElement = document.querySelector("#Overlay");
                overlayElement.style.height = documentHeight + "px";
                overlayElement.style.width = documentWidth + "px";

                document.querySelectorAll(".ImageContainer").forEach(sectionElement=> thumbnailObserver.observe(sectionElement));

                console.log("Init done");
            };

        </script>
        
    </head>

    <body>
    <cfoutput>

        <section id="Header" >
            <h1>#application.config.banner#</h1>
            <p>Showing #indexCounter# pictures</p>
            <p>#application.config.message#</p>
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
                    <div class="ImageName" >#encodeForHTML(listFirst(imageName, "."))#</div>
                </div>
            </section>

        </cfloop>

        <section id="Overlay"></section>
        <div id="NotificationContainer" >
            <span id="NotificationMessage">NOTIFY ME!</span>
        </div>

        <section id="PopUpContainer" >
            <div id="PopUpClose" >CLOSE</div>
            <img data-imageid="" src="" validate="never" referrerpolicy="no-referrer" />

            <section id="ImageControls" >
                <div id="ImagePrevious">Previous</div>
                <div id="ImageDisplayName">NAME</div>
                <div id="ImageNext" >Next</div>
            </section>
        </section>

    </cfoutput>
    </body>

</html>