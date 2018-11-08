xquery version "3.0";

import module namespace http="http://expath.org/ns/http-client";

(:
 : Take posted SPARQL query and send it to Syriaca.org sparql endpoint
 : Returns JSON
 : This will hopefully get around the javascript issues with http/https and same origin.
:)
let $query := if(request:get-parameter('query', '')) then  request:get-parameter('query', '')
              else if(not(empty(request:get-data()))) then request:get-data()
              else ()
let $subject-sparql-results := 
    try{
        util:base64-decode(http:send-request(<http:request href="http://wwwb.library.vanderbilt.edu/exist/apps/srophe/api/sparql?format=json&amp;query={fn:encode-for-uri($query)}" method="get"/>)[2])
    } catch * {<error>Caught error {$err:code}: {$err:description}</error>}       
              
return (response:set-header("Content-Type", "application/json"),$subject-sparql-results)

let $flickr-api-key := doc($config:app-root || '/config.xml')//*:flickr-api-key/text()
let $imageID := tokenize($imageURL,'/')[last()]
let $id := tokenize($imageID,'_')[1]
let $secret := tokenize($imageID,'_')[2]
let $request-url := 
        concat('https://api.flickr.com/services/rest/?method=flickr.photos.getInfo&amp;api_key=',$flickr-api-key,'&amp;photo_id=',$id,'&amp;secret=',$secret)
return              
        try{
           let $response := 
                http:send-request(<http:request http-version="1.1" href="{xs:anyURI($request-url)}" method="get">
                             <http:header name="Connection" value="close"/>
                           </http:request>)[2]
            let $desc :=  $response/descendant::description/text()
            let $title := $response/descendant::title/text()
            let $photo-page := $response/descendant::url[@type="photopage"]/text()
            return 
                <span class="{$image-class}">
                     <a href="{$imageURL}" target="_blank">
                         <span class="helper"></span>
                         {
                            if($image-class = 'thumb-images') then <img src="{replace($imageURL,'b.jpg','t.jpg')}"/>
                            else <img src="{$imageURL}" />
                         }
                     </a>
                     <div class="caption">{if($desc != '') then $desc else $title}</div>
                </span>  
        } catch* {
                    <response status="fail">
                        <message>{concat($err:code, ": ", $err:description)} {$request-url}</message>
                    </response>
        }    
 