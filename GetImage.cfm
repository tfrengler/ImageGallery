<cfheader name="access-control-allow-credentials" value="false" />
<cfheader name="access-control-allow-methods" value="GET, HEAD, OPTIONS" />
<cfheader name="access-control-allow-origin" value="http://asgard" />
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

<cfheader name="Content-Length" value="#application.images[trim(URL.ImageID)].size#" />
<cfcontent type="image/jpeg" file="#expandPath("/Data")#/#application.images[trim(URL.ImageID)].name#" />