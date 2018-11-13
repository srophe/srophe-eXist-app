xquery version "3.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace global="http://syriaca.org/global" at "../lib/global.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
declare option exist:serialize "method=html5 media-type=text/html omit-xml-declaration=yes indent=yes";

declare variable $graph {request:get-parameter('graph', '')};
(: Build HTML for force Graph, will add additional graphs later on. :)
declare function local:html(){
<html>
    <head>
        <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
            <title>Assignment 2: Relationships</title>
            <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no"/>
            <!--[if lt IE 9]>
                <script src="//html5shiv.googlecode.com/svn/trunk/html5.js"></script>
            <![endif]-->
            <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
            <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
            <link rel="stylesheet" type="text/css" href="$app-root/resources/css/bootstrap.min.css" />
            <link rel="stylesheet" href="$app-root/resources/css/main.css"/>
            <link rel="stylesheet" href="$app-root/modules/d3xquery/relationships.css"/>
            <link rel="stylesheet" href="$app-root/modules/d3xquery/pygment_trac.css"/>
            <script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js" ></script>
            <script type='text/javascript' src="http://d3js.org/d3.v3.js"></script>
            <!--<script type='text/javascript' src="https://cdnjs.cloudflare.com/ajax/libs/d3-legend/1.8.0/d3-legend.js"></script>-->
            <script src="$app-root/modules/d3xquery/force-d3js.js"></script>
            <script>
            <![CDATA[ 
                function exec(){
                    endpoint = d3.select("#endpoint").property("value")
                    graphType = d3.select("#graphType").property("value")
                    eventType = d3.select("#eventType").property("value")
                    itemURI = d3.select("#itemURI").property("value")
                    relType = d3.select("#relType").property("value")
                    d3xquery.query(endpoint, graphType, eventType, itemURI, relType, render)  
                }
                 
                function render(json) {
                    d3xquery.initialGraph(json)
                } 
                
                $(document).ready(function () { 
                    toggleFields(); //call this first so we start out with the correct visibility depending on the selected form values
                    $("#graphType").change(function () {
                        toggleFields();
                    });
                });
                
               function toggleFields() {
                   if ($("#graphType").val() === "event")
                       $("#eventGrp").show();
                   else
                       $("#eventGrp").hide();
                       
                   if ($("#graphType").val() === "relationship")
                       $("#relGrp").show();                       
                   else
                       $("#relGrp").hide();
               }
            ]]>
            </script>
    </head>
    <body class="white">
        <div class="row">
            <div class="col-md-9">
                <div id="graph-container">   
                    <div id="graph"></div>
                </div>
            </div>
            <div class="col-md-3">
                <div id="sidebar">
                    <div>
                      <form class="form-horizontal" id="query">
                        <h4>Select graph to explore 
                        <a class="togglelink pull-right btn-link" 
                        data-toggle="collapse" data-target="#showForm" 
                        data-text-swap="show options">hide options 
                        <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"></span>
                        </a>
                        </h4>
                        <div id="showForm" class="collapse in">
                        <div class="form-group">
                            <label for="graphType" class="col-sm-2 control-label">Type</label>
                            <div class="col-sm-10">
                                <select id="graphType" class="form-control">
                                    <option value="">-- Select Graph --</option>
                                    <option value="event">Event</option>
                                    <option value="relationship">Relationship</option>
                                </select>
                            </div>
                        </div>
                        <div class="form-group" id="eventGrp" >
                            <label for="eventType" class="col-sm-2 control-label">Events </label>
                            <div class="col-sm-10">
                                <select id="eventType" class="form-control">
                                    <option value="">-- Select Event --</option>
                                    <option value="all">All Events</option>
                                    {local:get-events()}
                                </select>
                            </div>
                        </div>
                        <div class="form-group" id="relGrp" >
                            <label for="relType" class="col-sm-2 control-label">Relationships </label>
                            <div class="col-sm-10">
                                <select id="relType" class="form-control">
                                    <option value="">-- Select Relationships --</option>
                                    <option value="all">All Relationships</option>
                                    {local:get-rels()}
                                </select>
                            </div>
                        </div>
                        <div class="form-group">
                            <label for="itemURI" class="col-sm-2 control-label">Record </label>
                            <div class="col-sm-10">
                                <input type="text" class="form-control" id="itemURI" placeholder="Example: http://syriaca.org/person/51"/>
                            </div>
                        </div>
                        <input id="endpoint" class="span5" value="get-relationships.xql" type="hidden"/>
                        <button type="button" class="btn btn-primary" onclick="exec()">Query</button> &#160;
                        <input class="btn btn-warning" type="reset" value="Reset"/>
                        </div>
                    </form>
                    </div>
                    <hr style="margin-top:1em;"/>
                    <div class="item-group">
                        <h4 class="item-label">Filter
                        <a class="togglelink pull-right btn-link" 
                        data-toggle="collapse" data-target="#filterContainer" 
                        data-text-swap="show options">hide options 
                        <span class="glyphicon glyphicon-collapse-down" aria-hidden="true"></span>
                        </a>
                        </h4>
                        <div id="filterContainer" class="filterContainer checkbox-interaction-group collapse in"></div>
                    </div>
                    <hr/>
                    <div id="info-box"></div>
                    <div id="relationship-box"></div>
                </div>
            </div>
        </div> 
        <script type="text/javascript" src="$app-root/resources/js/bootstrap.min.js"></script>
    </body>
</html>
};


(: Get all events for drop down menu :)
(: Eventually add collection filter :)
declare function local:get-events(){
    let $events := distinct-values(for $event in collection($global:data-root || '/spear/tei')//tei:event/tei:ptr/@target
                    return tokenize($event,'/')[last()])
    for $e in $events
    return 
    <option value="{$e}">{$e}</option>
};

(: Get all relationships for drop down menu :)
(: Eventually add collection filter :)
declare function local:get-rels(){
    let $rels := distinct-values(for $rel in collection($global:data-root || '/spear/tei')//tei:relation/@ref
                    return replace($rel,'^(.*?):','')[last()])
    for $r in $rels
    return 
    <option value="{$r}">{$r}</option>
};

local:html()