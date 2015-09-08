xquery version "3.0";

module namespace global="http://syriaca.org/global";

declare variable $global:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return
        substring-before($modulePath, "/modules")
    ;
    
declare variable $global:data-root := 
    let $app-root := doc($global:app-root || '/config.xml')//app-root/text() 
    let $data-root := concat(doc($global:app-root || '/config.xml')//data-root/text(),'/data') 
    return
       replace($global:app-root, $app-root, $data-root)
    ;

declare variable $global:app-map-option := 
    doc($global:app-root || '/config.xml')//maps/option[@selected='true']/text()  
    ;

(:~
 : Transform tei to html via xslt
 : @param $node data passed to transform
:)
declare function global:tei2html($nodes as node()*) {
    transform:transform($nodes, doc($global:app-root || '/resources/xsl/tei2html.xsl'), 
    <parameters>
        <param name="data-root" value="{$global:data-root}"/>
        <param name="app-root" value="{$global:app-root}"/>
    </parameters>
    )
};
