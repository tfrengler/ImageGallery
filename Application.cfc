<cfcomponent output="false">

	<cfset this.name="ImageGallery" />
	<cfset this.applicationtimeout = createTimeSpan(14,0,0,0) />
	<cfset this.setClientCookies = true />

	<cfset root = getDirectoryFromPath(getCurrentTemplatePath()) />

	<cfset this.mappings["/Data"] = "#root#Data/" />

	<cffunction name="onApplicationStart" returntype="boolean" output="false" >

		<cftry>
			<cfdirectory name="imageQuery" directory="#expandPath("/Data")#" type="file" filter="*.jpg" action="list" />
            <cfset application.images = {} />

            <cfloop query=#imageQuery# >
				<cfset application.images[hash(imageQuery.name, "MD5")] = {
                    name: imageQuery.name,
                    size: imageQuery.size
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

		<cfreturn true />
	</cffunction>

	<cffunction name="onRequestStart" returntype="boolean" output="false" >

		<!--- <cfheader name="X-Accel-Buffering" value="no" /> --->

		<cfif structKeyExists(URL, "Restarty") >
			<cfset sessionInvalidate() />
			<cfset applicationStop() />

			<cflocation url="#CGI.SCRIPT_NAME#?debuggery" addtoken=false />
		</cfif>

		<cfreturn true />
	</cffunction>

</cfcomponent>