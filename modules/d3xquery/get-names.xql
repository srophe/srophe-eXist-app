xquery version "3.0";

import module namespace rel="http://syriaca.org/related" at "../lib/get-related.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

declare variable $id {request:get-parameter('id', '')};

(:
        d3.select("#info-box").html('<h3>' + d.name + '</h3>' + 
                '<p><label>Type:</label> ' + d.type + '</p>' + 
                '<p>' + d.desc  + '</p>' + 
                '<p><label>URI:</label> <a href="' + d.id + '">' + d.id +'</a></p>');
:)
if(rel:get-names-json($id) != '') then 
    rel:display($id)
else 
    <div class="results-list">
        <a href="{$id}" class="syr-label">{tokenize($id,'/')[last()]}</a>
        <span class="results-list-desc uri">No description</span>
        <span class="results-list-desc uri"><a href="{$id}" class="syr-label">{$id}</a></span>
    </div>


(:local:get-relationships('http://syriaca.org/person/51'):)
(:local:get-events('synagogue'):)
(:local:get-relationships('http://syriaca.org/place/78'):)