<cfset host = ""> <!--- Something like: 'domain.com' --->
<cfset port = 80> <!--- https or ssl will likely be 443, http or tcp will likely be 80 --->
<cfset path = ""> <!--- Something like: /calendars/DOMAIN/USER/Calendar/ --->
<cfset username = ""> <!--- you know what to do with these two.. --->
<cfset password = "">

<cfset cdc = CreateObject('component','caldav').init(host=host,port=port,path=path,username=username,password=password)>

<!--- 
###########################################################################
Try getting options
 --->
<!--- 
<cfset myEvent = cdc.options()>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try adding an event
 --->
<!--- 
<cfsavecontent variable="myICal">BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
DTSTAMP:20111228T211811Z
DTSTART:201206015T000000Z
DTEND:201206015T000000Z
UID:test-event-123456
DESCRIPTION:My event description details
LOCATION:Office
SUMMARY:My Event Title 2.1
END:VEVENT
END:VCALENDAR
</cfsavecontent>
<cfset myEvent = cdc.edit("test-event-123456.ics", myICal)>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try deleteing an event
 --->
<!--- 
<cfset myEvent = cdc.delete("test-event-123456.ics")>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try getting an event
 --->
<!--- 
<cfset myEvent = cdc.get("test-event-123456.ics")>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try getting events
 --->
 
<cfset myEvent = cdc.getEvents("20120701T000000Z","20120801T000000Z", true,"","","","struct")>
<cfdump var="#myEvent#">


<!--- 
###########################################################################
Try querying for event by uid
 --->
<!--- 
<cfset myEvent = cdc.getEventByUid("my-test-uid-123456")>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try getting todos
 --->
<!--- 
<cfset myEvent = cdc.getTodos("20120601T000000Z","20120701T000000Z", true,"", "STATUS:COMPLETED,STATUS:CANCELLED","","struct")>
<cfdump var="#myEvent#">
 --->

<!--- 
###########################################################################
Try querying for todo by uid
 --->
<!--- 
<cfset myEvent = cdc.getTodoByUid("my-test-uid-123456")>
<cfdump var="#myEvent#">
 --->
