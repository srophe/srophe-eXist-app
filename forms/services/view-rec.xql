xquery version "3.0";
(:~
 : Submit new data to data folder for review
 : Send email alert to appropriate editor?
:)
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "xml";
declare option output:media-type "text/xml";

declare variable $path {request:get-parameter('path', '')};

let $cache := 'change value to force refresh: 344'
let $id :=
   if (exists($path))
      then $path
   else 'data/new.xml'
return doc($id)