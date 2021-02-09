xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
import module namespace global="http://syriaca.org/global" at "../../modules/lib/global.xqm";

declare variable $id {request:get-parameter('id', '')};
declare variable $type {request:get-parameter('type', '')};
declare variable $new {request:get-parameter('new', '')};

let $cache := 'change value to force refresh: 344'

return
if($new != '') then
    if($type= 'person') then doc('/db/apps/srophe-forms/forms/xml-templates/person.xml')
    else if($type = 'place') then doc('/db/apps/srophe-forms/forms/xml-templates/place.xml')
    else doc('/db/apps/srophe-forms/forms/xml-templates/template.xml')
else if ($id != '') then
    for $rec in collection($global:data-root)//tei:idno[@type='URI'][. = $id]/ancestor::tei:TEI
    return $rec
else
    if($type= 'person') then doc('/db/apps/srophe-forms/forms/xml-templates/person.xml')
    else if($type = 'place') then doc('/db/apps/srophe-forms/forms/xml-templates/place.xml')
    else doc('/db/apps/srophe-forms/forms/xml-templates/template.xml')
