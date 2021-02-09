xquery version "3.0";
(:~
 : Increments the latest available uri (syr-id.xml) for syriaca.org data types
 : Used by forms/initialize.xhtml
 : NOTE: Need to add handling for future non numeric URI generation
:)

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
import module namespace functx="http://www.functx.com";
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";
declare option exist:serialize "method=xml media-type=text/xml indent=yes";

(: Get new id node passed from xform, insert new values into syr-id.xml :)
(: Run with elevated privileges :)
let $results := request:get-data()
let $collection := '/db/apps/srophe-admin/forms/services/'
let $file-name := 'syr-ids.xml'
let $current := doc('syr-ids.xml')
let $user := 
    if(request:get-attribute(concat($global:login-domain, '.user'))) then 
        request:get-attribute(concat($global:login-domain, '.user'))
    else ()
return 
<data>{
    if($user != '') then
       if(sm:get-user-groups($user) = ('srophe','dba')) then 
         try {
                 (xmldb:store($collection, $file-name, $results), 
                 <response status="success"><message>URI Reserved.</message></response>)
              }
         catch * {
                 <response status="fail"><message>{concat('There was a problem: ',$err:code, $err:description)}</message></response>
              }
        else <response status="fail"><message>You do not have permission to reserve a URI. Please log in. (Note: You can use the forms and save the TEI XML file without reserving a URI) </message></response>              
    else <response status="fail"><message>You do not have permission to reserve a URI. Please log in. (Note: You can use the forms and save the TEI XML file without reserving a URI) </message></response>            
}</data>
