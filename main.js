"use strict";

const fetchImage = function(ID, fullSize) {

    var URLAppend = "";
    if (fullSize) URLAppend = "&fullSize=yes";

    const request = new Request(`GetImage.cfm?ImageID=${ID}${URLAppend}`, {
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
        else response.blob().then(file=> {
            if (fullSize)
                document.querySelector("#PopUpContainer img").src = URL.createObjectURL(file);
            else
                onThumbnailLoaded(ID, file)
        });
    })
    .catch(error=> console.error(error));

};

const onThumbnailLoaded = function(ID, file) {
    images[ID].data = URL.createObjectURL(file);
    document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";

    let imageElement = document.querySelector(`img[data-imageid='${ID}']`);
    imageElement.style.display = "block";

    imageElement.onerror = function() {
        this.src = "no_image.png";
    };

    imageElement.src = images[ID].data;
    imageElement.addEventListener("click", onClickImage);
};

const onClickImage = function(event) {
    document.querySelector("#ImageDisplayName").innerText = images[event.srcElement.dataset["imageid"]].name;
    
    document.querySelector("#Overlay").style.display = "block";
    document.querySelector("#NotificationMessage").innerText = "Loading full image...";
    document.querySelector("#NotificationContainer").style.display = "block";

    fetchImage(event.srcElement.dataset["imageid"], true);
};

const onPopupImageError = function() {
    this.src = "no_image.png";
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

const thumbnailLoader = function(entries, observer) {
    entries.forEach(entry=> {
        if (!entry.isIntersecting) return;

        fetchImage(entry.target.dataset["imageid"]);
        observer.unobserve(entry.target);
    });
};

const thumbnailObserver = new IntersectionObserver(thumbnailLoader, {
    root: null,
    rootMargin: '0px',
    threshold: 0.25
});