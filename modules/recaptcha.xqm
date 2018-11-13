xquery version "3.0";

module namespace recap="http://www.exist-db.org/xquery/util/recapture";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";
declare namespace httpclient = "http://exist-db.org/xquery/httpclient";
declare variable $recap:VALIDATE_URI as xs:anyURI := xs:anyURI("https://www.google.com/recaptcha/api/siteverify");

(:~
: Module for working with reCaptcha
:)
declare function recap:validate($private-key as xs:string, $recaptcha-response as xs:string) 
{
(: let $client-ip := request:get-remote-addr(), :)
    let $client-ip := request:get-header("X-Real-IP"),        (: if behind 
webserver proxy :)
     $post-fields := 
       <httpclient:fields>
            <httpclient:field name="secret" value="{$private-key}"/>            
            <httpclient:field name="response" value="{$recaptcha-response}"/>
            <httpclient:field name="remoteip" value="{$client-ip}"/>
        </httpclient:fields> return
    
        let $response := httpclient:post-form($recap:VALIDATE_URI, $post-fields, false(), ()) 
        return xqjson:parse-json(util:base64-decode($response))
        (:
            let $recapture-response := xqjson:parse-json(util:base64-decode($response))//text()
            return
                if(starts-with($recapture-response, "true"))then
                (
                    true()
                )
                else
                (
                    (: util:log("debug", concat("reCaptcha response='", $capture-response, "'")), :)    
                    (: uncomment to debug reCaptcha response :)
                    false()
                )
                :)
};