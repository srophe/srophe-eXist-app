xquery version "3.0";

module namespace app="http://syriaca.org/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace teiDocs="http://syriaca.org/teiDocs" at "teiDocs/teiDocs.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";

(:~         
 : Syriaca.org URI for retrieving TEI records 
:)
declare variable $app:id {request:get-parameter('id', '')}; 

(:~  
 : Simple get record function, retrieves tei record based on idno
 : @param $app:id syriaca.org uri 
:)
declare function app:get-rec($node as node(), $model as map(*), $coll as xs:string?) {
if($app:id) then 
    let $id :=
        if(contains(request:get-uri(),'http://syriaca.org/')) then $app:id
        else if($coll = 'places') then concat('http://syriaca.org/place/',$app:id) 
        else if(($coll = 'persons') or ($coll = 'saints') or ($coll = 'authors')) then concat('http://syriaca.org/person/',$app:id)
        else if($coll = 'bhse') then concat('http://syriaca.org/work/',$app:id)
        else if($coll = 'spear') then concat('http://syriaca.org/spear/',$app:id)
        else if($coll = 'mss') then concat('http://syriaca.org/manuscript/',$app:id)
        else $app:id
    return map {"data" := collection($global:data-root)//tei:idno[@type='URI'][. = $id]}
else map {"data" := 'Page data'}    
};

(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : @param $app:id if id is present find TEI title, otherwise use title of sub-module
:)
declare %templates:wrap function app:app-title($node as node(), $model as map(*), $coll as xs:string?){
if($app:id) then
   global:tei2html($model("data")/ancestor::tei:TEI/descendant::tei:title[1]/text())
else if($coll = 'places') then 'The Syriac Gazetteer'  
else if($coll = 'persons') then 'The Syriac Biographical Dictionary'
else if($coll = 'q')then 'Gateway to the Syriac Saints'
else if($coll = 'saints') then 'Gateway to the Syriac Saints: Volume II: Qadishe'
else if($coll = 'bhse') then 'Gateway to the Syriac Saints: Volume I: Bibliotheca Hagiographica Syriaca Electronica'
else if($coll = 'spear') then 'A Digital Catalogue of Syriac Manuscripts in the British Library'
else if($coll = 'mss') then concat('http://syriaca.org/manuscript/',$app:id)
else 'Syriaca.org: The Syriac Reference Portal '
};  

(:~
 : Default title display, used if no sub-module title function. 
:)
declare function app:h1($node as node(), $model as map(*)){
   global:tei2html($model("data")/ancestor::tei:TEI/descendant::tei:title[1])
}; 

(:~ 
 : Default record display, used if no sub-module functions. 
:)
declare %templates:wrap function app:rec-display($node as node(), $model as map(*), $coll as xs:string?){
    global:tei2html($model("data")/ancestor::tei:TEI)
};

declare %templates:wrap function app:set-data($node as node(), $model as map(*), $doc as xs:string){
    teiDocs:generate-docs($global:data-root || '/places/tei/78.xml')
};

(:~
 : Builds page title
 : Otherwise build based on page url
 : @param $metadata:id gets place id from url
 :)
declare %templates:wrap function app:page-title(){
'Title'
};

(:~
 : Builds Dublin Core metadata
 : If id parameter is present use place data to generate metadata
 : @param $metadata:id gets place id from url
 :) 
declare function app:get-dc-metadata(){
    if(exists($id)) then 'get data'
    else ()
};
(:
 : @depreciated
 : use tei2html.xslt
 : Currently used by spear only
:)
declare function app:link-icons-inline($nodes, $resource-id){
<div id="link-icons" class="col-md-4 text-right">
   {
    let $link-title := $nodes//tei:place/tei:placeName[@xml:lang='en'][1] | $nodes//tei:person/tei:persName[@xml:lang='en'][1]
    let $resource-uri := 'place/'
    return 
        (
        app:pleiades-links($nodes/descendant::tei:idno[contains(.,'pleiades')], $link-title,'inline'),
        app:wikipedia-links($nodes/descendant::tei:idno[contains(.,'wikipedia')],'inline'),
        app:google-map-links($nodes/descendant::tei:location[@type='gps']/tei:geo,$link-title,$resource-uri, $resource-id,'inline'),
        <a href="{$resource-uri}/tei" rel="alternate" type="application/tei+xml"><img src="/exist/apps/srophe/resources/img/tei-25.png" alt="The Text Encoding Initiative icon" title="click to view the TEI XML source data for this place"/></a>,
        <a href="{$resource-uri}/atom" rel="alternate" type="application/atom+xml"><img src="/exist/apps/srophe/resources/img/atom-25.png" alt="The Atom format icon" title="click to view this data in Atom XML format"/></a>,
        <a href="javascript:window.print();"><img src="/exist/apps/srophe/resources/img/icons-print.png" alt="The Print format icon" title="click to send this page to the printer"/></a>
        )    
    }
</div>
};

declare function app:link-icons-list($nodes, $resource-id){
<div id="see-also" class="well">
   <h3>See Also</h3>
   {
    let $link-title := $nodes//tei:place/tei:placeName[@xml:lang='en'][1] | $nodes//tei:person/tei:persName[@xml:lang='en'][1]
    let $resource-uri := 'place/'
    return
        <ul>
            {
            (app:pleiades-links($nodes/descendant::tei:idno[contains(.,'pleiades')], $link-title, 'list'),
            app:viaf-links($nodes/descendant::tei:idno[contains(.,'http://viaf.org/')]),
            app:wikipedia-links($nodes/descendant::tei:idno[contains(.,'wikipedia')],'list'),
            app:google-map-links($nodes/descendant::tei:location[@type='gps']/tei:geo, $link-title, $resource-uri, $resource-id,'list')
            )
            }
            <li><a href="{$resource-uri}/tei" rel="alternate" type="application/tei+xml">TEI XML source data for this resource</a></li>
            <li><a href="{$resource-uri}/atom" rel="alternate" type="application/atom+xml">Atom XML format</a></li>
        </ul>   
    }
</div>
};

declare function app:viaf-links($nodes){
for $node in $nodes
return 
   <li><a href="{normalize-space(.)}">VIAF</a></li>
};

declare function app:pleiades-links($nodes, $link-title, $mode){
for $node in $nodes
return 
    if($mode = 'top') then 
        <a href="{normalize-space(.)}"><img src="/exist/apps/srophe/resources/img/circle-pi-25.png" alt="Image of the Greek letter pi in blue; small icon of the Pleiades project" title="click to view {$link-title} in Pleiades"/></a>
    else <li><a href="{normalize-space(.)}">{$link-title} in Pleiades</a></li>
};

declare function app:wikipedia-links($nodes, $mode){
for $node in $nodes
let $title := replace(tokenize(.,'/')[last()],'_',' ')
return 
    if($mode = 'top') then 
        <a href="{normalize-space(.)}"><img src="/exist/apps/srophe/resources/img/Wikipedia-25.png" alt="The Wikipedia icon" title="click to view {$title} in Wikipedia"/></a>
    else <li><a href="{normalize-space(.)}">{$title} in Wikipedia</a></li>        
};

declare function app:google-map-links($nodes, $link-title, $resource-uri, $resource-id, $mode){
for $node in $nodes
return
    if($mode = 'top') then 
        <a href="https://maps.google.com/maps?f=q&amp;hl=en&amp;z=4&amp;q=http://syriaca.org/geo/atom.xql?id={$resource-id}">
            <img src="/exist/apps/srophe/resources/img/gmaps-25.png" alt="The Google Maps icon" title="click to view {$link-title} on Google Maps"/>
        </a>
    else 
    <li>
        <a href="https://maps.google.com/maps?f=q&amp;hl=en&amp;z=4&amp;q=http://syriaca.org/geo/atom.xql?id={$resource-id}">
            {$link-title} on Google Maps
        </a>
    </li> 
};


(:~
 : Generic contact form can be added to any page by calling:
 : <div data-template="app:contact-form"/>
 : with a link to open it that looks like this: 
 : <button class="btn btn-default" data-toggle="modal" data-target="#feedback">CLink text</button>&#160;
:)
declare %templates:wrap function app:contact-form($node as node(), $model as map(*))
{
    <div> 
        <div class="modal fade" id="feedback" tabindex="-1" role="dialog" aria-labelledby="feedbackLabel" aria-hidden="true">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal">
                            <span aria-hidden="true">x</span>
                            <span class="sr-only">Close</span>  
                        </button>
                        <h2 class="modal-title" id="feedbackLabel">Corrections/Additions?</h2>
                    </div>
                    <form action="/exist/apps/srophe/modules/email.xql" method="post" id="email" role="form">
                        <div class="modal-body" id="modal-body">
                            <input type="text" name="name" placeholder="Name" class="form-control" style="max-width:300px"/>
                            <br/>
                            <input type="text" name="email" placeholder="email" class="form-control" style="max-width:300px"/>
                            <br/>
                            <input type="text" name="subject" placeholder="subject" class="form-control" style="max-width:300px"/>
                            <br/>
                            <textarea name="comments" id="comments" rows="3" class="form-control" placeholder="Comments" style="max-width:500px"/>
                            <!-- start reCaptcha API-->
                            <script type="text/javascript" src="http://api.recaptcha.net/challenge?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia"/>
                            <noscript>
                                <iframe src="http://api.recaptcha.net/noscript?k=6Lf1uvESAAAAAPiMWhCCFcyDqj8LVNoBKwkROCia" height="100" width="100" frameborder="0"/>
                                <br/>
                                <textarea name="recaptcha_challenge_field" rows="3" cols="40"/>
                                <input type="hidden" name="recaptcha_response_field" value="manual_challenge"/>
                            </noscript>
                        </div>
                        <div class="modal-footer">
                            <button class="btn btn-default" data-dismiss="modal">Close</button>
                            <input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
                        </div>
                  </form>
          </div>
       </div>
        </div>
   </div> 
};

(:~
 : Grabs latest news for home page
 : http://syriaca.org/feed/
 :)
 
declare %templates:wrap function app:get-feed($node as node(), $model as map(*)){ 
   let $news := doc('http://syriaca.org/blog/feed/')/child::*
   for $latest at $n in subsequence($news//item, 1, 8)
   return 
   <li>
        <a href="{$latest/link/text()}">{$latest/title/text()}</a>
   </li>
};

(:~
 : Typeswitch to transform confessions.xml into nested list.
 : @param $node   
:)
declare function app:transform($nodes as node()*) as item()* {
    for $node in $nodes
    return 
        typeswitch($node)
            case text() return $node
            case comment() return ()
            case element(tei:list) return element ul {app:transform($node/node())}
            case element(tei:item) return element li {app:transform($node/node())}
            case element(tei:label) return element span {app:transform($node/node())}
            default return app:transform($node/node())
};

(:~
 : Pull confession data for confessions.html
:)
declare %templates:wrap function app:build-confessions($node as node(), $model as map(*)){
    let $confession := doc($global:data-root || '/documentation/confessions.xml')//tei:body/child::*[1]
    return app:transform($confession)
};

(:~
 : get editors as distinct values
:)
declare function app:get-editors(){
distinct-values(
    (for $editors in collection($global:data-root || '/places/tei')//tei:respStmt/tei:name/@ref
     return substring-after($editors,'#'),
     for $editors-change in collection($global:data-root || '/places/tei')//tei:change/@who
     return substring-after($editors-change,'#'))
    )
};

(:~
 : Build editor list. Sort alphabeticaly
:)
declare %templates:wrap function app:build-editor-list($node as node(), $model as map(*)){
    let $editors := doc($global:app-root || '/documentation/editors.xml')//tei:listPerson
    for $editor in app:get-editors()
    let $name := 
        for $editor-name in $editors//tei:person[@xml:id = $editor]
        return concat($editor-name/tei:persName/tei:forename,' ',$editor-name/tei:persName/tei:addName,' ',$editor-name/tei:persName/tei:surname)
    let $sort-name :=
        for $editor-name in $editors//tei:person[@xml:id = $editor] return $editor-name/tei:persName/tei:surname
    order by $sort-name
    return
        if($editor != '') then 
            if(normalize-space($name) != '') then 
            <li>{normalize-space($name)}</li>
            else ''
        else ''  
};