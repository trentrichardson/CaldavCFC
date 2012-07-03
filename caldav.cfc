<cfcomponent output="false" displayname="CalDavCfc" hint="Handle connection to caldav calendars and todos" name="CalDavCFC">
	
	<cfset this.host = ""> <!--- Something like: 'domain.com' --->
	<cfset this.port = 80> <!--- https or ssl will likely be 443, http or tcp will likely be 80 --->
	<cfset this.path = ""> <!--- Something like: /calendars/DOMAIN/USER/Calendar/ --->

	<cfset this.username = "">
	<cfset this.password = "">

	<cfset this.contentType = ""> <!--- Some like text/calendar, some text/icalendar --->
	<cfset this.userAgent = "CalDavCFC">

	<!--- 
	#########################################################################
	Constructor
	@host The host caldav server (ex: "domain.com")
	@port The port for the connection (ex: https/ssl would be 443, http/tcp would be 80)
	@path url path to the calendar folder (ex: "/calendars/DOMAIN/USER/Calendar")
	@username The username to log in to the server
	@password The password to log in to the server

	returns this class object
	 --->
	<cffunction name="init" returntype="any" access="public" output="false">
		<cfargument name="host" type="string" required="true" />
		<cfargument name="port" type="string" required="true" />
		<cfargument name="path" type="string" required="true" />
		<cfargument name="username" type="string" required="true" />
		<cfargument name="password" type="string" required="true" />
		<cfargument name="contentType" type="string" required="false" default="text/calendar" />

		<cfset this.host = arguments.host>
		<cfset this.port = arguments.port>
		<cfset this.path = arguments.path>
		<cfset this.username = arguments.username>
		<cfset this.password = arguments.password>
		<cfset this.contentType = arguments.contentType>

		<cfreturn this />
	</cffunction>

	<!--- 
	#########################################################################
	options
	@urlAppend extend the host url to the ico file

	returns a string list of all options, or "" if no options returned

	urlAppend is appended to the host url to point to a specific ics file:
	'http://mail.domain.com/calendars/DOMAIN/USER/Calendar/' & 'my-unique-uid-12345.ics'
	if the generated url does not point to a file to update, a new event is create.

	This method is more for information of what types of requests may be made. 
	For instance GET, POST, PUT, DELETE, REPORT, OPTIONS, SEARCH, etc
	 --->
	<cffunction name="options" returntype="string" access="public" output="false">
		<cfargument name="urlAppend" type="string" required="false" default="" />

		<cfset var result = makeRequest(arguments.urlAppend, "OPTIONS", "", "text/xml")>

		<cfif isDefined('result.headers.allow')>
			<cfreturn result.headers.allow >
		</cfif>

		<cfreturn "" />
	</cffunction>

	<!--- 
	#########################################################################
	edit
	@urlAppend extend the host url to the ico file
	@iCal string of a new event to write to the file specifiec by the url

	returns http response headers

	urlAppend is appended to the host url to point to a specific ics file:
	'http://mail.domain.com/calendars/DOMAIN/USER/Calendar/' & 'my-unique-uid-12345.ics'
	if the generated url does not point to a file to update, a new event is create.

	iCal should look something like:
	BEGIN:VCALENDAR
	VERSION:2.0
	BEGIN:VEVENT
	DTSTAMP:20111228T211811Z
	DTSTART:201206015T000000Z
	DTEND:201206015T000000Z
	UID:my-test-uid-12345
	DESCRIPTION:My event description details
	LOCATION:Office
	SUMMARY:My Event Title
	END:VEVENT
	END:VCALENDAR
	 --->
	<cffunction name="edit" returntype="struct" access="public" output="false">
		<cfargument name="urlAppend" type="string" required="true" />
		<cfargument name="iCal" type="string" required="true" />
		
		<cfset var headers = [
				{ name="If-None-Match", value="*" },
				{ name="Expect", value="" }
			]>
		<cfset var result = makeRequest(arguments.urlAppend, "PUT", arguments.iCal, this.contentType)>
		
		<cfreturn result.headers>
	</cffunction>

	<!--- 
	#########################################################################
	delete
	@urlAppend extend the host url to the ico file

	returns http response headers.

	urlAppend is appended to the host url to point to a specific ics file:
	'http://mail.domain.com/calendars/DOMAIN/USER/Calendar/' & 'my-unique-uid-12345.ics'
	 --->
	<cffunction name="delete" returntype="struct" access="public" output="false">
		<cfargument name="urlAppend" type="string" required="true" />

		<cfset var headers = [
				{ name="If-None-Match", value="*" },
				{ name="Expect", value="" }
			]>
		<cfset var result = makeRequest(arguments.urlAppend, "DELETE", "", this.contentType)>
		
		<cfreturn result.headers>
	</cffunction>

	<!--- 
	#########################################################################
	get
	@urlAppend extend the host url to the ico file
	@mode how to return the results. "all" is the full http reponse, "struct"
		is the parsed ical string, and "ical" is the raw ical string

	returns http response.  Should contain an iCal string if successful

	urlAppend is appended to the host url to point to a specific ics file:
	'http://mail.domain.com/calendars/DOMAIN/USER/Calendar/' & 'my-unique-uid-12345.ics'
	 --->
	<cffunction name="get" returntype="any" access="public" output="false">
		<cfargument name="urlAppend" type="string" required="true" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />

		<cfset var result = makeRequest(arguments.urlAppend, "GET", "", this.contentType)>

		<cfif arguments.mode eq "struct">
			<cfreturn parseResponse(result.body) >
		<cfelseif arguments.mode eq "ical">
			<cfreturn result.body>
		</cfif>
		<cfreturn result >
	</cffunction>

	<!--- 
	#########################################################################
	getEventByUid
	@uid string uid to query for
	@urlAppend extend the host url to the ico file or folder
	@mode how to return the results. "all" gives the http response, 
		"struct" parses out the ical, and "ical" is the text string.  
		struct and ical are  array of entries

	returns object if successful, false otherwise
	 --->
	<cffunction name="getEventByUid" returntype="any" access="public" output="false">
		<cfargument name="uid" type="string" required="false" default="" />
		<cfargument name="urlAppend" type="string" required="false" default="" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />
		
		<cfset var result = getEvents("", "", "UID:#arguments.uid#", "", arguments.urlAppend, arguments.mode)>

		<cfif ArrayLen(result) gt 0 and arguments.mode neq 'all'>
			<cfreturn result[1] >
		</cfif>

		<cfreturn false >
	</cffunction>

	<!--- 
	#########################################################################
	getTodoByUid
	@uid string uid to query for
	@urlAppend extend the host url to the ico file or folder
	@mode how to return the results. "all" gives the http response, 
		"struct" parses out the ical, and "ical" is the text string.  
		struct and ical are  array of entries

	returns object if successful, false otherwise
	 --->
	<cffunction name="getTodoByUid" returntype="any" access="public" output="false">
		<cfargument name="uid" type="string" required="false" default="" />
		<cfargument name="urlAppend" type="string" required="false" default="" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />
		
		<cfset var result = getTodos("", "", "UID:#arguments.uid#", "", arguments.urlAppend, arguments.mode)>
		
		<cfif ArrayLen(result) gt 0 and arguments.mode neq 'all'>
			<cfreturn result[1] >
		</cfif>
		
		<cfreturn false >
	</cffunction>

	<!--- 
	#########################################################################
	getEvents
	@startDate String start date: 20120601T000000Z
	@endDate String end date: 20120601T000000Z
	@posFilters list of KEY:VALUE pairs to query against for a positive 
		match. Ex: "STATUS:NEEDS-ACTION,PRIORITY:1". Look at the raw ical 
		to see the pairs you can query against
	@posFilters list of KEY:VALUE pairs to query against for a negative 
		match. Ex: "STATUS:COMPLETED,STATUS:CANCELLED" will get all todos 
		not cancelled and not completed
	@urlAppend extend the host url to the ico file or folder
	@mode how to return the results. "all" gives the http response, 
		"struct" parses out the ical, and "ical" is the text string.  
		struct and ical are  array of entries
	 --->
	<cffunction name="getEvents" returntype="any" access="public" output="false">
		<cfargument name="startDateTime" type="string" required="false" default="" />
		<cfargument name="endDateTime" type="string" required="false" default="" />
		<cfargument name="posFilters" type="string" required="false" default="" hint="List of statuses to filter positive for: STATUS:COMPLETED,PRIORITY:1" />
		<cfargument name="negFilters" type="string" required="false" default="" hint="List of statuses to filter negative for: STATUS:COMPLETED,PRIORITY:2" />
		<cfargument name="urlAppend" type="string" required="false" default="" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />
		
		<cfset var result = {}>

		<cfsavecontent variable="xmlstr">
			<C:filter>
				<C:comp-filter name="VCALENDAR">
					<C:comp-filter name="VEVENT">
						<cfloop list="#arguments.posFilters#" index="i">
							<C:prop-filter name="<cfoutput>#ucase(listFirst(i,':'))#</cfoutput>">
								<C:text-match negate-condition="no"><cfoutput>#ucase(listLast(i,':'))#</cfoutput></C:text-match>
							</C:prop-filter>
						</cfloop>
						<cfloop list="#arguments.negFilters#" index="i">
							<C:prop-filter name="<cfoutput>#ucase(listFirst(i,':'))#</cfoutput>">
								<C:text-match negate-condition="yes"><cfoutput>#ucase(listLast(i,':'))#</cfoutput></C:text-match>
							</C:prop-filter>
						</cfloop>

						<cfif arguments.startDateTime neq "" and arguments.endDateTime neq "">
							<C:time-range start="<cfoutput>#arguments.startDateTime#</cfoutput>" end="<cfoutput>#arguments.endDateTime#</cfoutput>"/>
						</cfif>
					</C:comp-filter>
				</C:comp-filter>
			</C:filter>
		</cfsavecontent>

		<cfset result = query(xmlstr, arguments.urlAppend, arguments.mode)>

		<cfreturn result >
	</cffunction>

	<!--- 
	#########################################################################
	getTodos
	@startDate String start date: 20120601T000000Z
	@endDate String end date: 20120601T000000Z
	@posFilters list of KEY:VALUE pairs to query against for a positive 
		match. Ex: "STATUS:NEEDS-ACTION,PRIORITY:1". Look at the raw ical 
		to see the pairs you can query against
	@posFilters list of KEY:VALUE pairs to query against for a negative 
		match. Ex: "STATUS:COMPLETED,STATUS:CANCELLED" will get all todos 
		not cancelled and not completed
	@urlAppend extend the host url to the ico file or folder
	@mode how to return the results. "all" gives the http response, 
		"struct" parses out the ical, and "ical" is the text string.  
		struct and ical are  array of entries
	 --->
	<cffunction name="getTodos" returntype="any" access="public" output="false">
		<cfargument name="startDateTime" type="string" required="false" default="" />
		<cfargument name="endDateTime" type="string" required="false" default="" />
		<cfargument name="posFilters" type="string" required="false" default="" hint="List of statuses to filter positive for: STATUS:COMPLETED,PRIORITY:1" />
		<cfargument name="negFilters" type="string" required="false" default="" hint="List of statuses to filter negative for: STATUS:COMPLETED,PRIORITY:2" />
		<cfargument name="urlAppend" type="string" required="false" default="" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />
		
		<cfset var result = {}>

		<cfsavecontent variable="xmlstr">
			<C:filter>
				<C:comp-filter name="VCALENDAR">
					<C:comp-filter name="VTODO">
						<cfloop list="#arguments.posFilters#" index="i">
							<C:prop-filter name="<cfoutput>#ucase(listFirst(i,':'))#</cfoutput>">
								<C:text-match negate-condition="no"><cfoutput>#ucase(listLast(i,':'))#</cfoutput></C:text-match>
							</C:prop-filter>
						</cfloop>
						<cfloop list="#arguments.negFilters#" index="i">
							<C:prop-filter name="<cfoutput>#ucase(listFirst(i,':'))#</cfoutput>">
								<C:text-match negate-condition="yes"><cfoutput>#ucase(listLast(i,':'))#</cfoutput></C:text-match>
							</C:prop-filter>
						</cfloop>

						<cfif arguments.startDateTime neq "" and arguments.endDateTime neq "">
							<C:time-range start="<cfoutput>#arguments.startDateTime#</cfoutput>" end="<cfoutput>#arguments.endDateTime#</cfoutput>"/>
						</cfif>
					</C:comp-filter>
				</C:comp-filter>
			</C:filter>
		</cfsavecontent>

		<cfset result = query(xmlstr, arguments.urlAppend, arguments.mode)>

		<cfreturn result >
	</cffunction>

	<!--- 
	#########################################################################
	query
	@xmlFilter an xml string containing the search query
	@urlAppend extend the host url to the ico file or folder
	@mode how to return the results. "all" gives the http response, 
		"struct" parses out the ical, and "ical" is the text string.  
		struct and ical are  array of entries
	 --->
	<cffunction name="query" returntype="any" access="public" output="false">
		<cfargument name="xmlFilter" type="string" required="true" />
		<cfargument name="urlAppend" type="string" required="false" default="" />
		<cfargument name="mode" type="string" required="false" default="struct" hint="all, struct, or ical" />
		
		<cfset var result = {}>
		<cfset var search = []>
		<cfset var items = []>
		<cfset var contents = "">
		<cfset var xmlobj = {}>
		<cfset var href={}>
		<cfset var ical={}>

		<cfsavecontent variable="xmlstr"><?xml version="1.0" encoding="utf-8" ?>
			<C:calendar-query xmlns:D="DAV:" xmlns:C="urn:ietf:params:xml:ns:caldav">
				<D:prop>
					<C:calendar-data/>
					<D:getetag/>
				</D:prop>
				<cfoutput>#arguments.xmlFilter#</cfoutput>
			</C:calendar-query>
		</cfsavecontent>

		<cfset result = makeRequest(arguments.urlAppend, "REPORT", xmlstr, "text/xml")>

		<!--- return the full package --->
		<cfif arguments.mode eq "all">
			<cfreturn result >
		</cfif>

		<!--- Sometimes, for some reason or another the xml strings won't parse, if so we will use regex instead --->
		<cftry>
			<cfset xmlobj = XmlParse(result.body)>

			<cfif not find("xmlns:c=", xmlobj)>
				<cfreturn items >
			</cfif>
			
			<!--- a:response will contain a:href and ccalendar-data which we want --->
			<cfset search = xmlSearch(xmlobj, "//a:response/")>

			<cfloop array="#search#" index="i">
				<cfset href=i['a:href'].XmlText>
				<cfset ical=i['a:propstat']['a:prop']['c:calendar-data'].XmlText>

				<cfif arguments.mode eq "struct">
					<cfset ArrayAppend(items, { href=href, file=getFileFromPath(href), ical=parseResponse(ical) })>
				<cfelse>
					<cfset ArrayAppend(items, { href=href, file=getFileFromPath(href), ical=ical })>
				</cfif>
			</cfloop>
			
			<cfcatch type="Any">

				<!--- failed to create an xml doc, maybe invalid xml, who knows... so parse as string --->
				<cfset search = ReMatchNoCase("\<a\:response\s?.*?\>(.+?)\<\/a\:response\>", result.body)>
				
				<cfloop array="#search#" index="i">
					<cfset href=ReReplaceNoCase(i, "(.*?\<a\:href\s?.*?\>)(.+?)(\<\/a\:href\>.*)", "\2")>
					<cfset ical=ReReplaceNoCase(i, "(.*?\<c\:calendar\-data\s?.*?\>)(.+?)(\<\/c\:calendar\-data\>.*)", "\2")>

					<cfif arguments.mode eq "struct">
						<cfset ArrayAppend(items, { href=href, file=getFileFromPath(href), ical=parseResponse(ical) })>
					<cfelse>
						<cfset ArrayAppend(items, { href=href, file=getFileFromPath(href), ical=ical })>
					</cfif>
				</cfloop>
				
			</cfcatch>
		</cftry>

		<cfreturn items >
	</cffunction>

	<!--- 
	#########################################################################
	makeRequest will create a socket connection to the caldav server. You 
	should use the getOptions method from this component to determine the 
	request types (arguments.method) you may make.

	@urlAppend extend the host url to the ico file (optional)
	@method type of request to make (PUT, DELETE, GET, etc)
	@data string of the data to send (ex: an iCalendar format string)
	@contentType the content type of the data sent (ex: text/calendar)
	@headers any extra headers to pass along [{name='', value=''}, ...]

	returns a request object similar to 
	{ headers={}, headersRaw="", body="", raw="" }
	headers will be an object of each header value
	body will be the content returned (xml, ical file, etc..)
	raw and headersRaw is the unparsed response from the server
	 --->
	<cffunction name="makeRequest" returntype="struct" access="public" output="false">
		<cfargument name="appendUrl" type="string" required="false" default="" />
		<cfargument name="method" type="string" required="false" default="GET" />
		<cfargument name="data" type="string" required="false" default="" />
		<cfargument name="contentType" type="string" required="false" default="application/x-www-form-urlencoded" />
		<cfargument name="headers" type="array" required="false" hint="An array of structs with 'name' and 'value' properties"/>
		
		<cfscript>
			var result = { headers={}, headersRaw="", body="", raw="" };
			var socket = createObject( "java", "java.net.Socket" );
			var output = "";
			var input = "";
			var line = "";
			var bodypos = 0;
			var xmlpos = 0;
			var newLine = chr(13) & chr(10);
			var headerRow = "";

			try{
				socket.init(this.host, this.port);
			}
			catch(Object e){
				return { error="Could not connect to host." };
			}

			if( socket.isConnected() ){

				// send a request
				output = createObject("java", "java.io.PrintWriter").init(socket.getOutputStream());
				output.println(arguments.method & " " & this.path & arguments.appendUrl & " HTTP/1.1");
				output.println("Authorization: Basic "& ToBase64(this.username &":"& this.password) );
				output.println("Host: "& this.host &":"& this.port );

				if(isDefined("arguments.headers")){
					for(i=1; i lte ArrayLen(arguments.headers); i++){
						output.println(arguments.headers[i].name &": "& arguments.headers[i].value);
					}
				}

				output.println("Content-Type: "& arguments.contentType );
				output.println("User-Agent: "& this.userAgent);
				output.println("Content-Length: "& Len(arguments.data) );
				output.println("Connection: close" );
				output.println();
				output.println(arguments.data);
				output.flush();

				// read back the response
				input = createObject( "java", "java.io.BufferedReader").init(createObject( "java", "java.io.InputStreamReader").init(socket.getInputStream()) );
				
				while(true){
					line = input.readLine();
					if(not isDefined('line') or line eq -1)
						break;
					result.raw &= line & newLine;
				}

				output.close();
				input.close();
				socket.close();

				// at this point the request is done, we have a result. We just need to parse it
				result.raw = trim(result.raw);
				xmlpos = find("<?xml", result.raw);
				bodypos = find(newLine & newLine, result.raw);
				
				// it has an xml body, just parse out the string correctly, conversion to xml obj is done elsewhere
				if(xmlpos gt 0){
					result.headersRaw = trim(left(result.raw, xmlpos-1));
					result.body = trim(mid(result.raw, xmlpos, len(result.raw)-xmlpos));
				}
				// it has a plain body (as far as we're concerned we handle as plain text..)
				else if(bodypos gt 0){
					result.headersRaw = trim(left(result.raw, bodypos-1));
					result.body = trim(mid(result.raw, bodypos, len(result.raw)-bodypos+1));
				}
				// no body returned
				else{
					result.headersRaw = result.raw;
				}

				// now break down the headers
				result.headers = parseResponse(result.headersRaw);

				return result;
			}
			
			return { error="Could not communicate with host." };
			
		</cfscript>
	</cffunction>

	<!--- 
	#########################################################################
	parseResponse
	@data string of response headers or perhaps an ical
	@nest will prefix the key with the ical segment name "BEGIN:VEVENT"

	returns struct of key/value pairs

	It is likely a coincidence that both headers and ical format somewhat 
	follow a KEY:VALUE (with colon) pairs, so we will share the same func 
	to parse these into a struct.  Beware there may be special cases this 
	may not work as planned
	 --->
	<cffunction name="parseResponse" returntype="struct" access="public" output="false">
		<cfargument name="data" type="string" required="true" />
		<cfargument name="nest" type="boolean" required="false" default="false" />

		<cfscript>
			var newLine = chr(13) & chr(10);
			var results = {};
			var currVal = "";
			var currKey = "";
			var prefix = "";
			var headerRow = "";
			var headerRowLen = 0;
			var headerRowPos = 0;

			for(i=1; i lte listLen(arguments.data, newLine); i++){
				headerRow = ListGetAt(arguments.data, i, newLine);
				headerRow = trim(ReReplace(headerRow, "\;.+\:", ":","all"));
				headerRowLen = Len(headerRow);
				headerRowValPos = find(":", headerRow);

				if(headerRow neq "" and headerRowLen gt headerRowValPos){
					currVal = trim(right(headerRow,headerRowLen-headerRowValPos));
					currKey = lcase(ReReplace(trim(listFirst(headerRow,":")),"\W+","","all"));

					if(arguments.nest and currKey eq "begin"){
						prefix &= lcase(currVal) & "_";
					}
					else if(arguments.nest and currKey eq "end"){
						prefix = replace(prefix, currVal & "_","");
					}
					else{
						results[prefix & currKey] = currVal;
					}
				}
			}

			return results;
		</cfscript>
	</cffunction>

</cfcomponent>