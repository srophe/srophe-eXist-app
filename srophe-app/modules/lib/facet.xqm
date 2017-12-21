xquery version "3.0";
(:~ 
 : Partial facet implementation for eXist-db based on the EXPath specifications (http://expath.org/spec/facet)
 : 
 : Uses the following eXist-db specific functions:
 :      util:eval 
 :      request:get-parameter
 :      request:get-parameter-names()
 : 
 : @author Winona Salesky
 : @version 1.0 
 :
 : @see http://expath.org/spec/facet   
 : 
 : TODO: 
 :  Support for hierarchical facets
 :)

module namespace facet = "http://expath.org/ns/facet";
import module namespace global="http://syriaca.org/global" at "global.xqm";
import module namespace functx="http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: External facet parameters :)
declare variable $facet:fq {request:get-parameter('fq', '') cast as xs:string};

(:~
 : Given a result sequence, and a sequence of facet definitions, count the facet-values for each facet defined by the facet definition(s).
 : Accepts one or more facet:facet-definition elements
 : Signiture: 
    facet:count($results as item()*,
        $facet-definitions as element(facet:facet-definition)*) as element(facet:facets)
 : @param $results results node to be faceted on.
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:count($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:facets){
<facets xmlns="http://expath.org/ns/facet">
    {   
    for $facet in $facet-definitions
    return 
    <facet name="{$facet/@name}" show="{$facet/descendant::facet:max-values/@show}" max="{$facet/descendant::facet:max-values/text()}">
        {
        let $max := if($facet/descendant::facet:max-values/text()) then $facet/descendant::facet:max-values/text() else 100
        for $facets at $i in subsequence(facet:facet($results, $facet),1,$max)
        return $facets
        }
    </facet>
    }
</facets>  
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
(:  TODO: Handle nested facet-definition  :)
declare function facet:facet($results as item()*, $facet-definitions as element(facet:facet-definition)?) as item()*{
    if ($facet-definitions/facet:group-by/@function) then
        util:eval(concat($facet-definitions/facet:group-by/@function,'($results,$facet-definitions)'))
    else if($facet-definitions/facet:range) then
        facet:group-by-range($results, $facet-definitions)        
    else facet:group-by($results, $facet-definitions)
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each facet defined by the facet definition. 
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
(: TODO: Need to be able to switch out descending with ascending based on facet-def/order-by/@direction:)
declare function facet:group-by($results as item()*, $facet-definitions as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $f[1]
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{(:global:odd2text($f[1],string($f[1])):)$facet-grp}"/>
};


(:~
 : Syriaca.org specific group-by function for correctly labeling attributes with arrays.
:)
declare function facet:group-by-array($results as item()*, $facet-definitions as element(facet:facet-definition)?){
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text()) 
    let $sort := $facet-definitions/facet:order-by
    let $d := tokenize(string-join(util:eval($path),' '),' ')
    for $f in $d
    group by $facet-grp := tokenize($f,' ')
    order by 
        if($sort/text() = 'value') then $f[1]
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}"/>
};

(:~
 : Given a result sequence, and a facet definition, count the facet-values for each range facet defined by the facet definition. 
 : Range values defined by: range and range/bucket elements
 : Facet defined by facets:facet-definition/facet:group-by/facet:sub-path 
 : @param $results results to be faceted on. 
 : @param $facet-definitions one or more facet:facet-definition element
:) 
declare function facet:group-by-range($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $ranges := $facet-definitions/facet:range
    let $sort := $facet-definitions/facet:order-by 
    for $range in $ranges/facet:bucket
    let $path := if($range/@lt and $range/@lt != '') then
                    concat('$results/',$facet-definitions/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'" and . <= "',facet:type($range/@lt, $ranges/@type),'"]')
                 else if($range/@eq) then
                    concat('$results/',$facet-definitions/descendant::facet:sub-path/text(),'[', $range/@eq ,']')
                 else concat('$results/',$facet-definitions/descendant::facet:sub-path/text(),'[. >= "', facet:type($range/@gt, $ranges/@type),'"]')
    let $f := util:eval($path)
    order by 
            if($sort/text() = 'value') then $f[1]
            else if($sort/text() = 'count') then count($f)
            else if($sort/text() = 'order') then xs:integer($range/@order)
            else count($f)
        descending
    return 
         <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{string($range/@name)}" label="{string($range/@name)}"/>
};

(:~
 : Syriaca.org specific group-by function for correctly labeling submodules.
:)
declare function facet:group-by-sub-module($results as item()*, $facet-definitions as element(facet:facet-definition)?) {
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending        
    return 
        let $label := 
            if($facet-grp = 'http://syriaca.org/authors') then 'Authors'
            else if($facet-grp = 'http://syriaca.org/q') then 'Saints'
            else ()
        return 
            <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$label}"/>    
};

(:~
 : Syriaca.org specific group-by function for correctly labeling submodules.
:)
declare function facet:group-place-type($results as item()*, $facet-definitions as element(facet:facet-definition)?) {
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by $facet-grp ascending
    return
        <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{$facet-grp}"/>    
};

(:~
 : Syriaca.org specific group-by function for correctly labeling SPEAR source texts.
:)
declare function facet:spear-source-text($results as item()*, $facet-definitions as element(facet:facet-definition)?) {
    let $path := concat('$results[',$facet-definitions/facet:group-by/facet:sub-path/text(),']')
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    let $fg := util:eval(concat('$f/',$facet-definitions/facet:group-by/facet:sub-path/text()))
    group by $facet-grp := $fg
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp[1]}" label="{$facet-grp[1]}"/>    
};

declare function facet:spear-type($results as item()*, $facet-definitions as element(facet:facet-definition)?) as element(facet:key)*{
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{substring-after($facet-grp,'list')}"/>
};

(: biblia-arabica special facet :)
declare function facet:viewable-online($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $r := $results[descendant::tei:idno[not(matches(.,'^(http://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))] or descendant::tei:ref/@target[not(matches(.,'^(http://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))]]
    return 
         <key xmlns="http://expath.org/ns/facet" count="{count($r)}" value="true" label="Online"/>
};

(: biblia-arabica special facet :)
declare function facet:authors($results as item()*, $facet-definitions as element(facet:facet-definition)*) as element(facet:key)*{
    let $sort := $facet-definitions/facet:order-by
    for $f in $results/descendant::tei:body/tei:biblStruct/child::*/child::*[self::tei:author or self::tei:editor]
    group by $facet-grp := string-join($f/descendant::text(),' ')
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
   return    
        <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{normalize-space($facet-grp[1])}" label="{concat($f[1]/tei:surname,', ', $f[1]/tei:forename)}"/>   

};


(: Syriaca.org specific function that uses the syiraca.org ODD file to establish labels for controlled values 
 : Uses global:odd2text($element-name,$label)) for translation. 
:)
declare function facet:controlled-labels($results as item()*, $facet-definitions as element(facet:facet-definition)?) {
    let $path := concat('$results/',$facet-definitions/facet:group-by/facet:sub-path/text())
    let $sort := $facet-definitions/facet:order-by
    for $f in util:eval($path)
    group by $facet-grp := $f
    order by 
        if($sort/text() = 'value') then $facet-grp
        else count($f)
        descending
    return <key xmlns="http://expath.org/ns/facet" count="{count($f)}" value="{$facet-grp}" label="{global:odd2text(tokenize(replace($path[1],'@|\[|\]',''),'/')[last()],string($facet-grp))}"/>    
};

(:~
 : Adds type casting when type is specified facet:facet:group-by/@type
 : @param $value of xpath
 : @param $type value of type attribute
:)
declare function facet:type($value as item()*, $type as xs:string?) as item()*{
    if($type != '') then  
        if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:string') then xs:string($value)
        else if($type = 'xs:decimal') then xs:decimal($value)
        else if($type = 'xs:integer') then xs:integer($value)
        else if($type = 'xs:long') then xs:long($value)
        else if($type = 'xs:int') then xs:int($value)
        else if($type = 'xs:short') then xs:short($value)
        else if($type = 'xs:byte') then xs:byte($value)
        else if($type = 'xs:float') then xs:float($value)
        else if($type = 'xs:double') then xs:double($value)
        else if($type = 'xs:dateTime') then xs:dateTime($value)
        else if($type = 'xs:date') then xs:date($value)
        else if($type = 'xs:gYearMonth') then xs:gYearMonth($value)        
        else if($type = 'xs:gYear') then xs:gYear($value)
        else if($type = 'xs:gMonthDay') then xs:gMonthDay($value)
        else if($type = 'xs:gMonth') then xs:gMonth($value)        
        else if($type = 'xs:gDay') then xs:gDay($value)
        else if($type = 'xs:duration') then xs:duration($value)        
        else if($type = 'xs:anyURI') then xs:anyURI($value)
        else if($type = 'xs:Name') then xs:Name($value)
        else $value
    else $value
};

(:~
 : XPath filter to be passed to main query
 : creates XPath based on facet:facet-definition//facet:sub-path.
 : @param $facet-def facet:facet-definition element
 : NOTE: need to do type checking here
 : NOTE: add range handling here. 
:)
declare function facet:facet-filter($facet-definitions as node()*)  as item()*{
    if($facet:fq != '') then
        string-join(
        for $facet in tokenize($facet:fq,';fq-')
        let $facet-name := substring-before($facet,':')
        let $facet-value := normalize-space(substring-after($facet,':'))
        return 
            for $facet in $facet-definitions/facet:facet-definition[@name = $facet-name]
            let $path := 
                         if(matches($facet/descendant::facet:sub-path/text(), '^/@')) then concat('descendant::*/',substring($facet/descendant::facet:sub-path/text(),2))
                         else $facet/descendant::facet:sub-path/text()
            return 
            if($facet-value != '') then 
                if($facet/facet:range) then
                    if($facet/facet:range/facet:bucket[@name = $facet-value]/@lt and $facet/facet:range/facet:bucket[@name = $facet-value]/@lt != '') then
                        concat('[',$path,'[string(.) >= "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" and string(.) <= "',facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@lt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'"]]')                        
                    else if($facet/facet:range/facet:bucket[@name = $facet-value]/@eq and $facet/facet:range/facet:bucket[@name = $facet-value]/@eq != '') then
                        concat('[',$path,'[', $facet/facet:range/facet:bucket[@name = $facet-value]/@eq ,']]')
                    else concat('[',$path,'[string(.) >= "', facet:type($facet/facet:range/facet:bucket[@name = $facet-value]/@gt, $facet/facet:range/facet:bucket[@name = $facet-value]/@type),'" ]]')
                else if($facet/facet:group-by[@function="facet:group-by-array"]) then 
                    concat('[',$path,'[matches(., "',$facet-value,'(\W|$)")]',']')
                else if($facet/facet:group-by[@function="facet:viewable-online"]) then 
                    "[descendant::tei:idno[not(matches(.,'^(http://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))] or descendant::tei:ref/@target[not(matches(.,'^(http://biblia-arabica.com|https://www.zotero.org|https://api.zotero.org)'))]]"    
                else if($facet/facet:group-by[@function="facet:spear-type"]) then 
                    concat('[',substring-before($path,'/name(.)'),'[name(.) = "',$facet-value,'"]',']')
                else if($facet/facet:group-by[@function="facet:authors"]) then
                    concat("[descendant::tei:biblStruct/child::*/child::*[self::tei:author or self::tei:editor][normalize-space(string-join(descendant::text(),' ')) = '",$facet-value,"']]")                 
                else concat('[',$path,'[normalize-space(.) = "',replace($facet-value,'"','""'),'"]',']')
            else(),'')    
    else ()   
};

(:~ 
 : Builds new facet params for html links.
 : Uses request:get-parameter-names() to get all current params 
 :)
declare function facet:url-params(){
    string-join(
    for $param in request:get-parameter-names()
    return 
        if($param = 'fq') then ()
        else if($param = 'start') then '&amp;start=1'
        else if(request:get-parameter($param, '') = ' ') then ()
        else concat('&amp;',$param, '=',request:get-parameter($param, '')),'')
};

(: HTML display functions :)

(:~
 : Create 'Remove' button 
 : Constructs new URL for user action 'remove facet'
:)
declare function facet:selected-facets-display(){
    for $facet in tokenize($facet:fq,';fq-')
    let $value := substring-after($facet,':')
    let $new-fq := string-join(
                    for $facet-param in tokenize($facet:fq,';fq-') 
                    return 
                        if($facet-param = $facet) then ()
                        else concat(';fq-',$facet-param),'')
    let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
    return 
        if($facet != '') then 
            <span class="label label-facet" title="Remove {$value}">
                {$value} <a href="{$href}" class="facet icon"> x</a>
            </span>
        else()
};

(:~
 : Create 'Add' button 
 : Constructs new URL for user action 'Add facet'
:)
declare function facet:html-list-facets-as-buttons($facets as node()*){
(
for $facet in tokenize($facet:fq,';fq-')
let $facet-name := substring-before($facet,':')
let $new-fq := string-join(
                for $facet-param in tokenize($facet:fq,';fq-') 
                return 
                    if($facet-param = $facet) then ()
                    else concat(';fq-',$facet-param),'')
let $href := if($new-fq != '') then concat('?fq=',replace(replace($new-fq,';fq- ',''),';fq-;fq-',';fq-'),facet:url-params()) else ()
return
    if($facet != '') then
        for $f in $facets/facet:facet[@name = $facet-name]
        let $fn := string($f/@name)
        let $label := string($f/facet:key[@value = substring-after($facet,concat($facet-name,':'))]/@label)
        let $value := if(starts-with($label,$global:app-root)) then 
                         facet:get-label($label)   
                      else $label
        return 
                <span class="label label-facet" title="Remove {$value}">
                    {concat($fn,': ', $value)} <a href="{$href}" class="facet icon"> x</a>
                </span>
    else(),
for $f in $facets/facet:facet
let $count := count($f/facet:key)
return 
    if($count gt 0) then 
    <div class="facet-grp">
        <h4>{string($f/@name)}</h4>
            <div class="facet-list show">{
                for $key at $l in subsequence($f/facet:key,1,$f/@show)
                let $facet-query := replace(replace(concat(';fq-',string($f/@name),':',string($key/@value)),';fq-;fq-;',';fq-'),';fq- ','')
                let $new-fq := 
                    if($facet:fq) then concat('fq=',$facet:fq,$facet-query)
                    else concat('fq=',normalize-space($facet-query))
                let $active := if(contains($facet:fq,concat(';fq-',string($f/@name),':',string($key/@value)))) then 'active' else ()    
                return <a href="?{$new-fq}{facet:url-params()}" class="facet-label btn btn-default {$active}"><bdi>{facet:get-label(string($key/@label))}</bdi> <span class="count"> ({string($key/@count)})</span></a> 
                }
            </div>
            <div class="facet-list collapse" id="{concat('show',replace(string($f/@name),'\s|/',''))}">{
                for $key at $l in subsequence($f/facet:key,$f/@show + 1,$f/@max)
                let $facet-query := replace(replace(concat(';fq-',string($f/@name),':',string($key/@value)),';fq-;fq-;',';fq-'),';fq- ','')
                let $new-fq := 
                    if($facet:fq) then concat('fq=',$facet:fq,$facet-query)
                    else concat('fq=',$facet-query)
                return <a href="?{$new-fq}{facet:url-params()}" class="facet-label btn btn-default">{facet:get-label(string($key/@label))} <span class="count"> ({string($key/@count)})</span></a>
                }
            </div>
            {if($count gt ($f/@show - 1)) then 
                <a class="facet-label togglelink btn btn-info" 
                data-toggle="collapse" data-target="#{concat('show',replace(string($f/@name),'\s|/',''))}" href="#{concat('show',replace(string($f/@name),'\s|/',''))}" 
                data-text-swap="Less"> More &#160;<i class="glyphicon glyphicon-circle-arrow-right"></i></a>
            else()}
    </div>
    else()
)    
};

(:~
 : Syriaca.org specific function to label URI's with human readable labels. 
 : @param $uri Syriaca.org uri to be used for lookup. 
 : URI can be a record or a keyword
 : NOTE: this function will probably slow down the facets.
:)

declare function facet:get-label($uri as item()*){
if(starts-with($uri, $global:app-root)) then 
  if(contains($uri,'/keyword/')) then
    lower-case(functx:camel-case-to-words(substring-after($uri,'/keyword/'),' '))
  else 
      let $doc := collection($global:data-root)//tei:TEI[.//tei:idno = concat($uri,"/tei")][1]
      return 
      if (exists($doc)) then
        replace(string-join($doc/descendant::tei:fileDesc/tei:titleStmt[1]/tei:title[1]/text()[1],' '),' — ','')
      else $uri 
else $uri
};