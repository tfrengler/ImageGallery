"use strict";

const fetchImage2 = function(ID, fullSize) {

    var URLAppend = "";
    if (fullSize) URLAppend = "&fullSize=yes";

    const request = new Request(`GetImage.cfm?ImageID=${ID}${URLAppend}`, {
        cache: "force-cache",
        mode: "same-origin",
        method: "GET",
        redirect: "error",
        headers: new Headers({
            accept: "image/jpeg,image/png,image/bmp"
        })
    });

    fetch(request).then(response=> {
        if (response.status !== 200) {
            // TODO(thomas): Needs to take fullsize into account!
            let imageElement = document.querySelector(`img[data-imageid='${ID}']`);

            imageElement.src = "no_image.png";
            imageElement.style.display = "block";
            document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";

            throw new Error(`Server did not return status 200 | ${response.status} | ${ID}`);
        }
        else response.blob().then(file=> {
            if (fullSize) {
                let popUpImage = document.querySelector("#PopUpContainer img");
                popUpImage.src = URL.createObjectURL(file);
                popUpImage.dataset["imageid"] = ID;
            }
            else
                onThumbnailLoaded(ID, file)
        });
    })
    .catch(error=> console.error(error));
};

const fetchImage = function(ID, fullSize) {

    var URLAppend = "";
    if (fullSize) URLAppend = "&fullSize=yes";

    const request = new Request(`GetImage.cfm?ImageID=${ID}${URLAppend}`, {
        cache: "force-cache",
        mode: "same-origin",
        method: "GET",
        redirect: "error",
        headers: new Headers({
            accept: "image/jpeg,image/png,image/bmp"
        })
    });

    return new Promise((resolve, reject)=> {
        
        fetch(request).then(response=> {
            if (response.status !== 200) {
                
                let imageElement = document.querySelector(`img[data-imageid='${ID}']`);

                imageElement.src = "no_image.png";
                imageElement.style.display = "block";
                document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";

                reject(new Error(`Server did not return status 200 | ${response.status} | ${ID}`));
            }
            else response.blob().then(file=> {
                if (fullSize) {
                    let popUpImage = document.querySelector("#PopUpContainer img");
                    popUpImage.src = URL.createObjectURL(file);
                    popUpImage.dataset["imageid"] = ID;
                }
                else
                    onThumbnailLoaded(ID, file);

                resolve();
            });
        });
    });
};

const onThumbnailLoaded = function(ID, file) {
    images[ID].data = URL.createObjectURL(file);
    document.querySelector(`section[data-imageid='${ID}'] .Loader`).style.display = "none";
    document.querySelector(`section[data-imageid='${ID}'] .ImageName`).style.visibility = "visible";

    let imageElement = document.querySelector(`img[data-imageid='${ID}']`);
    imageElement.style.display = "block";

    imageElement.onerror = function() {
        this.src = "no_image.png";
    };

    imageElement.src = images[ID].data;

    imageElement.addEventListener("click", (event)=> {
        let imageID = event.srcElement.dataset["imageid"] || null;
        let imageName = images[imageID].name;
        onClickImage(imageID, imageName);
    });
};

const onClickImage = function(imageID, imageName) {
    document.querySelector("#ImageDisplayName").innerText = imageName;
    
    document.querySelector("#Overlay").style.display = "block";
    document.querySelector("#NotificationMessage").innerText = "Loading full image...";
    document.querySelector("#NotificationContainer").style.display = "block";

    fetchImage(imageID, true);
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

        downloadQueue.add(entry.target.dataset["imageid"], false);
        observer.unobserve(entry.target);
    });
};

const thumbnailObserver = new IntersectionObserver(thumbnailLoader, {
    root: null,
    rootMargin: '0px',
    threshold: 0.25
});

const onSwitchImage = function(previous) {
    
    const popUpImage = document.querySelector("#PopUpContainer img");
    
    let id = popUpImage.dataset.imageid;
    let currentIndex = images[id].index;
    let searchIndex = previous ? currentIndex - 1 : currentIndex + 1;
    let followingImageID = null;

    if (searchIndex < 1 || searchIndex > imageCount)
        return;

    for(let imageID in images)
    {
        if (images[imageID].index == searchIndex) {
            followingImageID = imageID;
            break;
        }
    }

    onCloseFullImage();
    if (!followingImageID) return;
    onClickImage(followingImageID, images[followingImageID].name);
};

const onCloseFullImage = function() {
    document.querySelector("#PopUpContainer").style.display = "none";
    document.querySelector("#Overlay").style.display = "none";
    URL.revokeObjectURL(document.querySelector("#PopUpContainer img").src);
}

const downloadQueue = (function() {

    const queue = [];
    var inProgress = false;

    const DownloadRequest = function(ID, fullSize)
    {
        this.ID = ID;
        this.fullSize = fullSize;

        return Object.freeze(this);
    }

    const add = function(ID, fullSize) {
        queue.push(new DownloadRequest(ID, fullSize));
        if (!inProgress) _doDownload();
    }

    const _doDownload = function() {
        inProgress = true;
        
        if (queue.length == 0) {
            inProgress = false;
            return;
        }

        let nextDownload = queue.shift();
        fetchImage(nextDownload.ID, nextDownload.fullSize)
        .then(_doDownload)
        .catch(()=> {
            console.error("Error during download request");
            _doDownload();
        });
    };

    return Object.freeze({
        add: add
    });
})();