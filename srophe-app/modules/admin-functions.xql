xquery version "3.0";
(:~
 : @deprecated, use RESTXQ module instead
 : Returns tie xml record
 : @param $id record id
 :)
import module namespace config="http://syriaca.org//config" at "config.xqm";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";

declare variable $id {request:get-parameter('id', '')};

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";

let $path-to-xq := '/db/apps/srophe/modules/get-place-rec.xql'
return
    sm:chmod(xs:anyURI($path-to-xq), 'rwxr-xr-x')