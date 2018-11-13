xquery version "3.0";
import module namespace global="http://syriaca.org/global" at "modules/lib/global.xqm";
declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
(: Get variables for Srophe collections. :)
declare variable $exist:record-uris  := 
    distinct-values(for $collection in $global:get-config//repo:collection
    let $short-path := replace($collection/@record-URI-pattern,$global:base-uri,'')
    return $short-path)    
;

(: Get variables for Srophe collections. :)
declare variable $exist:collection-uris  := 
    distinct-values(for $collection in $global:get-config//repo:collection
    let $short-path := replace($collection/@app-root,$global:base-uri,'')
    return concat('/',$short-path,'/'))    
; 

(: Used to test vars
<div>
    <p>$exist:path: {$exist:path}</p>
    <p>$exist:resource: {$exist:resource}</p>
    <p>$exist:controller: {$exist:controller}</p>
    <p>$exist:prefix: {$exist:prefix}</p>
    <p>$exist:root: {$exist:root}</p>
    <p>Srophe record uris: {$exist:record-uris}</p>
    <p>Srophe coleection uris: {$exist:collection-uris}</p>
</div>
:)


if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

(: Resource paths starting with $app-root are resolved relative to app :)
else if (contains($exist:path, "/$app-root/")) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{concat($exist:controller,'/', substring-after($exist:path, '/$app-root/'))}">
                <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
            </forward>
        </dispatch>        

(: Resource paths starting with $shared are loaded from the shared-resources app :)
else if (contains($exist:path, "/$shared/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
            <set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
        </forward>
    </dispatch>

(: Checks for any record uri patterns as defined in repo.xml :)    
else if(replace($exist:path, $exist:resource,'') =  ($exist:record-uris) or ends-with($exist:path, ("/atom","/tei","/rdf","/ttl",'.tei','.atom','.rdf','.ttl'))) then
    (: Sends to restxql to handle /atom, /tei,/rdf:)
    if (ends-with($exist:path, ("/atom","/tei","/rdf","/ttl",'.tei','.atom','.rdf','.ttl'))) then
        let $path := 
            if(ends-with($exist:path, (".atom",".tei",".rdf",".ttl"))) then 
                replace($exist:path, "\.(atom|tei|rdf|ttl)", "/$1")
            else $exist:path
        return 
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{concat('/restxq/ba', $path)}" absolute="yes"/>
            </dispatch>
    (: Special handling for collections with app-root that matches record-URI-pattern sends html pages to html, others are assumed to be records :)
    else if($exist:resource = ('index.html','search.html','browse.html','about.html','aggregate.html','factoid.html')) then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
           <view>
               <forward url="{$exist:controller}/modules/view.xql"/>
           </view>
   		<error-handler>
   			<forward url="{$exist:controller}/error-page.html" method="get"/>
   			<forward url="{$exist:controller}/modules/view.xql"/>
   		</error-handler>
       </dispatch>
    (: parses out record id to be passed to correct collection view, based on values in repo.xml :)       
    else if($exist:resource = '') then 
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="index.html"/>
        </dispatch>
    else 
        let $id := replace(xmldb:decode($exist:resource), "^(.*)\..*$", "$1")
        let $record-uri-root := replace($exist:path,$exist:resource,'')
        let $html-path :=
            if(contains($exist:path,'spear')) then 
                if(matches($exist:resource,'^[0-9]+-[0-9]+')) then concat('/',$global:get-config//repo:collection[ends-with(@record-URI-pattern, $record-uri-root)][1]/@app-root,'/factoid.html')  
                else if(matches($exist:resource,'^[0-9]+')) then concat('/',$global:get-config//repo:collection[ends-with(@record-URI-pattern, $record-uri-root)][1]/@app-root,'/aggregate.html')
                else concat('/',$global:get-config//repo:collection[ends-with(@record-URI-pattern, $record-uri-root)][1]/@app-root,'/record.html')
            else concat('/',$global:get-config//repo:collection[ends-with(@record-URI-pattern, $record-uri-root)][1]/@app-root,'/record.html')
        return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{$exist:controller}{$html-path}"></forward>
                <view>
                    <forward url="{$exist:controller}/modules/view.xql">
                       <add-parameter name="id" value="{$id}"/>
                    </forward>
                </view>
                <error-handler>
                    <forward url="{$exist:controller}/error-page.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
         </dispatch> 
(: Passes any api requests to restxq:)    
else if (contains($exist:path,'/api/')) then
  if (ends-with($exist:path,"/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/api-documentation/index.html"/>
    </dispatch> 
   else if($exist:resource = 'index.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="/api-documentation/index.html"/>
    </dispatch>
    else if($exist:resource = 'oai') then
     <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{replace($exist:path,'/api/oai','/ba/modules/oai.xql')}"/>
     </dispatch>
    else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{concat('/restxq/ba', $exist:path)}" absolute="yes"/>
    </dispatch>

else if ($exist:resource eq '' or ends-with($exist:path,"/")) then 
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>
    
(: Sends all other html pages through eXist templating module for processing. :)    
else if (ends-with($exist:resource, ".html")) then
    (: the html page is run through view.xql to expand templates :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <view>
            <forward url="{$exist:controller}/modules/view.xql"/>
        </view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
    </dispatch>

(: Redirects paths with directory, and no trailing slash to index.html in that directory :)    
else if (matches($exist:resource, "^([^.]+)$")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{concat($exist:path,'/index.html')}"/>
    </dispatch>         
else
    (: everything else is passed through :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <cache-control cache="yes"/>
    </dispatch>