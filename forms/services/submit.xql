xquery version "3.1";
(:~
 : Submit xforms generated data
 : @param $type options view (view xml in new window), download (download xml without saving), save (save to db, only available to logged in users)
:)
import module namespace config="http://srophe.org/srophe/config" at "../../modules/config.xqm";
import module namespace gitcommit="http://syriaca.org/srophe/gitcommit" at "git-commit.xql";
import module namespace http="http://expath.org/ns/http-client";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace httpclient="http://exist-db.org/xquery/httpclient";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.json.org";

declare option output:method "xml";
declare option output:media-type "text/xml";

(: Any post processing to TEI form data happens here :)
declare function local:transform($nodes as node()*) as item()* {
  for $node in $nodes
  let $type := if($node/ancestor::tei:TEI/descendant::tei:body/tei:entryFree) then'keyword'  else 'place' 
  let $generateID := $node/ancestor::tei:TEI/descendant::tei:body/child::*[1]/tei:idno[@type='URI'][not(empty(.))][1]
  let $URI := if(starts-with($generateID, $config:base-uri)) then $generateID 
              else concat($config:base-uri,'/',$type,'/',$generateID)
  let $id := tokenize($URI,'/')[last()] 
  return 
    typeswitch($node)
        case processing-instruction() return $node 
        case comment() return $node 
        case text() return local:transformTextXML(parse-xml-fragment($node))
        case element(tei:TEI) return 
            <TEI xmlns="http://www.tei-c.org/ns/1.0">
                {($node/@*[. != ''], local:transform($node/node()))}
            </TEI>
        case element(tei:change) return
            if($node[@who = 'online-submission']) then 
                element { local-name($node) }
                    { 
                        attribute who { '#onlineForms' },
                        attribute when { current-date() },
                        concat($node/ancestor::tei:TEI/descendant::tei:respStmt[1]/tei:name,', ', $node/ancestor::tei:TEI/descendant::tei:respStmt[1]/tei:comments)
                    }
            else if($node[@who = '' and @when = '']) then
                element { local-name($node) } 
                    { 
                        attribute who { '#onlineForms' },
                        attribute when { current-date() },
                        'Record created by Architectura Sinica webforms'
                    }
            else local:passthru($node)
        case element(tei:entryFree) return
                element { local-name($node) } 
                    {($node/@*[. != '' and not(name(.) = 'xml:id')], attribute xml:id  {$id}, local:transform($node/node()))}    
        case element(tei:idno) return                         
                if($node/parent::tei:publicationStmt) then
                    element { local-name($node) } 
                        {   $node/@*,
                            concat($URI,'/tei')
                        }
                else if($node/parent::tei:entryFree) then
                    element { local-name($node) } 
                        {   $node/@*,
                            $URI
                        }
                else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:persName) return
            if($node/parent::tei:person) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id') and not(name(.) = 'source')],
                        attribute xml:id { concat('name',$id,'-',
                        count($node/preceding-sibling::*[local-name(.) = 'term']) + 1) },
                        if($node/@source[. != '']) then 
                            attribute source { concat('#bibl',$id,'-', $node/@source)}
                        else (),
                        local:transform($node/node())
                    }
            else 
                element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:placeName) return
            if($node/parent::tei:place) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id') and not(name(.) = 'source')],
                        attribute xml:id { concat('name',$id,'-',
                        count($node/preceding-sibling::*[local-name(.) = 'term']) + 1) },
                        if($node/@source[. != '']) then 
                            attribute source { concat('#bibl',$id,'-', $node/@source)}
                        else (),
                        local:transform($node/node())
                    }
            else 
                element { local-name($node) } {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:relation) return
                if($node[@ref="foaf:depicts"]) then 
                    element { local-name($node) } {($node/@*[. != ''], attribute passive {$URI}, local:transform($node/node()))}
                else if($node[@ref="skos:broadMatch"]) then
                    element { local-name($node) } {($node/@*[. != ''], attribute active {$URI}, local:transform($node/node()))}
                else 
                    element { local-name($node) } {($node/@*[. != ''], 
                        if($node/@active = '') then  
                           attribute active {$URI} 
                        else if($node/@passive = '') then  
                            attribute passive {$URI} 
                       else (),
                       local:transform($node/node()))}
        case element(tei:respStmt) return 
            if($node/tei:comments) then
                 element {local-name($node) } {($node/@*[. != ''], local:transform($node/tei:resp), local:transform($node/tei:name))}
            else local:passthru($node)
        case element(tei:term) return
            if($node/parent::tei:entryFree) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id') and not(name(.) = 'source')],
                        attribute xml:id { concat('term',$id,'-',
                        count($node/preceding-sibling::*[local-name(.) = 'term']) + 1) },
                        if($node/@source[. != '']) then 
                            attribute source { concat('#bibl',$id,'-', $node/@source)}
                        else (),
                        local:transform($node/node())
                    }
            else 
                element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:title) return
            if($node/parent::tei:bibl[parent::tei:body]) then 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',$id,'-',
                        count($node/preceding-sibling::*[local-name(.) = 'title']) + 1) },
                        local:transform($node/node())
                    }
            else if($node/parent::tei:bibl[not(parent::tei:body)]) then 
                if($node[@level='citation']) then ()
                else 
                  element { local-name($node) } 
                    {   $node/@*[. != '' and not(name(.) = 'xml:id')],
                        attribute xml:id { 
                        concat('name',$id,'-',
                        count($node/preceding-sibling::*[local-name(.) = 'title']) + 1) },
                        local:transform($node/node())
                    }                    
            else if($node/parent::tei:titleStmt and not($node/@level='m')) then
                if($node/ancestor::tei:TEI/descendant::entryFree) then
                    if($node/ancestor::tei:TEI/descendant::tei:term[@xml:lang='zh-latn-pinyin-nt']) then
                      element { local-name($node) } 
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { 'zh-latn-pinyin-nt' },
                            (if($node/ancestor::tei:TEI/descendant::tei:term[@xml:lang='zh-Hant'][1]) then
                                (<foreign xml:lang="zh-Hant">{$node/ancestor::tei:TEI/descendant::tei:term[@xml:lang='zh-Hant']/text()}</foreign>,' ')
                            else (),
                            $node/ancestor::tei:TEI/descendant::tei:term[@xml:lang='zh-latn-pinyin-nt']/text()   
                            )
                        }  
                    else if($node/ancestor::tei:TEI/descendant::tei:term[@type='preferred']) then
                      element { local-name($node) } 
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { 'zh-latn-pinyin-nt' },
                        (if($node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='zh-Hant']) then
                                (<foreign xml:lang="zh-Hant">{$node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='zh-Hant']/text()}</foreign>,' ')
                            else (),
                          if($node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='zh-latn-pinyin-nt']) then
                            $node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='zh-latn-pinyin-nt']/text()
                          else if($node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='en']) then 
                            $node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][@xml:lang='en']/text()
                          else $node/ancestor::tei:TEI/descendant::tei:term[@type='preferred'][1]/text()   
                            )
                           } 
                    else 
                        element { local-name($node) } 
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { $node/ancestor::tei:TEI/descendant::tei:term[1]/@xml:lang },
                            $node/ancestor::tei:TEI/descendant::tei:term[1]/text()   
                            }
                 else if($node/ancestor::tei:TEI/descendant::place) then
                    if($node/ancestor::tei:TEI/descendant::tei:placeName[@xml:lang='zh-latn-pinyin-nt']) then
                      element { local-name($node) } 
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { 'zh-latn-pinyin-nt' },
                            (if($node/ancestor::tei:TEI/descendant::tei:placeName[@xml:lang='zh-Hant'][1]) then
                                (<foreign xml:lang="zh-Hant">{$node/ancestor::tei:TEI/descendant::tei:placeName[@xml:lang='zh-Hant']/text()}</foreign>,' ')
                            else (),
                            $node/ancestor::tei:TEI/descendant::tei:placeName[@xml:lang='zh-latn-pinyin-nt']/text()   
                            )
                        }  
                    else if($node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred']) then
                       element { local-name($node) }
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { 'zh-latn-pinyin-nt' },
                        (if($node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='zh-Hant']) then
                                 (<foreign xml:lang="zh-Hant">{$node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='zh-Hant']/text()}</foreign>,' ')
                             else (),
                           if($node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='zh-latn-pinyin-nt']) then
                             $node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='zh-latn-pinyin-nt']/text()
                           else if($node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='en']) then 
                             $node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][@xml:lang='en']/text()
                           else $node/ancestor::tei:TEI/descendant::tei:placeName[@type='preferred'][1]/text()   
                             )
                        }
                    else 
                        element { local-name($node) } 
                        { $node/@*[. != '' and not(name(.) = 'xml:lang')],attribute xml:lang { $node/ancestor::tei:TEI/descendant::tei:placeName[1]/@xml:lang },
                            $node/ancestor::tei:TEI/descendant::tei:placeName[1]/text()   
                            }
                else ()                            
            else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}
        case element(tei:bibl) return
            if($node/child::*) then 
                let $num := $node/@xml:id
                return 
                element { local-name($node) } 
                        {   $node/@*[. != '' and not(name(.) = 'xml:id') and not(name(.) = 'ref')],
                            attribute xml:id { 
                            concat('bibl',$id,'-',$num)},
                            local:transform($node/node())
                        }    
            else ()
                    
        case element(tei:location) return 
            if($node/tei:lat or $node/tei:long) then
                element { local-name($node) } 
                    {
                        $node/@*[. != '' and not(name(.) = 'type')], attribute type { "gps" }, 
                        element { 'geo' }
                          { concat($node/tei:lat, ' ', $node/tei:long) }
                        
                    }
            else element { local-name($node) } 
                    {($node/@*[. != ''], local:transform($node/node()))}                   
        case element() return (:local:passthru($node):)
                element {local-name($node) } { $node/@*[. != '' and not(name(.) = 'source')],
                        if($node/@source[. != '']) then 
                            attribute source { concat('#bibl',$id,'-', $node/@source)}
                        else (),
                        local:transform($node/node())
                    }
        default return local:transform($node/node())
};

(: Recurse through child nodes :)
declare function local:passthru($node as node()*) as item()* { 
    element {local-name($node)} {($node/@*[. != ''], local:transform($node/node()))}
};

declare function local:transformTextXML($nodes as node()*) as item()* { 
for $node in $nodes
return
    typeswitch($node)
        case processing-instruction() return $node 
        case comment() return $node 
        case text() return parse-xml-fragment($node)
        case element() return local:passthru($node) 
        default return local:passthru($node)
};

(:
namespace {''} {'http://www.tei-c.org/ns/1.0'}
{fn:QName("http://www.tei-c.org/ns/1.0", local-name($node))} 
:)


let $data := if(request:get-parameter('postdata','')) then request:get-parameter('postdata','') else request:get-data()
let $record := 
    if($data instance of node()) then
        $data//tei:TEI
    else fn:parse-xml($data)        
let $post-processed-xml := local:transform($record)
let $uri := replace($post-processed-xml/descendant::tei:idno[1],'/tei','')
let $id := tokenize($uri,'/')[last()]
let $file-name := 
    if($id != '') then 
        concat($id, '.xml') 
    else 'form.xml'
let $document-uri := document-uri(root(collection($config:data-root)//tei:idno[@type='URI'][. = $id]))
let $collection-uri := substring-before($document-uri,$file-name)
let $github-path := substring-after($collection-uri,'tcadrt/')
return 
    if(request:get-parameter('type', '') = 'save') then
        try {
            let $save := xmldb:store($collection-uri, xmldb:encode-uri($file-name), $post-processed-xml)
            return 
             <response status="okay" code="200"><message>Record saved, thank you for your contribution. {$post-processed-xml}</message></response>  
        } catch * {
            (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to update resource {$id}: {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }
    else if(request:get-parameter('type', '') = 'github') then
        try {
            let $save := gitcommit:run-commit($post-processed-xml, concat($github-path,$file-name), concat("User submitted content for ",$document-uri))
            return 
             <response status="okay" code="200"><message>Thank you for your contribution.</message></response>  
        } catch * {
            (response:set-status-code( 500 ),
            <response status="fail">
                <message>Failed to submit, please download your changes and send via email. {concat($err:code, ": ", $err:description)}</message>
            </response>)
        }    
    else if(request:get-parameter('type', '') = ('download','view')) then
            (response:set-header("Content-Type", "application/xml; charset=utf-8"),
             response:set-header("Content-Disposition", fn:concat("attachment; filename=", $file-name)),$post-processed-xml)     
    else 
        <response code="500">
            <message>General Error</message>
        </response> 