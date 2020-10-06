xquery version "3.1";
(:~  
 : Basic data interactions, returns raw data for use in other modules  
 : Used by browse, search, and view records.  
 :
 : @see lib/facet.xqm for facets
 : @see lib/paging.xqm for sort options
 : @see lib/global.xqm for global variables 
 :)
 

import module namespace config="http://syriaca.org/srophe/config" at "config.xqm";
import module namespace cntneg="http://syriaca.org/srophe/cntneg" at "content-negotiation/content-negotiation.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $collection :=  request:get-parameter("collection", ())
let $format :=  request:get-parameter("format", ())
let $collection-path := 
            if(config:collection-vars($collection)/@data-root != '') then concat('/',config:collection-vars($collection)/@data-root)
            else if($collection != '') then concat('/',$collection)
            else ()
let $data := if($collection != '') then
                  collection($config:data-root || $collection-path)
             else collection($config:data-root)
let $request-format := if($format != '') then $format else 'xml'
return cntneg:content-negotiation($data, $request-format,())
 