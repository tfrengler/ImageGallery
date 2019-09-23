<cfheader name="access-control-allow-credentials" value="false" />
<cfheader name="access-control-allow-methods" value="GET, HEAD, OPTIONS" />
<!--- <cfheader name="access-control-allow-origin" value="*" /> --->
<cfheader name="access-control-allow-origin" value="www.frenglerslair.nl" />
<cfheader name="Vary" value="Origin" />
<cfheader name="access-control-expose-headers" value="Content-Length, Content-Type, Accept" />
<cfheader name="access-control-max-age" value="86400" />
<cfheader name="Referrer-Policy" value="same-origin" />

<cfif NOT structKeyExists(URL, "ImageID") >
    <cfheader statuscode="404" />
    <p>Sorry chief, that ain't working</p>
    <cfabort/>
</cfif>

<cfif len(URL.ImageID) IS 0 >
    <cfheader statuscode="400" />
    <p>Sorry chief, that ain't working</p>
    <cfabort/>
</cfif>

<cfif NOT structKeyExists(application.images, URL.ImageID) >
    <cfheader statuscode="204" />
    <p>Sorry chief, that ain't working</p>
    <cfabort/>
</cfif>

<cfif structKeyExists(URL, "fullSize") >
    <cfset imagePath = "#expandPath("/Data")#/#application.images[trim(URL.ImageID)].name#.jpg" />
<cfelse>
    <cfset imagePath = "#expandPath("/Thumbnails")#/thumb_#application.images[trim(URL.ImageID)].name#.jpg" />
</cfif>

<cfcontent type="#fileGetMimeType(imagePath)#" file=#imagePath# />