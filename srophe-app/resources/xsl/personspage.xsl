<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" xmlns:x="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs t s saxon" version="2.0">

 <!-- ================================================================== 
       Copyright 2013 New York University
       
       The Syriac Reference Portal Persons Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Persons Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Persons Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
 
 <!-- ================================================================== 
       personspage.xsl
       
       This XSLT transforms perons tei xml (TEI) files to HTML. It builds the
       guts of the website, in effect.
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 on tei generated from /srophe/modules/record.xql
        
       code by: 
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
        + Edited by Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
 <!-- =================================================================== -->
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
   <!-- NOTE: WS: should rename place-title-std to title-std used by place and persons -->
    <xsl:import href="place-title-std.xsl"/>
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <xsl:import href="json-uri.xsl"/>
    <xsl:import href="langattr.xsl"/>
    <xsl:import href="collations.xsl"/>
    
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="html" encoding="UTF-8" method="xhtml" indent="no"/>

 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!--  sourcedir: where to look for XML files to summarize/link to -->
 <!--  description: a meta description for the HTML page we will output -->
 <!--  name-app: name of the application (for use in head/title) -->
 <!--  name-page-short: short name of the page (for use in head/title) -->
 <!--  colquery: constructed variable with query for collection fn. -->
 <!-- =================================================================== -->
    <xsl:param name="normalization">NFKC</xsl:param>
    <xsl:param name="xmlbase">/db/apps/srophe/data/persons/tei/xml/</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/documentation/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc">/db/apps/srophe/documentation/editors.xml</xsl:variable>
    <xsl:param name="uribase">http://syriaca.org/person/</xsl:param>
    <xsl:variable name="resource-id" select="substring-after(/descendant::*/t:person[1]/@xml:id,'person-')"/>
    <xsl:variable name="resource-uri" select="concat($uribase,$resource-id)"/>
 <!-- =================================================================== -->
 <!-- TEMPLATES -->
 <!-- =================================================================== -->


 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
 <!-- |||| Root template matches tei root -->
 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="/">
        <div class="row title">
            <h1 class="col-md-8">        
                <!-- Format title, calls template in place-title-std.xsl -->
                <xsl:call-template name="rec-title-std">
                    <xsl:with-param name="rec" select="//t:person"/>
                </xsl:call-template>
                <!-- Add person type and dates to page heading -->
                <xsl:if test="//t:person/@ana or //t:death or t:birth">
                (<xsl:choose>
                        <xsl:when test="contains(//t:person/@ana,'author') and contains(//t:person/@ana,'saint')">author, saint</xsl:when>
                        <xsl:when test="contains(//t:person/@ana,'author')">author</xsl:when>
                        <xsl:when test="contains(//t:person/@ana,'saint')">saint</xsl:when>
                    </xsl:choose>
                    <xsl:if test="//t:person/@ana and //t:death or //t:birth">, 
                        <xsl:if test="not(//t:death)">b. </xsl:if>
                        <xsl:value-of select="//t:birth/text()"/>
                        <xsl:if test="//t:death">
                            <xsl:choose>
                                <xsl:when test="//t:birth"> - </xsl:when>
                                <xsl:otherwise>d. </xsl:otherwise>
                            </xsl:choose>
                            <xsl:value-of select="//t:death/text()"/>
                        </xsl:if>
                    </xsl:if>)
                </xsl:if>
                <span class="get-syriac noprint">
                    <xsl:if test="//t:person/child::*[@xml:lang ='syr']">
                        <a href="../documentation/view-syriac.html">
                            <img src="/exist/apps/srophe/resources/img/faq.png" alt="FAQ icon"/>&#160;Don't see Syriac?</a>
                    </xsl:if>
                </span>
            </h1>
            <xsl:call-template name="link-icons"/>  
        <!-- End Title -->
        </div>
        <!-- Main persons page content -->
        <xsl:apply-templates select="//t:person"/>
  <!-- End main content section -->
  <!-- Citations section -->
        <xsl:variable name="htmluri" select="concat('?id=',$resource-id)"/>
        <div class="citationinfo">
            <h3>How to Cite This Entry</h3>
            <div id="citation-note" class="well">
                <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
                <div class="collapse" id="showcit">
                    <div id="citation-bibliography">
                        <h4>Bibliography:</h4>
                        <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-biblist"/>
                    </div>
                    <div id="about">
                        <h3>About this Entry</h3>
                        <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="about"/>
                    </div>
                    <div id="license">
                        <h3>Copyright and License for Reuse</h3>
                        <p>
                            <xsl:text>Except otherwise noted, this page is © </xsl:text>
                            <xsl:choose>
                                <xsl:when test="//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]/text() castable as xs:date">
                                    <xsl:value-of select="format-date(xs:date(//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]"/>
                                </xsl:otherwise>
                            </xsl:choose>.</p>
                        <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence"/>
                    </div>
                </div>
                <a class="togglelink pull-right btn-link" data-toggle="collapse" data-target="#showcit" data-text-swap="Hide citation">Show full citation information...</a>
            </div>
        </div>
    </xsl:template>
    
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
<!-- |||| Person templates -->
<!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:person">
        <!-- Start person content -->
        <!-- Main content -->
        <!-- emit person URI and associated help links -->
        <xsl:for-each select="t:idno[contains(.,'syriaca.org')]">
            <div style="margin:0 1em 1em; color: #999999;">
                <small>
                    <a href="../documentation/terms.html#person-uri" title="Click to read more about Person URIs" class="no-print-link">
                        <div class="helper circle noprint">
                            <p>i</p>
                        </div>
                    </a>
                    <p>
                        <span class="srp-label">Person URI</span>
                        <xsl:text>: </xsl:text>
                        <xsl:value-of select="."/>
                    </p>
                </small>
            </div>
        </xsl:for-each>
        
        <!-- Start of two column content -->
        <div class="row">
            <!-- Column 1 -->
            <div class="col-md-8 column1">
                <xsl:call-template name="col1"/>
                <div style="margin-bottom:1em;">  
                    <!-- Button trigger corrections email modal -->
                    <button class="btn btn-default" data-toggle="modal" data-target="#feedback">Corrections/Additions?</button>&#160;
                    <button class="btn btn-default" data-toggle="modal" data-target="#selection" id="showSection">Is this record complete?</button>
                    <!-- Modal email form-->
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
                                        <!-- More information about submitting data from howtoadd.html -->
                                        <p>
                                            <strong>Notify the editors of a mistake:</strong>
                                            <a class="btn btn-link togglelink" data-toggle="collapse" data-target="#viewdetails" data-text-swap="hide information">more information...</a>
                                        </p>
                                        <div class="section">
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
                                        <input type="hidden" name="id" value="{$resource-id}"/>
                                        <input type="hidden" name="place" value="{string(t:placeName[1])}"/>
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
                    
                    <!-- Modal faq popup -->
                    <div class="modal fade" id="selection" tabindex="-1" role="dialog" aria-labelledby="selectionLabel" aria-hidden="true">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <button type="button" class="close" data-dismiss="modal">
                                        <span aria-hidden="true"> x </span>
                                        <span class="sr-only">Close</span>
                                    </button>
                                    <h2 class="modal-title" id="selectionLabel">Is this record complete?</h2>
                                </div>
                                <div class="modal-body">
                                    <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                                </div>
                                <div class="modal-footer">
                                    <a class="btn" href="../documentation/faq.html" aria-hidden="true">See all FAQs</a>
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                                </div>
                            </div>
                        </div>
                    </div>
                    <script>
                        $('#showSection').click(function(){
                            $('#popup').load( '../documentation/faq.html #selection',function(result){
                            $('#selection').modal({show:true});
                            });
                        });
                    </script>
                </div>
            </div>
            <!-- Column 2 -->
            <div class="col-md-4 column2">
                <xsl:call-template name="col2"/>
            </div>
        </div>
        <xsl:call-template name="sources"/>
        
            <!-- RDF Results -->
            <!--<div class="span2">
                <h3>RDF Results</h3>
                <div>
                    Results
                </div>
            </div>-->
    </xsl:template>
    <!-- Person content is split into two columns -->
    <xsl:template name="col1">
        <div id="persnames" class="well">
            <xsl:if test="string-length(t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']) &gt; 1">
                <h4>Identity</h4>
                <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']" mode="abstract"/>
                <!--<xsl:apply-templates select="t:note[@type='abstract']"/>-->
            </xsl:if>
            <!-- NOTE: Need to add Identy description if it exists, When Nathan gets element back to me.  -->
            <div class="clearfix">
                <p>Names: 
                <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'en')]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:persName[starts-with(@xml:lang, 'ar')]" mode="list">
                        <xsl:sort lang="ar" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar'))]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                </p>
            </div>
            <br class="clearfix"/>
        </div>
      
        <!-- Timeline -->
        <xsl:choose>
            <xsl:when test="//t:death | //t:birth | //t:floruit | //t:state | //t:event">
                <xsl:if test="//t:death | //t:birth | //t:floruit | //t:state | //t:event">
                    <div class="row">
                        <div class="col-md-9">
                            <div class="timeline">
                                <script type="text/javascript" src="http://cdn.knightlab.com/libs/timeline/latest/js/storyjs-embed.js"/>
                                <script type="text/javascript">
                                    $(document).ready(function() {
                                        var parentWidth = $(".timeline").width();
                                        createStoryJS({
                                            start:      'start_at_end',
                                            type:       'timeline',
                                            width:      "'" +parentWidth+"'",
                                            height:     '300',
                                            source:     '<xsl:value-of select="concat('../modules/timeline.xql?uri=',$resource-uri)"/>',
                                            embed_id:   'my-timeline'
                                        });
                                    });
                                </script>
                                <div id="my-timeline"/>
                                <p>*Timeline generated with <a href="http://timeline.knightlab.com/">http://timeline.knightlab.com/</a>
                                </p>
                            </div>
                        </div>
                        <div class="col-md-3">
                            <h4>Dates</h4>
                            <ul class="list-unstyled">
                                <xsl:for-each select="t:birth | t:death | t:floruit | //t:state[not(@type='attestation')][@when or @notBefore or @notAfter or @to or @from]">
                                    <li>
                                        <xsl:apply-templates select="."/>
                                        <!--<xsl:value-of select="descendant-or-self::*"/>-->
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </div>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="//t:death | //t:birth | //t:floruit | //t:state[@when or @notBefore or @notAfter or @to or @from]">
                    <h4>Dates</h4>
                    <ul>
                        <xsl:for-each select="t:birth | t:death | t:floruit | //t:state[not(@type='attestation')][@when or @notBefore or @notAfter or @to or @from]">
                            <li>
                                <xsl:apply-templates select="."/>
                                <!--<xsl:value-of select="descendant-or-self::*"/>-->
                            </li>
                        </xsl:for-each>
                    </ul>
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="../t:relation">
            <xsl:if test="//*:related-items/*:relation[contains(@uri,'place')]">
                <div>
                    <h2>Related Places in the Syriac Gazetteer</h2>
                    <xsl:if test="//*:div[@id='geojson']">
                        <div id="map-data" style="margin-bottom:1em;">
                            <script type="text/javascript" src="http://cdn.leafletjs.com/leaflet-0.7.2/leaflet.js?2"/>
                            <script src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js" type="text/javascript"/>
                            <script src="http://isawnyu.github.com/awld-js/awld.js?autoinit" type="text/javascript"/>
                            <script type="text/javascript" src="/exist/apps/srophe/resources/leaflet/leaflet.awesome-markers.js"/>
                            <div id="map" style="height: 250px;"/>
                            <div class="hint">Not all places in the list below are represented on the map above.</div>
                            <script type="text/javascript">
                                var terrain = L.tileLayer(
                                'http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', 
                                {attribution: "ISAW, 2012"});
                                
                                /* Not added by default, only through user control action */
                                var streets = L.tileLayer(
                                'http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', 
                                {attribution: "ISAW, 2012"});
                                
                                var imperium = L.tileLayer(
                                'http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
                                attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC',
                                maxZoom: 11 });
                                
                                <xsl:text>var placesgeo =</xsl:text>
                                <xsl:value-of select="//*:div[@id='geojson']"/>
                                <![CDATA[
                                var sropheIcon = L.Icon.extend({
                                      options: {
                                          iconSize:     [38, 38],
                                          iconAnchor:   [22, 94],
                                          popupAnchor:  [-3, -76]
                                      }
                                  });
                                  var redIcon =
                                         L.AwesomeMarkers.icon({
                                            icon:'fa-circle',
                                             markerColor: 'red'
                                           }),
                                        orangeIcon =  
                                            L.AwesomeMarkers.icon({
                                            icon:'fa-circle',
                                             markerColor: 'orange'
                                           }),
                                        purpleIcon = 
                                         L.AwesomeMarkers.icon({
                                         icon:'fa-circle',
                                             markerColor: 'purple'
                                           }),
                                        blueIcon =  L.AwesomeMarkers.icon({
                                        icon:'fa-circle',
                                             markerColor: 'blue'
                                           });
                                        
                                var geojson = L.geoJson(placesgeo, {
                                        onEachFeature: function (feature, layer){
                                            var popupContent = "<a href='" + feature.properties.uri + "'>" +
                                            feature.properties.name + " - " + feature.properties.type + "</a>";
                                            layer.bindPopup(popupContent);
                                            switch (feature.properties.relation) {
                                                case 'born-at': return layer.setIcon(orangeIcon);
                                                case 'died-at':   return layer.setIcon(redIcon);
                                                case 'has-literary-connection-to-place':   return layer.setIcon(purpleIcon);
                                                case 'has-relation-to-place':   return layer.setIcon(blueIcon);
                                            }
                                            
                                        }
                                })
                                var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 5});     
                                  
                                terrain.addTo(map);
                                        
                                L.control.layers({
                                        "Terrain (default)": terrain,
                                        "Streets": streets,
                                        "Imperium": imperium }).addTo(map);
                                        
                                geojson.addTo(map);      
                                ]]></script>
                        </div> 
                        <!-- <xsl:copy-of select="//*:div[@id='map-data']"/>-->
                    </xsl:if>
                    <dl class="dl-horizontal dl-srophe">
                        <xsl:for-each-group select="//../*:related-items/*:relation[contains(@uri,'place')]" group-by="@name">
                            <xsl:variable name="desc-ln" select="string-length(t:desc)"/>
                            <xsl:choose>
                                <xsl:when test="not(current-group()/descendant::*:geo)">
                                    <dt>&#160;</dt>
                                </xsl:when>
                                <xsl:when test="current-grouping-key() = 'born-at'">
                                    <dt>
                                        <i class="srophe-marker born-at"/>
                                    </dt>
                                </xsl:when>
                                <xsl:when test="current-grouping-key() = 'died-at'">
                                    <dt>
                                        <i class="srophe-marker died-at"/>
                                    </dt>
                                </xsl:when>
                                <xsl:when test="current-grouping-key() = 'has-literary-connection-to-place'">
                                    <dt>
                                        <i class="srophe-marker literary"/>
                                    </dt>
                                </xsl:when>
                                <xsl:otherwise>
                                    <dt>
                                        <i class="srophe-marker relation"/>
                                    </dt>
                                </xsl:otherwise>
                            </xsl:choose>
                            <dd>
                                <xsl:value-of select="substring(*:desc,1,$desc-ln - 1)"/>:
                                  <xsl:for-each select="current-group()">
                                    <xsl:apply-templates select="." mode="relation"/>
                                      <!--<xsl:if test="position() != last()">, </xsl:if>-->
                                </xsl:for-each>
                            </dd>
                        </xsl:for-each-group>
                    </dl>
                </div>
            </xsl:if>
            <xsl:if test="../*:related-items/*:relation[contains(@uri,'person')]">
                <div id="relations" class="well">
                    <h3>Related People</h3>
                    <!-- NOTE: currently in list, changed to approved format, list or inline -->
                    <ul>
                        <xsl:for-each-group select="//../*:related-items/*:relation[contains(@uri,'person')]" group-by="@name">
                            <li>
                                <xsl:variable name="desc-ln" select="string-length(t:desc)"/>
                                <xsl:value-of select="substring(*:desc,1,$desc-ln - 1)"/>:
                                <xsl:for-each select="current-group()">
                                    <xsl:apply-templates select="." mode="relation"/>
                                    <xsl:if test="position() != last()">, </xsl:if>
                                </xsl:for-each>
                            </li>
                        </xsl:for-each-group>
                    </ul>
                </div>
            </xsl:if>
        </xsl:if>
        <xsl:if test="//t:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]">
            <xsl:for-each-group select="//t:state[not(@when) and not(@notBefore) and not(@notAfter) and not(@to) and not(@from)]" group-by="@type">
                <h4>
                    <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                </h4>
                <ul>
                    <xsl:for-each select="current-group()[not(t:desc/@xml:lang = 'en-x-gedsh')]">
                        <li>
                            <xsl:apply-templates select="."/>
                        </li>
                    </xsl:for-each>
                </ul>
            </xsl:for-each-group>
        </xsl:if>
        
        <!-- What to do about sex and langKnowledge? Better ogranization of data needed. -->
        <xsl:for-each select="//t:sex | //t:langKnowledge">
            <p>
                <xsl:apply-templates select="."/>
            </p>
        </xsl:for-each>
        <div>
            <xsl:if test="string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &gt; 1">
                <div id="description">
                    <h3>Brief Descriptions</h3>
                    <ul>
                        <xsl:for-each-group select="t:desc" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                            <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                            <xsl:for-each select="current-group()">
                                <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                                <xsl:apply-templates select="."/>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </ul>
                </div>
            </xsl:if>
          
          <!-- Events without @type="attestation" -->
            <xsl:if test="t:event[not(@type='attestation')]">
                <div id="event">
                    <h3>Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if>
                    </h3>
                    <ul>
                        <xsl:apply-templates select="t:event[not(@type='attestation')]" mode="event"/>
                    </ul>
                </div>
            </xsl:if> 
          <!-- Events with @type="attestation" -->
            <xsl:if test="t:event[@type='attestation']">
                <div id="event">
                    <h3>Attestation<xsl:if test="count(t:event[@type='attestation']) &gt; 1">s</xsl:if>
                    </h3>
                    <ul>
                        <!-- Sorts events on dates, checks first for @notBefore and if not present, uses @when -->
                        <xsl:for-each select="t:event[@type='attestation']">
                            <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                            <xsl:apply-templates select="." mode="event"/>
                        </xsl:for-each>
                    </ul>
                </div>
            </xsl:if>
            <xsl:if test="t:note[not(@type='abstract')]">
                <xsl:for-each-group select="t:note[not(@type='abstract')]" group-by="@type">
                    <h4>
                        <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                    </h4>
                    <ul>
                        <xsl:for-each select="current-group()">
                            <xsl:apply-templates/>
                        </xsl:for-each>
                    </ul>
                </xsl:for-each-group>
            </xsl:if>
        </div>
    
        <!-- Saints' lives -->
        <xsl:if test="@ana ='#syriaca-saint'">
            <div>
                <h3>Lives</h3>
                <p>
                    [Under preparation. Syriaca.org is preparing a database of Syriac saints lives, Biblioteca Hagiographica Syriaca Electronica, which will include links to lives for saints here.]
                </p>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template name="col2">
        <xsl:if test="//*:div[@id = 'worldcat-refs']">
            <div id="worldcat-refs" class="well">
                <h3>Catalog Search Results from WorldCat</h3>
                <p class="hint">Based on VIAF ID. May contain inaccuracies. Not curated by Syriaca.org.</p>
                <xsl:for-each select="//*:div[@id = 'worldcat-refs']/*:ul">
                    <xsl:variable name="viaf-ref" select="@id"/>
                    <ul>
                        <xsl:for-each select="*:li">
                            <li>
                                <a href="{@ref}">
                                    <xsl:value-of select="text()"/>
                                </a>
                            </li>
                        </xsl:for-each>
                    </ul>
                    <span class="pull-right">
                        <a href="{$viaf-ref}">See all <xsl:value-of select="@count"/> titles from WorldCat</a>
                    </span>
                </xsl:for-each>
            </div>    
            <!--<xsl:copy-of select="//*:div[@id = 'worldcat-refs']"/>-->
        </xsl:if>
        <xsl:call-template name="link-icons-text"/>
    </xsl:template>
    <xsl:template name="sources">
        <div class="well">
            <!-- Sources -->
            <div id="sources">
                <h3>Sources</h3>
                <p>
                    <small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small>
                </p>
                <ul>
                    <!-- Bibliography elements are processed by bibliography.xsl -->
                    <xsl:apply-templates select="t:bibl" mode="footnote"/>
                </ul>
            </div>
        </div>
    </xsl:template>
    
    <!-- Children of person element -->
    <xsl:template match="t:relation">
        <xsl:apply-templates select="t:desc"/>
    </xsl:template>
    <xsl:template match="t:note[not(@type='abstract')]">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:state">
        <span class="srp-label">
            <xsl:choose>
                <xsl:when test="@role">
                    <xsl:value-of select="concat(upper-case(substring(@role,1,1)),substring(@role,2))"/>:
               </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/>:        
               </xsl:otherwise>
            </xsl:choose>
        </span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="plain"/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:birth">
        <span class="srp-label">Birth:</span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:death">
        <span class="srp-label">Death:</span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:floruit">
        <span class="srp-label">floruit:</span>
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:sex">
            <span class="srp-label">Sex:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:langKnowledge">
            <span class="srp-label">langKnowledge:</span>
            <xsl:text> </xsl:text>
            <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:langKnown">
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
   
    <!-- Template to print out events -->
    <xsl:template match="t:event" mode="event">
        <li> 
            <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
            <xsl:apply-templates select="child::*" mode="plain"/>
            <!-- Adds dates if available -->
            <xsl:sequence select="local:do-dates(.)"/>
            <!-- Adds footnotes if available -->
            <xsl:if test="@source">
                <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
            </xsl:if>
        </li>
    </xsl:template>
    <xsl:template match="t:location[@type='geopolitical' or @type='relative']">
        <li>
            <xsl:choose>
                <xsl:when test="@subtype='quote'">"<xsl:apply-templates/>"</xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </li>
    </xsl:template>
    
    <!-- Related items -->
    <!-- NOTE still working on this display -->
    <xsl:template match="*:relation" mode="relation">
        <a href="{@uri}">
            <xsl:choose>
                <xsl:when test="child::*/t:place">
                    <xsl:value-of select="child::*/t:place/t:placeName"/>
                </xsl:when>
                <xsl:when test="contains(child::*/t:title,' — ')">
                    <xsl:value-of select="substring-before(child::*[1]/t:title,' — ')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="child::*/t:title"/>
                </xsl:otherwise>
            </xsl:choose>
        </a>
        <xsl:if test="preceding-sibling::*">,</xsl:if>
            <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
        <xsl:if test="@source">
            <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
        </xsl:if>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     handle standard output of 'nested' locations 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:location[@type='nested']">
        <li>Within 
            <xsl:for-each select="t:*">
                <xsl:apply-templates select="."/>
                <xsl:if test="following-sibling::t:*">
                    <xsl:text> within </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
            <xsl:sequence select="local:do-refs(@source,'eng')"/>
        </li>
    </xsl:template>
    <xsl:template match="t:location[@type='gps' and t:geo]">
        <li>Coordinates: 
            <ul class="unstyled offset1">
                <li>
                    <xsl:value-of select="concat('Lat. ',tokenize(t:geo,' ')[1],'°')"/>
                </li>
                <li>
                    <xsl:value-of select="concat('Long. ',tokenize(t:geo,' ')[2],'°')"/>
                    <!--            <xsl:value-of select="t:geo"/>-->
                    <xsl:sequence select="local:do-refs(@source,'eng')"/>
                </li>
            </ul>
        </li>
    </xsl:template>
    <xsl:template match="t:offset | t:measure">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="out-normal"/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     Description templates 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Descriptions without list elements or paragraph elements -->
    <xsl:template match="t:desc" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:label">
        <span class="syr-label">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Descriptions for person abstract  added template for abstracts, handles quotes and references.-->
    <xsl:template match="t:desc[starts-with(@xml:id, 'abstract-en')] | t:note[@type='abstract']" mode="abstract">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- General descriptions within the body of the person element, uses lists -->
    <xsl:template match="t:desc[not(starts-with(@xml:id, 'abstract-en'))]">
        <li>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a listBibl element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:listBibl">
        <ul class="listBibl">
            <xsl:for-each select="t:bibl">
                <li>
                    <xsl:apply-templates select="." mode="biblist"/>
                    <xsl:text>.</xsl:text>
                </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a note element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:note">
        <xsl:variable name="xmlid" select="@xml:id"/>
        <xsl:choose>
            <!-- Adds definition list for depreciated names -->
            <xsl:when test="@type='deprecation'">
                <li>
                    <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>:
                        <xsl:apply-templates/>
                        <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@type='corrigenda' or @type='incerta' or @type ='errata'">
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates/>
                    <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Handles t:link elements for deperciated notes, pulls value from matching element, output element and footnotes -->
    <xsl:template match="t:link">
        <xsl:variable name="elementID" select="substring-after(substring-before(@target,' '),'#')"/>
        <xsl:for-each select="/descendant-or-self::*[@xml:id=$elementID]">
            <xsl:apply-templates select="."/>
            <!-- NOTE: position last is not working? -->
            <!--   <xsl:if test="not(../preceding-sibling::*[@xml:id=$elementID])"><xsl:text>, </xsl:text></xsl:if>-->
            <xsl:text> </xsl:text>
        </xsl:for-each>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a p element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:p">
        <p>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:quote">
        <xsl:choose>
            <xsl:when test="@xml:lang">
                <xsl:text>“</xsl:text>
                <bdi>
                    <xsl:attribute name="dir">
                        <xsl:call-template name="getdirection"/>
                    </xsl:attribute>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </bdi>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <xsl:when test="parent::t:desc/@xml:lang">
                <xsl:text>“</xsl:text>
                <bdi>
                    <xsl:attribute name="dir">
                        <xsl:choose>
                            <xsl:when test="parent::t:desc[@xml:lang='en']">ltr</xsl:when>
                            <xsl:when test="parent::t:desc[@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj']">rtl</xsl:when>
                            <xsl:otherwise>ltr</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </bdi>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>“</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>”</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:date">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:persName | t:region | t:settlement">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1"/>
                    <xsl:when test="starts-with(@ref, $uribase)">
                        <xsl:text> </xsl:text>
                        <a class="persName" href="/person/{substring-after(@ref, $uribase)}.html">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="persName" href="{@ref}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!-- NOTE: added footnotes to all persName if available. Uses local do-refs function -->
                <span class="persName">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates mode="cleanout"/>
                    <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="title">
        <span class="persName">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="text-normal"/>
        </span>
    </xsl:template>
    <xsl:template match="t:persName" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <span dir="ltr" class="label label-default pers-label">
                    <!-- write out the persName itself, with appropriate language and directionality indicia -->
                    <span class="persName">
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <xsl:template match="t:persName">
        <xsl:call-template name="langattr"/>
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    -->
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:addName">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:roleName" mode="text-normal">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename" mode="text-normal">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:addName" mode="text-normal">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the licence element in the tei header
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:licence">
        <xsl:if test="@target">
            <xsl:variable name="licenserev" select="tokenize(@target, '/')[last()-1]"/>
            <xsl:variable name="licensetype" select="tokenize(substring-before(@target, $licenserev), '/')[last()-1]"/>
            <a rel="license" href="{@target}">
                <img alt="Creative Commons License" style="border-width:0" src="http://i.creativecommons.org/l/{$licensetype}/{$licenserev}/80x15.png"/>
            </a>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the ref element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:ref">
        <a href="{@target}">
            <xsl:apply-templates/>
        </a>
    </xsl:template>
    <xsl:template name="get-headword-ele" as="element()*">
        <xsl:choose>
            <xsl:when test="./descendant-or-self::t:listPerson/t:person/t:persName[@syriaca-tags='#syriaca-headword']">
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:persName[@syriaca-tags='#syriaca-headword']"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:persName[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- NOTE: where is this used? Seems to be an issue with syrac text-->
    <xsl:template name="get-description-ele" as="element()*">
        <xsl:choose>
            <xsl:when test="./descendant-or-self::t:listPerson/t:person/t:desc[starts-with(@xml:id, 'abstract-en')]">
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:desc[starts-with(@xml:id, 'abstract-en')]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="./descendant-or-self::t:listPerson/t:person/t:desc[1]"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName[local-name(..)='desc']" mode="cleanout">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <xsl:template match="text()" mode="cleanout">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="t:*" mode="cleanout">
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!-- |||| match=t:*: suppress all TEI elements not otherwise handled -->
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:*"/>
</xsl:stylesheet>