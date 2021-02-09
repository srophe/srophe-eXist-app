xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:media-type "text/xml";


declare variable $id {request:get-parameter('id', '')};
declare variable $type {request:get-parameter('type', '')};

if($id != '') then 
    let $record := collection($global:data-root)//tei:idno[@type='URI'][. = $id]
    return 
        if(not(empty($record))) then root($record) 
        else if($type = 'keyword') then
            doc('../xml-templates/entryFree.xml')
        else if($type = 'person') then
            doc('../xml-templates/person.xml')
        else if($type = 'place') then
            doc('../xml-templates/place.xml')
        else doc('../xml-templates/tei-template.xml')
else doc('../xml-templates/tei-template.xml')
(:root(collection($global:data-root)//tei:idno[@type='URI'][. = $id]):)

(:

if($id != '') then 
    root(collection($global:data-root)//tei:idno[@type='URI'][. = $id])
else 
    doc('../xml-templates/tei-template.xml')




:)
