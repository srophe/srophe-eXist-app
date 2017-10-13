xquery version "3.1";

(:~
 : Bare-bones resolution service for CTS URNs 
 :)
declare namespace xslt="http://exist-db.org/xquery/transform";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace http="http://expath.org/ns/http-client";

declare option exist:serialize "method=html5 media-type=text/html";

declare variable $cts-registry := doc('cts-registry.xml');

(: Note, we may want to retain a 'registry' for namespaces, either in xml or json :)
(: Get base URL from namespace resolver :)
declare function local:resolve-namespace($ref as xs:string?){
let $namespace := tokenize($ref,':')[3]
return 
    if($cts-registry//namespace[@value = $namespace]) then
        string($cts-registry//namespace[@value = $namespace]/@resolvesTo)
    else <error>ERROR: Failed to resolve namespace {$namespace}. No matching repository in the Syriaca.org registry.</error>
    (:
    if($namespace = 'syriacLit') then (:'http://syriaccorpus.org/':) 'http://localhost:8080/exist/apps/syriac-corpus/'
    else <error>ERROR: Failed to resolve namespace {$namespace}. No matching repository in the Syriaca.org registry.</error>
    :)
};

declare function local:resolve-base-uri($repo as xs:string?){
    if($cts-registry//workIdentifiers[@value = $repo]) then
        string($cts-registry//workIdentifiers[@value = $repo]/@resolvesTo)
    else <error>ERROR: Failed to resolve base uri {$repo}. No matching repository in the Syriaca.org registry. </error>
};

declare function local:resolve-passage($ref){
let $passage := tokenize($ref,':')[5]
return
    if($passage != '') then 
        concat('#id.',replace($passage,'@','.')) 
    else ()
};
declare function local:build-request($ref){
let $work := tokenize($ref,':')[4]
let $workref := tokenize($work,'\.')[last()]
let $repo := replace(replace($workref,'(\D*)(\d*)','$1'),'\s','')
let $idno := replace($workref,'(\D*)(\d*)','$2')
let $url := concat(local:resolve-base-uri($repo),$idno,local:resolve-passage($ref))
return 
    (: Will need error handling :)
    if($repo = 'nhsl') then concat(local:resolve-namespace($ref),'search.html?nhsl-edition=',$url)
    else if($repo = 'bibl') then concat(local:resolve-namespace($ref),'search.html?bibl-edition=',$url)  
    else concat(local:resolve-namespace($ref),tokenize($url,'/')[4]) 
 
};

let $urn := request:get-parameter("urn",())
return 
    if($urn != '') then 
       response:redirect-to(local:build-request($urn))
       (:
       <div>
       <p>urn: {$urn}</p>
       <p>redirect: {local:build-request($urn)}</p>
       </div>
       :)
    else <error>ERROR: no data recieved. </error>  
(:
let $t1 := 'urn:cts:syriacLit:nhsl8501'
let $t2 := 'urn:cts:syriacLit:nhsl8501.nhsl8503'
let $t3 := 'urn:cts:syriacLit:nhsl8501.nhsl8503.syriacCorpus1'
let $t4 := 'urn:cts:syriacLit:nhsl8501.nhsl8503.syriacCorpus1:3.5'
let $t5 := 'urn:cts:syriacLit:nhsl70.nhsl75.syriacCorpus121:5@10'
rn:cts:syriacLit:nhsl70.nhsl75.syriacCorpus121:4.10
let $t6 := 'urn:cts:syriacLit:nhsl8528.nhsl8602.bibl1765'
let $t6alt := 'urn:cts:syriacLit:nhsl8528.nhsl8602.bibl1765 = urn:cts:syriacLit:nhsl8528.nhsl8602.syriacCorpus101'
:)
