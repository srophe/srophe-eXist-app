xquery version "3.0";
(: Main module for interacting with eXist-db templates :)
module namespace app="http://syriaca.org/templates";
(: eXist modules :)
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://syriaca.org/config" at "config.xqm";
import module namespace functx="http://www.functx.com";
(: Srophe modules :)
import module namespace data="http://syriaca.org/data" at "lib/data.xqm";
import module namespace teiDocs="http://syriaca.org/teiDocs" at "teiDocs/teiDocs.xqm";
import module namespace tei2html="http://syriaca.org/tei2html" at "lib/tei2html.xqm";
import module namespace global="http://syriaca.org/global" at "lib/global.xqm";
import module namespace rel="http://syriaca.org/related" at "lib/get-related.xqm";
import module namespace maps="http://syriaca.org/maps" at "lib/maps.xqm";
import module namespace timeline="http://syriaca.org/timeline" at "lib/timeline.xqm";
(: Namespaces :)
declare namespace http="http://expath.org/ns/http-client";
declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace tei="http://www.tei-c.org/ns/1.0";
  
(:~            
 : Simple get record function, get tei record based on tei:idno
 : Builds URL from the following URL patterns defined in the controller.xql or uses the id paramter
 : Retuns 404 page if record is not found, or has been @depreciated
 : Retuns 404 page and redirects if the record has been @depreciated see https://github.com/srophe/srophe-app-data/wiki/Deprecated-Records
 : @param request:get-parameter('id', '') syriaca.org uri   
:)                 
declare function app:get-rec($node as node(), $model as map(*), $collection as xs:string?) { 
if(request:get-parameter('id', '') != '') then 
    let $id := global:resolve-id()   
    return 
        let $rec := data:get-rec($id)
        return 
            if(empty($rec)) then response:redirect-to(xs:anyURI(concat($global:nav-base, '/404.html')))
            else 
                if($rec/descendant::tei:idno[@type='redirect']) then 
                    let $redirect := 
                            if($rec/descendant::tei:idno[@type='redirect']) then 
                                replace(replace($rec/descendant::tei:idno[@type='redirect'][1],'/tei',''),$global:base-uri,$global:nav-base)
                            else concat($global:nav-base,'/',$collection,'/','browse.html')
                    return 
                    response:redirect-to(xs:anyURI(concat($global:nav-base, '/301.html?redirect=',$redirect)))
                else map {"data" := $rec }  
else map {"data" := <div>'Page data'</div>}    
};

(:~   
 : Default record display. Runs full TEI record through global:tei2html($data/child::*) for HTML display 
 : For more complicated displays page can be configured using eXistdb templates. See a persons or place html page.
 : Or the page can be organized using templates and Srophe functions to extend TEI visualiation to include 
 : dynamic maps, timelines and xquery enhanced relationships.
 : @param $view swap in functions for other page views/layouts
:)
declare function app:display-rec($node as node(), $model as map(*), $collection as xs:string?){
 global:tei2html($model("data"))    
};

(:~  
 : Default title display, used if no sub-module title function.
 : Used by templating module, not needed if full record is being displayed 
:)
declare function app:h1($node as node(), $model as map(*)){
 global:tei2html(
 <srophe-title xmlns="http://www.tei-c.org/ns/1.0">{(
    if($model("data")/descendant::*[@syriaca-tags='#syriaca-headword']) then
        $model("data")/descendant::*[@syriaca-tags='#syriaca-headword']
    else $model("data")/descendant::tei:titleStmt[1]/tei:title[1], 
    $model("data")/descendant::tei:idno[1]
    )}
 </srophe-title>)
}; 
  
(:~  
 : Display any TEI nodes passed to the function via the paths parameter
 : Used by templating module, defaults to tei:body if no nodes are passed. 
 : @param $paths comma separated list of xpaths for display. Passed from html page  
:)
declare function app:link-icons-list($node as node(), $model as map(*)){
let $data := $model("data")//tei:body/descendant::tei:idno[not(contains(., $global:base-uri))]  
return 
    if(not(empty($data))) then 
        <div class="panel panel-default">
            <div class="panel-heading"><h3 class="panel-title">See Also </h3></div>
            <div class="panel-body">
                <ul>
                    {for $l in $data
                     return <li>{global:tei2html($l)}</li>
                    }
                </ul>
            </div>
        </div>
    else ()
}; 

(:~  
 : Display any TEI nodes passed to the function via the paths parameter
 : Used by templating module, defaults to tei:body if no nodes are passed. 
 : @param $paths comma separated list of xpaths for display. Passed from html page  
:)
declare function app:display-nodes($node as node(), $model as map(*), $paths as xs:string?){
    let $data := $model("data")
    return 
        if($paths != '') then 
            global:tei2html(
                    for $p in $paths
                    return util:eval(concat('$data',$p)))
        else global:tei2html($model("data")/descendant::tei:body)
}; 

(:
 : Return tei:body/descendant/tei:bibls for use in sources
:)
declare %templates:wrap function app:display-sources($node as node(), $model as map(*)){
    let $sources := $model("data")/descendant::tei:body/descendant::tei:bibl
    return global:tei2html(<sources xmlns="http://www.tei-c.org/ns/1.0">{$sources}</sources>)
};

(:~
 : Display Series information
 :)
declare %templates:wrap function app:display-series($node as node(), $model as map(*)){
let $series := distinct-values($model("data")/descendant::tei:seriesStmt/tei:biblScope/tei:title)
return 
if($series != '') then 
<div class="panel panel-default">
    <div class="panel-heading"><h3 class="panel-title">Series  
    <span class="glyphicon glyphicon-question-sign text-info moreInfo pull-right" aria-hidden="true" 
    data-toggle="tooltip" 
    title="?"></span></h3></div>
    <div class="panel-body">
        {
        for $f in $series
        return 
            if($f = 'A Guide to Syriac Authors') then
                <p><a href="{$global:nav-base}/authors/index.html">
                    <span class="syriaca-icon syriaca-authors" style="font-size:1.35em; vertical-align: middle;"><span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/></span><span> A Guide to Syriac Authors</span>
                </a></p>
            else if($f = 'The Syriac Biographical Dictionary') then
                <p><a href="{$global:nav-base}/persons/index.html">
                    <span class="syriaca-icon syriaca-sbd" style="font-size:1.35em; vertical-align: middle;"><span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/></span><span class="icon-text">SBD</span>
                </a></p>
            else if($f = 'Qadishe: A Guide to the Syriac Saints') then
                <p><a href="{$global:nav-base}/q/index.html">
                    <span class="syriaca-icon syriaca-q" style="font-size:1.35em; vertical-align: middle;"><span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/></span><span> Qadishe: A Guide to the Syriac Saints</span>
                </a></p>                
            else if($f = 'Bibliotheca Hagiographica Syriaca Electronica') then
               <p><a href="{$global:nav-base}/bhse/index.html">
                    <span class="syriaca-icon syriaca-bhse" style="font-size:1.35em; vertical-align: middle;"><span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/></span><span> Bibliotheca Hagiographica Syriaca Electronica</span>
                </a></p>
            else if($f = 'New Handbook of Syriac Literature') then
               <p><a href="{$global:nav-base}/nhsl/index.html">
                    <span class="syriaca-icon syriaca-nhsl" style="font-size:1.35em; vertical-align: middle;"><span class="path1"/><span class="path2"/><span class="path3"/><span class="path4"/></span><span> New Handbook of Syriac Literature</span>
                </a></p>               
            else ()
        }
    </div>
</div>
else ()
};

(:~    
 : Special output for NHSL work records
:)
declare %templates:wrap function app:display-work($node as node(), $model as map(*)){
        <div class="row">
            <div class="col-md-8 column1">
                {
                    let $data := $model("data")/descendant::tei:body/tei:bibl
                    let $infobox := 
                        <body xmlns="http://www.tei-c.org/ns/1.0">
                        <bibl>
                        {(
                            $data/@*,
                            $data/tei:title[not(@type=('initial-rubric','final-rubric'))],
                            $data/tei:author,
                            $data/tei:editor,
                            $data/tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')],
                            $data/tei:note[@type='abstract'],
                            $data/tei:date,
                            $data/tei:extent,
                            $data/tei:idno[starts-with(.,'http://syriaca.org')]
                         )}
                        </bibl>
                        </body>
                     let $allData := 
                     <body xmlns="http://www.tei-c.org/ns/1.0"><bibl>
                        {(
                            $data/@*,
                            $data/child::*
                            [not(self::tei:title[not(@type=('initial-rubric','final-rubric'))])]
                            [not(self::tei:author)]
                            [not(self::tei:editor)]
                            [not(self::tei:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')])]
                            [not(self::tei:note[@type='abstract'])]
                            [not(self::tei:date)]
                            [not(self::tei:extent)]
                            [not(self::tei:idno)])}
                        </bibl></body>
                     return 
                        (
                        app:work-toc($data),
                        global:tei2html($infobox),
                        app:external-relationships($node, $model,'dct:isPartOf', 'nhsl','',''),
                        app:external-relationships($node, $model,'skos:broadMatch', 'nhsl','',''),
                        app:external-relationships($node, $model,'syriaca:sometimesCirculatesWith','nhsl','',''),
                        app:external-relationships($node, $model,'syriaca:part-of-tradition','nhsl','',''),
                        global:tei2html($allData))  
                } 
            </div>
            <div class="col-md-4 column2">
                {(
                app:rec-status($node, $model,''),
                <div class="info-btns">  
                    <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button>&#160;
                    <a href="#" class="btn btn-default" data-toggle="modal" data-target="#selection" data-ref="../documentation/faq.html" id="showSection">Is this record complete?</a>
                </div>,                
                if($model("data")//tei:body/child::*/tei:listRelation) then 
                rel:build-relationships($model("data")//tei:body/child::*/tei:listRelation, replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''))
                else (),
                app:link-icons-list($node, $model)
                )}  
            </div>
        </div>
};

(:~    
 : Works TOC on bibl elements
:)
declare function app:work-toc($data){
let $data := $data/tei:bibl[@type != ('lawd:Citation','lawd:ConceptualWork')]
return global:tei2html(<work-toc xmlns="http://www.tei-c.org/ns/1.0" >{$data}</work-toc>)
};

(:~
 : Passes any tei:geo coordinates in record to map function. 
 : Suppress map if no coords are found. 
:)                   
declare function app:display-map($node as node(), $model as map(*)){
    if($model("data")//tei:geo) then 
        maps:build-map($model("data"),0)
    else ()
};

(:~
 : Process relationships uses lib/timeline.xqm module
:)                   
declare function app:display-timeline($node as node(), $model as map(*)){
    if($model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter]) then
        <div>                
            <div>{timeline:timeline($model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter], 'Timeline')}</div>
            <div class="indent">
                <h4>Dates</h4>
                <ul class="list-unstyled">
                    {
                        for $date in $model("data")/descendant::tei:body/descendant::*[@when or @notBefore or @notAfter] 
                        return <li>{global:tei2html($date)}</li>
                    }
                </ul> 
            </div>     
        </div>
     else ()
};

(:
 : Return tei:body/descendant/tei:bibls for use in sources
:)
declare %templates:wrap function app:display-citation($node as node(), $model as map(*)){
    global:tei2html(<citation xmlns="http://www.tei-c.org/ns/1.0">{$model("data")//tei:teiHeader | $model("data")//tei:bibl}</citation>) 

};

(:~
 : Process relationships uses lib/rel.xqm module
:)                   
declare function app:display-related($node as node(), $model as map(*), $relType as xs:string?){
    if($relType != '') then 
        rel:build-relationship($model("data")//tei:body/child::*/tei:listRelation, replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''), $relType)
    else if($model("data")//tei:body/child::*/tei:listRelation) then 
            rel:build-relationships($model("data")//tei:body/child::*/tei:listRelation, replace($model("data")//tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei',''))
    else ()
};

(:~      
 : Get relations to display in body of HTML page
 : Used by NHSL for displaying child works
 : @param $data TEI record
 : @param $relType name/ref of relation to be displayed in HTML page
:)
declare %templates:wrap function app:external-relationships($node as node(), $model as map(*), $relType, $collection, $sort, $count){
let $rec := $model("data")
let $relType := $relType 
let $recid := replace($rec/descendant::tei:idno[@type='URI'][starts-with(.,$global:base-uri)][1],'/tei','')
let $title := if(contains($rec/descendant::tei:title[1]/text(),' — ')) then 
                    substring-before($rec/descendant::tei:title[1],' — ') 
               else $rec/descendant::tei:title[1]/text()
return rel:external-relationships($recid, $title, $relType, $collection, $sort, $count)
};
   
(:~
 : bibl module relationships
:)                   
declare function app:subject-headings($node as node(), $model as map(*)){
    rel:subject-headings($model("data")//tei:idno[@type='URI'][ends-with(.,'/tei')])
};

(:~
 : bibl modulerelationships
:)                   
declare function app:cited($node as node(), $model as map(*)){
    rel:cited($model("data")//tei:idno[@type='URI'][ends-with(.,'/tei')], request:get-parameter('start', 1),request:get-parameter('perpage', 5))
};

(:~      
 : Return teiHeader info to be used in citation used for Syriaca.org bibl module
:)
declare %templates:wrap function app:d($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $header := 
        <srophe-about xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader}
        </srophe-about>
    return global:tei2html($header)
};

(:~      
 : Return teiHeader info to be used in citation used for Syriaca.org bibl module
:)
declare %templates:wrap function app:about($node as node(), $model as map(*)){
    let $rec := $model("data")
    let $header := 
        <srophe-about xmlns="http://www.tei-c.org/ns/1.0">
            {$rec//tei:teiHeader}
        </srophe-about>
    return global:tei2html($header)
};

(:~  
 : Record status to be displayed in HTML sidebar 
 : Data from tei:teiHeader/tei:revisionDesc/@status
:)
declare %templates:wrap  function app:rec-status($node as node(), $model as map(*), $collection as xs:string?){
let $status := string($model("data")/descendant::tei:revisionDesc/@status)
return
    if($status = 'published' or $status = '') then ()
    else
    <span class="rec-status {$status} btn btn-info">Status: {$status}</span>
};

(:~
 : Dynamically build html title based on TEI record and/or sub-module. 
 : @param request:get-parameter('id', '') if id is present find TEI title, otherwise use title of sub-module
:)
declare %templates:wrap function app:app-title($node as node(), $model as map(*), $collection as xs:string?){
if(request:get-parameter('id', '')) then
   if(contains($model("data")/descendant::tei:titleStmt[1]/tei:title[1]/text(),' — ')) then
        substring-before($model("data")/descendant::tei:titleStmt[1]/tei:title[1],' — ')
   else $model("data")/descendant::tei:titleStmt[1]/tei:title[1]/text()
else if($collection = 'places') then 'The Syriac Gazetteer'  
else if($collection = 'persons') then 'The Syriac Biographical Dictionary'
else if($collection = 'saints')then 'Gateway to the Syriac Saints'
else if($collection = 'q') then 'Gateway to the Syriac Saints: Volume II: Qadishe'
else if($collection = 'bhse') then 'Gateway to the Syriac Saints: Volume I: Bibliotheca Hagiographica Syriaca Electronica'
else if($collection = 'spear') then 'A Digital Catalogue of Syriac Manuscripts in the British Library'
else if($collection = 'mss') then concat('http://syriaca.org/manuscript/',request:get-parameter('id', ''))
else $global:app-title
};  

(:~ 
 : Add header links for alternative formats. 
:)
declare function app:metadata($node as node(), $model as map(*)) {
    if(request:get-parameter('id', '')) then 
    (
    (: some rdf examples
    <link type="application/rdf+xml" href="id.rdf" rel="alternate"/>
    <link type="text/turtle" href="id.ttl" rel="alternate"/>
    <link type="text/plain" href="id.nt" rel="alternate"/>
    <link type="application/json+ld" href="id.jsonld" rel="alternate"/>
    :)
    <meta name="DC.title " property="dc.title " content="{$model("data")/ancestor::tei:TEI/descendant::tei:title[1]/text()}"/>,
    if($model("data")/ancestor::tei:TEI/descendant::tei:desc or $model("data")/ancestor::tei:TEI/descendant::tei:note[@type="abstract"]) then 
        <meta name="DC.description " property="dc.description " content="{$model("data")/ancestor::tei:TEI/descendant::tei:desc[1]/text() | $model("data")/ancestor::tei:TEI/descendant::tei:note[@type="abstract"]}"/>
    else (),
    <link xmlns="http://www.w3.org/1999/xhtml" type="text/html" href="{request:get-parameter('id', '')}.html" rel="alternate"/>,
    <link xmlns="http://www.w3.org/1999/xhtml" type="text/xml" href="{request:get-parameter('id', '')}/tei" rel="alternate"/>,
    <link xmlns="http://www.w3.org/1999/xhtml" type="application/atom+xml" href="{request:get-parameter('id', '')}/atom" rel="alternate"/>
    )
    else ()
};

(:~
 : Generic contact form can be added to any page by calling:
 : <div data-template="app:contact-form"/>
 : with a link to open it that looks like this: 
 : <button class="btn btn-default" data-toggle="modal" data-target="#feedback">CLink text</button>&#160;
:)
declare %templates:wrap function app:contact-form($node as node(), $model as map(*), $collection)
{
<div class="modal fade" id="feedback" tabindex="-1" role="dialog" aria-labelledby="feedbackLabel" aria-hidden="true" xmlns="http://www.w3.org/1999/xhtml">
    <div class="modal-dialog">
        <div class="modal-content">
        <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">x</span><span class="sr-only">Close</span></button>
            <h2 class="modal-title" id="feedbackLabel">Corrections/Additions?</h2>
        </div>
        <form action="{$global:nav-base}/modules/email.xql" method="post" id="email" role="form">
            <div class="modal-body" id="modal-body">
                <!-- More information about submitting data from howtoadd.html -->
                <p><strong>Notify the editors of a mistake:</strong>
                <a class="btn btn-link togglelink" data-toggle="collapse" data-target="#viewdetails" data-text-swap="hide information">more information...</a>
                </p>
                <div class="container">
                    <div class="collapse" id="viewdetails">
                    <p>Using the following form, please inform us which page URI the mistake is on, where on the page the mistake occurs,
                    the content of the correction, and a citation for the correct information (except in the case of obvious corrections, such as misspelled words). 
                    Please also include your email address, so that we can follow up with you regarding 
                    anything which is unclear. We will publish your name, but not your contact information as the author of the  correction.</p>
                    <h4>Add data to an existing entry</h4>
                    <p>The Syriac Gazetteer is an ever expanding resource  created by and for users. The editors actively welcome additions to the gazetteer. If there is information which you would like to add to an existing place entry in The Syriac Gazetteer, please use the link below to inform us about the information, your (primary or scholarly) source(s) 
                    for the information, and your contact information so that we can credit you for the modification. For categories of information which  The Syriac Gazetteer structure can support, please see the section headings on the entry for Edessa and  specify in your submission which category or 
                    categories this new information falls into.  At present this information should be entered into  the email form here, although there is an additional  delay in this process as the data needs to be encoded in the appropriate structured data format  and assigned a URI. A structured form for submitting  new entries is under development.</p>
                    </div>
                </div>
                <input type="text" name="name" placeholder="Name" class="form-control" style="max-width:300px"/>
                <br/>
                <input type="text" name="email" placeholder="email" class="form-control" style="max-width:300px"/>
                <br/>
                <input type="text" name="subject" placeholder="subject" class="form-control" style="max-width:300px"/>
                <br/>
                <textarea name="comments" id="comments" rows="3" class="form-control" placeholder="Comments" style="max-width:500px"/>
                <input type="hidden" name="id" value="{request:get-parameter('id', '')}"/>
                <input type="hidden" name="collection" value="{$collection}"/>
                <!-- start reCaptcha API-->
                <div class="g-recaptcha" data-sitekey="{$global:recaptcha}"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-default" data-dismiss="modal">Close</button><input id="email-submit" type="submit" value="Send e-mail" class="btn"/>
            </div>
        </form>
        </div>
    </div>
</div>
};

(:~
 : Grabs latest news for Syriaca.org home page
 : http://syriaca.org/feed/
 :) 
declare %templates:wrap function app:get-feed($node as node(), $model as map(*)){
    try {
        if(doc('http://syriaca.org/blog/feed/')/child::*) then 
            let $news := doc('http://syriaca.org/blog/feed/')/child::*
            for $latest at $n in subsequence($news//item, 1, 3)
            return 
                <li>
                     <a href="{$latest/link/text()}">{$latest/title/text()}</a>
                </li>
        else ()
       } catch * {
           <error>Caught error {$err:code}: {$err:description}</error>
    }     
};

(:~ 
 : Used by teiDocs
:)
declare %templates:wrap function app:set-data($node as node(), $model as map(*), $doc as xs:string){
    teiDocs:generate-docs($global:data-root || '/places/tei/78.xml')
};

(:~
 : Generic output documentation from xml
 : @param $doc as string
:)
declare %templates:wrap function app:build-documentation($node as node(), $model as map(*), $doc as xs:string?){
    let $doc := doc($global:app-root || '/documentation/' || $doc)//tei:encodingDesc
    return tei2html:tei2html($doc)
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

(:~
 : Dashboard function outputs collection statistics. 
 : $data collection data
 : $collection-title title of sub-module/collection
 : $data-dir 
:)
declare %templates:wrap function app:dashboard($node as node(), $model as map(*), $collection-title, $data-dir){
    let $data := 
        if($collection-title != '') then 
            collection($global:data-root || '/' || $data-dir || '/tei')//tei:title[. = $collection-title]
        else collection($global:data-root || '/' || $data-dir || '/tei')//tei:title[@level='a'][parent::tei:titleStmt] 
            
    let $data-type := if($data-dir) then $data-dir else 'data'
    let $rec-num := count($data)
    let $contributors := for $contrib in distinct-values(for $contributors in $data/ancestor::tei:TEI/descendant::tei:respStmt/tei:name return $contributors) return <li>{$contrib}</li>
    let $contrib-num := count($contributors)
    let $data-points := count($data/ancestor::tei:TEI/descendant::tei:body/descendant::text())
    return
    <div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
        <div class="panel panel-default">
            <div class="panel-heading" role="tab" id="dashboardOne">
                <h4 class="panel-title">
                    <a role="button" data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="true" aria-controls="collapseOne">
                        <i class="glyphicon glyphicon-dashboard"></i> {concat(' ',$collection-title,' ')} Dashboard
                    </a>
                </h4>
            </div>
            <div id="collapseOne" class="panel-collapse collapse in" role="tabpanel" aria-labelledby="dashboardOne">
                <div class="panel-body dashboard">
                    <div class="row" style="padding:2em;">
                        <div class="col-md-4">
                            <div class="panel panel-primary">
                                <div class="panel-heading">
                                    <div class="row">
                                        <div class="col-xs-3"><i class="glyphicon glyphicon-file"></i></div>
                                        <div class="col-xs-9 text-right">
                                            <div class="huge">{$rec-num}</div><div>{$data-dir}</div>
                                        </div>
                                    </div>
                                </div>
                                <div class="collapse panel-body" id="recCount">
                                    <p>This number represents the count of {$data-dir} currently described in <i>{$collection-title}</i> as of {current-date()}.</p>
                                    <span><a href="browse.html"> See records <i class="glyphicon glyphicon-circle-arrow-right"></i></a></span>
                                </div>
                                <a role="button" 
                                    data-toggle="collapse" 
                                    href="#recCount" 
                                    aria-expanded="false" 
                                    aria-controls="recCount">
                                    <div class="panel-footer">
                                        <span class="pull-left">View Details</span>
                                        <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="panel panel-success">
                                <div class="panel-heading">
                                    <div class="row">
                                        <div class="col-xs-3"><i class="glyphicon glyphicon-user"></i></div>
                                        <div class="col-xs-9 text-right"><div class="huge">{$contrib-num}</div><div>Contributors</div></div>
                                    </div>
                                </div>
                                <div class="panel-body collapse" id="contribCount">
                                    {(
                                    <p>This number represents the count of contributors who have authored or revised an entry in <i>{$collection-title}</i> as of {current-date()}.</p>,
                                    <ul style="padding-left: 1em;">{$contributors}</ul>)} 
                                    
                                </div>
                                <a role="button" 
                                    data-toggle="collapse" 
                                    href="#contribCount" 
                                    aria-expanded="false" 
                                    aria-controls="contribCount">
                                    <div class="panel-footer">
                                        <span class="pull-left">View Details</span>
                                        <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="panel panel-info">
                                <div class="panel-heading">
                                    <div class="row">
                                        <div class="col-xs-3"><i class="glyphicon glyphicon-stats"></i></div>
                                        <div class="col-xs-9 text-right"><div class="huge"> {$data-points}</div><div>Data points</div></div>
                                    </div>
                                </div>
                                <div id="dataPoints" class="panel-body collapse">
                                    <p>This number is an approximation of the entire data, based on a count of XML text nodes in the body of each TEI XML document in the <i>{$collection-title}</i> as of {current-date()}.</p>  
                                </div>
                                <a role="button" 
                                data-toggle="collapse" 
                                href="#dataPoints" 
                                aria-expanded="false" 
                                aria-controls="dataPoints">
                                    <div class="panel-footer">
                                        <span class="pull-left">View Details</span>
                                        <span class="pull-right"><i class="glyphicon glyphicon-circle-arrow-right"></i></span>
                                        <div class="clearfix"></div>
                                    </div>
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
};

(:~
 : Pulls github wiki data into Syriaca.org documentation pages. 
 : @param $wiki-uri pulls content from specified wiki or wiki page. 
:)
declare function app:get-wiki($wiki-uri as xs:string?){
    http:send-request(
            <http:request href="{xs:anyURI($wiki-uri)}" method="get">
                <http:header name="Connection" value="close"/>
            </http:request>)[2]//html:div[@class = 'repository-content']            
};

(:~
 : Pulls github wiki data H1.  
:)
declare function app:wiki-page-title($node, $model){
    let $wiki-uri := 
        if(request:get-parameter('wiki-uri', '')) then 
            request:get-parameter('wiki-uri', '')
        else 'https://github.com/srophe/srophe-eXist-app/wiki' 
    let $uri := 
        if(request:get-parameter('wiki-page', '')) then 
            concat($wiki-uri, request:get-parameter('wiki-page', ''))
        else $wiki-uri
    let $wiki-data := app:get-wiki($uri)
    let $content := $wiki-data//html:div[@id='wiki-body']
    return $wiki-data/descendant::html:h1[1]
};

(:~
 : Pulls github wiki content.  
:)
declare function app:wiki-page-content($node, $model){
    let $wiki-uri := 
        if(request:get-parameter('wiki-uri', '')) then 
            request:get-parameter('wiki-uri', '')
        else 'https://github.com/srophe/srophe-eXist-app/wiki' 
    let $uri := 
        if(request:get-parameter('wiki-page', '')) then 
            concat($wiki-uri, request:get-parameter('wiki-page', ''))
        else $wiki-uri
    let $wiki-data := app:get-wiki($uri)
    return $wiki-data//html:div[@id='wiki-body'] 
};

(:~
 : Pull github wiki data into Syriaca.org documentation pages. 
 : Grabs wiki menus to add to Syraica.org pages
 : @param $wiki pulls content from specified wiki or wiki page. 
:)
declare function app:wiki-menu($node, $model, $wiki){
    let $wiki-data := app:get-wiki($wiki)
    let $menu := app:wiki-links($wiki-data//html:div[@id='wiki-rightbar']/descendant::*:ul[@class='wiki-pages'], $wiki)
    return $menu
};

(:~
 : Typeswitch to processes wiki menu links for use with Syriaca.org documentation pages. 
 : @param $wiki pulls content from specified wiki or wiki page. 
:)
declare function app:wiki-links($nodes as node()*, $wiki) {
    for $node in $nodes
    return 
        typeswitch($node)
            case element(html:a) return
                let $wiki-path := substring-after($wiki,'https://github.com')
                let $href := concat($global:nav-base, replace($node/@href, $wiki-path, "/documentation/wiki.html?wiki-page="),'&amp;wiki-uri=', $wiki)
                return
                    <a href="{$href}">
                        {$node/@* except $node/@href, $node/node()}
                    </a>
            case element() return
                element { node-name($node) } {
                    $node/@*, app:wiki-links($node/node(), $wiki)
                }
            default return
                $node               
};

(:~
 : display keyboard menu 
:)
declare function app:keyboard-select-menu($node, $model, $input-id){
    global:keyboard-select-menu($input-id)
};

(:~ 
 : Enables shared content with template expansion.  
 : Used for shared menus in navbar where relative links can be problematic 
 : @param $node
 : @param $model
 : @param $path path to html content file, relative to app root. 
:)
declare function app:shared-content($node as node(), $model as map(*), $path as xs:string){
    let $links := doc($global:app-root || $path)
    return templates:process(global:fix-links($links/node()), $model)
};

(:~                   
 : Traverse main nav and "fix" links based on values in config.xml
 : Replaces $app-root with vaule defined in config.xml. 
 : This allows for more flexible deployment for dev and production environments.   
:)
declare
    %templates:wrap
function app:fix-links($node as node(), $model as map(*)) {
    templates:process(global:fix-links($node/node()), $model)
};

(:~ 
 : Adds google analytics from config.xml
 : @param $node
 : @param $model
 : @param $path path to html content file, relative to app root. 
:)
declare  
    %templates:wrap 
function app:google-analytics($node as node(), $model as map(*)){
   $global:get-config//google_analytics/text() 
};