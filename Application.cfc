<cfcomponent output="false">

	<cfset this.name="ImageGallery" />
	<cfset this.applicationtimeout = createTimeSpan(14,0,0,0) />
	<cfset this.setClientCookies = true />

	<cfset root = getDirectoryFromPath(getCurrentTemplatePath()) />

	<cfset this.mappings["/Data"] = "#root#Data/" />
	<cfset this.mappings["/Thumbnails"] = "#root#Data/Thumbnails/" />

	<cffunction name="onApplicationStart" returntype="boolean" output="false" >

		<cftry>
			<cfdirectory name="imageQuery" directory="#expandPath("/Data")#" type="file" filter="*.jpg" action="list" />
            <cfset application.images = {} />

            <cfloop query=#imageQuery# >
				<cfset application.images[hash(imageQuery.name, "MD5")] = {
                    name: listFirst(imageQuery.name, ".")
                } />
            </cfloop>

		<cfcatch>
			<cfif structKeyExists(URL, "debuggery") >
				<cfrethrow/>
			<cfelse>
				<cfset application.images = [] />
			</cfif>
		</cfcatch>
		</cftry>

		<cfset var checksumCreator = createObject("java", "java.security.MessageDigest").getInstance("SHA-384") />
		<cfset var scriptStringToHash = fileRead("#root#/main.js", "utf-8") />
		<cfset var styleStringToHash = fileRead("#root#/main.css", "utf-8") />

		<cfset application.scriptChecksum = toBase64(checksumCreator.digest(scriptStringToHash.getBytes()), "utf-8") />
		<cfset application.styleChecksum = toBase64(checksumCreator.digest(styleStringToHash.getBytes()), "utf-8") />

		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returntype="boolean" output="true" >
		<cfargument type="string" name="targetPage" required=true />

		<cfif structKeyExists(URL, "Restarty") >
			<cfset sessionInvalidate() />
			<cfset applicationStop() />

			<cflocation url="#CGI.SCRIPT_NAME#?debuggery" addtoken=false />
		</cfif>
		
		<cfif find("/index.cfm", arguments.targetPage) AND NOT structKeyExists(URL, "debuggery") > 
			<cfset request.nonce = toBase64(generateSecretKey("AES", 128)) />
			<cfset request.scriptChecksum = application.scriptChecksum />
			<cfset request.styleChecksum = application.styleChecksum />
			<cfheader name="Content-Security-Policy" value="script-src 'nonce-#request.nonce#' 'self'; style-src 'nonce-#request.nonce#' 'self'" />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>