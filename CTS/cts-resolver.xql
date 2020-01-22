xquery version "3.1";

(:~
 : Bare-bones resolution service for CTS URNs for Syriaca.org and The Oxford-BYU Syriac Corpus
 : @author Syriaca.org
 : @param $urn The CTS URN to be resolved.
 : @param $action The return type. 
    Available actions: 
        - 'html' [Returns the html referenced text block]
        - 'xml' [Returns the xml referenced text block]
        - 'redirect' [Sends users to HTML page]
 :)
 
import module namespace cts="http://syriaca.org/cts" at "cts-resolver.xqm";

let $ref := request:get-parameter("urn",())
let $action := request:get-parameter("action",())
return 
    (response:set-header("Access-Control-Allow-Origin", "*"),
     response:set-header("Access-Control-Allow-Methods", "GET, POST"),
     response:set-header("Content-Type", "text/xml"),cts:run($ref, $action))