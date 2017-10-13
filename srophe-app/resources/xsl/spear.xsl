<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t s saxon" version="2.0">
    
    <!-- ================================================================== 
       Copyright 2013 New York University
       
       This file is part of the Syriac Reference Portal Places Application.
       
       The Syriac Reference Portal Places Application is free software: 
       you can redistribute it and/or modify it under the terms of the GNU 
       General Public License as published by the Free Software Foundation, 
       either version 3 of the License, or (at your option) any later 
       version.
       
       The Syriac Reference Portal Places Application is distributed in 
       the hope that it will be useful, but WITHOUT ANY WARRANTY; without 
       even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
       PARTICULAR PURPOSE.  See the GNU General Public License for more 
       details.
       
       You should have received a copy of the GNU General Public License
       along with the Syriac Reference Portal Places Application.  If not,
       see (http://www.gnu.org/licenses/).
       
       ================================================================== --> 
    
    <!-- ================================================================== 
       spear.xsl
       
       This XSLT transforms tei.xml to html for SPEAR content.
       
       parameters:
       
        
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
        + Winona Salesky for use with eXist-db
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
    
    <!-- =================================================================== -->
    <!-- TEMPLATES -->
    <!-- =================================================================== -->
    
    <!-- Manuscript templates -->
    <!-- used by spear pages not real tei element -->
    <xsl:template match="t:aggregate-source">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>A Prosopography of </xsl:text>
                <xsl:call-template name="title"/>
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <span class="padding-top">
                <xsl:call-template name="link-icons"/>
            </span>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <span class="helper circle noprint">
                        <p>i</p>
                    </span>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <span id="syriaca-id">
                        <!-- NOTE: temporary fix, the Perm URI will be found in header/sourceDesc -->
                        <xsl:value-of select="concat('http://syriaca.org/spear/aggregate.html?id=',$resource-id)"/>
                    </span>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:aggregate-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>SPEAR Factoids about </xsl:text>
                <xsl:call-template name="title"/>
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <span class="padding-top">
                <xsl:call-template name="link-icons"/>
            </span>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <span class="helper circle noprint">
                        <p>i</p>
                    </span>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
                    </span>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:keyword-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">
                <xsl:text>SPEAR Factoids about </xsl:text>
                <xsl:value-of select="substring-after(//tei:idno,'/keyword/')"/>
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <span class="padding-top">
                <xsl:call-template name="link-icons"/>
            </span>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <span class="helper circle noprint">
                        <p>i</p>
                    </span>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
                    </span>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:factoid-title">
        <div class="row title padding-top">
            <h1 class="col-md-8">SPEAR Factoid </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <span class="padding-top">
                <xsl:call-template name="link-icons"/>
            </span>
        </div>
        <div style="margin:0 1em 1em; color: #999999;">
            <xsl:variable name="current-id">
                <xsl:variable name="idString" select="tokenize($resource-id,'/')[last()]"/>
                <xsl:variable name="idSubstring" select="substring-after($idString,'-')"/>
                <xsl:choose>
                    <xsl:when test="$idSubstring  castable as xs:integer">
                        <xsl:value-of select="$idSubstring cast as xs:integer"/>
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="next-id" select="$current-id + 1"/>
            <xsl:variable name="prev-id" select="$current-id - 1"/>
            <xsl:variable name="next-uri" select="concat(substring-before($resource-id,'-'),'-',string($next-id))"/>
            <xsl:variable name="prev-uri" select="concat(substring-before($resource-id,'-'),'-',string($prev-id))"/>                
            
            <small>
                <span class="uri">
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($prev-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-backward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                    <xsl:text> </xsl:text>
                    <button type="button" class="btn btn-default btn-xs" id="idnoBtn" data-clipboard-action="copy" data-clipboard-target="#syriaca-id">
                        <span class="srp-label">URI</span>
                    </button>
                    <xsl:text> </xsl:text>
                    <span id="syriaca-id">
                        <xsl:value-of select="$resource-id"/>
                    </span>
                    <script>
                        var clipboard = new Clipboard('#idnoBtn');
                        clipboard.on('success', function(e) {
                        console.log(e);
                        });
                        
                        clipboard.on('error', function(e) {
                        console.log(e);
                        });
                    </script>
                    <xsl:text> </xsl:text>
                    <xsl:if test="starts-with($nav-base,'/exist/apps')">
                        <a href="{replace($next-uri,$base-uri,$nav-base)}">
                            <span class="glyphicon glyphicon-forward" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                </span>
            </small>
        </div>
    </xsl:template>
    <xsl:template match="t:spear-headwords">
        <xsl:call-template name="title"/>
    </xsl:template>
    <xsl:template match="t:factoid | t:div[@uri]">
        <div class="factoid">
            <xsl:if test="t:factoid-headword">
                <h4>
                    <xsl:call-template name="title"/>
                </h4>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="descendant::t:div[@uri]/child::t:listPerson">
                    <h4>Person</h4>
                </xsl:when>
                <xsl:when test="descendant::t:div[@uri]/child::t:listEvent">
                    <h4>Person</h4>
                </xsl:when>
                <xsl:when test="descendant::t:div[@uri]/child::t:listRelation">
                    <h4>Relationship</h4>
                </xsl:when>
            </xsl:choose>
            <xsl:for-each select="descendant::t:div[@uri]">
                <xsl:for-each select="child::*[not(self::t:bibl)][not(self::t:listRelation)]/child::*/child::*[not(empty(descendant-or-self::text()))]">
                    <xsl:variable name="label">
                        <xsl:choose>
                            <xsl:when test="name(.) = 'persName'">Name</xsl:when>
                            <xsl:when test="name(.) = 'desc'">Description</xsl:when>
                            <xsl:otherwise><xsl:value-of select="concat(upper-case(substring(name(.),1,1)),substring(name(.),2))"></xsl:value-of></xsl:otherwise>
                        </xsl:choose>                        
                    </xsl:variable>
                    <p><strong><xsl:value-of select="$label"/>: </strong><xsl:apply-templates/></p>
                </xsl:for-each>
            </xsl:for-each>
            <br/>
        </div>
    </xsl:template>
    <xsl:template match="t:aggregate ">
        <div class="spear-aggregate">
        <xsl:choose>
            <xsl:when test="t:div">
                <xsl:for-each-group select="t:div/t:listPerson/t:person/t:persName[. != ''] | t:div/t:listPerson/t:person/t:persName[. != '']" group-by="name(.)">
                    <h4>Name variant(s): </h4>
                    <xsl:for-each select="current-group()">
                       <xsl:sort select="xs:integer(substring-after(ancestor::t:div[1]/@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:copy-of select="."/>

                            <a href="factoid.html?id={string(ancestor::t:div[1]/@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:sex]" group-by="name(t:div[descendant::t:sex][1])">
                    <h4>Sex: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:birth]" group-by="name(t:div[descendant::t:birth][1])">
                    <xsl:for-each-group select=".[descendant::t:birth/t:date]" group-by="name(descendant::t:birth/t:date)">
                        <h4>Birth date: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select=".[descendant::t:birth/t:placeName]" group-by="name(descendant::t:birth/t:placeName)">
                        <h4>Birth Place: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:death]" group-by="name(t:div[descendant::t:death][1])">
                    <xsl:for-each-group select=".[descendant::t:death/t:date]" group-by="name(descendant::t:death/t:date)">
                        <h4>Death date: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                    <xsl:for-each-group select=".[descendant::t:death/t:placeName]" group-by="name(descendant::t:death/t:placeName)">
                        <h4>Death Place: </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:socecStatus]" group-by="name(t:div[descendant::t:socecStatus][1])">
                    <h4>Social rank: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:occupation]" group-by="name(t:div[descendant::t:occupation][1])">
                    <h4>Occupation(s): </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:nationality]" group-by="name(t:div[descendant::t:nationality][1])">
                    <h4>Citizenship: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:residence]" group-by="name(t:div[descendant::t:residence][1])">
                    <h4>Place of residence: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:state]" group-by="name(t:div[descendant::t:state][1])">
                    <xsl:for-each-group select=".[descendant::t:state]" group-by="descendant::t:state/@type">
                        <h4>
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'mental'">Mental state: </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="current-grouping-key()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:education]" group-by="name(t:div[descendant::t:education][1])">
                    <h4>Education: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:langKnowledge]" group-by="name(t:div[descendant::t:langKnowledge][1])">
                    <h4>Language known: </h4>
                    <xsl:for-each select="current-group()">
                        <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                        <p class="indent">
                            <xsl:apply-templates mode="spear"/>
                            <xsl:text> </xsl:text>
                            <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each-group select="t:div[descendant::t:trait]" group-by="name(t:div[descendant::t:trait][1])">
                    <xsl:for-each-group select=".[descendant::t:trait]" group-by="descendant::t:trait/@type">
                        <h4>
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'physical'">Physical trait: </xsl:when>
                                <xsl:when test="current-grouping-key() = 'gender'">Gender: </xsl:when>
                                <xsl:when test="current-grouping-key() = 'ethnicLabel'">Ethnic label: </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="current-grouping-key()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </h4>
                        <xsl:for-each select="current-group()">
                            <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                            <p class="indent">
                                <xsl:apply-templates mode="spear"/>
                                <xsl:text> </xsl:text>
                                <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                                </a>
                            </p>
                        </xsl:for-each>
                    </xsl:for-each-group>
                </xsl:for-each-group>
                <xsl:for-each select="t:div[not(descendant::t:sex |                                           descendant::t:state |                                           descendant::t:occupation |                                           descendant::t:birth |                                           descendant::t:death |                                           descendant::t:education |                                           descendant::t:nationality |                                           descendant::t:residence |                                           descendant::t:langKnowledge |                                           descendant::t:socecStatus |                                           descendant::t:trait |                                          t:listPerson/child::*/t:persName[. != ''])]">
                    <xsl:sort select="xs:integer(substring-after(@uri,'-'))" order="ascending"/>
                    <p class="indent">
                        <xsl:apply-templates mode="spear"/>
                        <xsl:text> </xsl:text>
                        <a href="factoid.html?id={string(@uri)}">See factoid page <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </p>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="spear"/>
            </xsl:otherwise>
        </xsl:choose>
        </div>     
    </xsl:template>
    <xsl:template match="t:spear-teiHeader">
        <p>
            <span class="srp-label">Editor: </span>
            <xsl:value-of select="descendant::t:titleStmt/t:editor[@role='creator']"/>
        </p>
        <xsl:if test="descendant::t:respStmt">
            <div>
                <span class="srp-label">Contributors: </span>
                <xsl:choose>
                    <xsl:when test="count(descendant::t:respStmt) &gt; 2">
                        <xsl:value-of select="count(descendant::t:respStmt)"/> contributors (
                            <a class="togglelink" data-toggle="collapse" data-target="#show-contributors" href="#show-contributors" data-text-swap="Hide"> See all  <i class="glyphicon glyphicon-circle-arrow-right"/>
                        </a>)
                            <div class="collapse" id="show-contributors">
                            <ul>
                                <xsl:for-each select="descendant::t:respStmt">
                                    <li>
                                        <xsl:apply-templates select="."/>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:when>
                    <xsl:otherwise>
                        <ul>
                            <xsl:for-each select="descendant::t:respStmt">
                                <li>
                                    <xsl:apply-templates select="."/>
                                </li>
                            </xsl:for-each>
                        </ul>
                    </xsl:otherwise>
                </xsl:choose>
            </div>
        </xsl:if>
        <xsl:if test="descendant::t:fileDesc/t:publicationStmt/t:date">
            <p>
                <span class="srp-label">Date of Publication: </span>
                <xsl:choose>
                    <xsl:when test="descendant::t:fileDesc/t:publicationStmt/t:date[1]/text() castable as xs:date">
                        <xsl:value-of select="format-date(xs:date(descendant::t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="descendant::t:fileDesc/t:publicationStmt/t:date[1]"/>
                    </xsl:otherwise>
                </xsl:choose>
            </p>
        </xsl:if>
        <p>
            <span class="srp-label">Based on: </span>
            <ul class="list-unstyled indent">
                <xsl:apply-templates select="descendant::t:back/descendant::t:bibl" mode="footnote"/>
            </ul>
        </p>
    </xsl:template>
    <xsl:template match="t:spear-sources">
        <xsl:call-template name="sources"/>
    </xsl:template>
    <xsl:template mode="spear" match="*">
        <xsl:choose>
            <xsl:when test="self::t:bibl"/>
            <xsl:otherwise>
                <xsl:apply-templates mode="spear"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:sex | t:state | t:persName | t:occupation | t:birth | t:death          | t:education | t:nationality | t:residence | t:langKnowledge | t:socecStatus | t:trait" mode="spear">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:listRelation" mode="spear"/>
    <!-- Needs work -->
    <xsl:template match="t:spear-citation">
        <xsl:if test="t:bibl">
            <div class="well">
                <!-- Sources -->
                <div id="sources">
                    <h3>Sources</h3>
                    <p>
                        <small>Any information without attribution has been created following the Syriaca.org <a href="http://syriaca.org/documentation/">editorial guidelines</a>.</small>
                    </p>
                    <ul>
                        <xsl:apply-templates select="t:bibl" mode="footnote"/>
                    </ul>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>