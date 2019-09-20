<cfheader name="access-control-allow-credentials" value="false" />
<cfheader name="access-control-allow-methods" value="GET, HEAD, OPTIONS" />
<cfheader name="access-control-allow-origin" value="*" />
<cfheader name="Vary" value="Origin" />
<cfheader name="access-control-expose-headers" value="Content-Length" />
<cfheader name="access-control-max-age" value="86400" />

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

<cfcontent type="image/jpeg" file="#expandPath("/Thumbnails")#/thumb_#application.images[trim(URL.ImageID)].name#.jpg" />