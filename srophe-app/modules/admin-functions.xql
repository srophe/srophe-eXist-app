xquery version "3.0";
(:~
 : Used for testing on production server.
 :)
import module namespace xrest="http://exquery.org/ns/restxq/exist" at "java:org.exist.extensions.exquery.restxq.impl.xquery.exist.ExistRestXqModule";

declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace atom="http://www.w3.org/2005/Atom";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace transform="http://exist-db.org/xquery/transform";
declare namespace request="http://exist-db.org/xquery/request";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";
'temp'
(:
let $path-to-xq := '/db/apps/srophe/modules/get-place-rec.xql'
return
    sm:chmod(xs:anyURI($path-to-xq), 'rwxr-xr-x')
    xrest:register-module(xs:anyURI('/db/apps/srophe/modules/rest.xqm'))
    exrest:deregister-module(xs:anyURI('/db/apps/srophe/modules/rest.xqm'))
    :)
    (:exrest:deregister-module(xs:anyURI('/db/apps/srophe/modules/rest.xqm')):)
    rest:resource-functions()
    (:xrest:register-module(xs:anyURI('/db/apps/srophe/modules/rest.xqm')):)
