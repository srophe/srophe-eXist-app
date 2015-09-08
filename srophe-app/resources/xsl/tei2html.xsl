<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:s="http://syriaca.org" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" xmlns:x="http://www.w3.org/1999/xhtml" exclude-result-prefixes="xs t s saxon" version="2.0">

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
       tei2html.xsl
       
       This XSLT transforms tei.xml to html.
       
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
 <!-- import component stylesheets for HTML page portions -->
 <!-- =================================================================== -->
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
    <xsl:import href="manuscripts.xsl"/>
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
    
    <!-- Parameters passed from app.xql default values if params are empty -->
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <xsl:param name="normalization">NFKC</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc" select="concat($app-root,'/documentation/editors.xml')"/>
    <!--<xsl:param name="uribase">http://syriaca.org/</xsl:param>-->
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="replace(/descendant::t:idno[@type='URI'][starts-with(.,'http://syriaca.org/')][1],'/tei','')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
 <!-- =================================================================== -->
 <!-- TEMPLATES -->
 <!-- =================================================================== -->


 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
 <!-- |||| Root template matches tei root -->
 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:TEI">
        <!-- Header -->
        <xsl:choose>
            <xsl:when test="descendant::*[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'en')]">
                <xsl:call-template name="h1"/>
            </xsl:when>
            <xsl:when test="t:teiHeader/t:fileDesc/t:titleStmt">
                <xsl:apply-templates select="t:teiHeader/t:fileDesc/t:titleStmt"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="h1"/>
            </xsl:otherwise>
        </xsl:choose>
        
        <!-- Body -->
        <xsl:apply-templates select="t:text/t:body/child::*"/>
        
        <!-- Sources 
        <xsl:if test="t:text/t:body/child::*/child::*/t:bibl">
            <xsl:call-template name="sources">
                <xsl:with-param name="node" select="t:text/t:body/child::*/child::*"/>
            </xsl:call-template>
        </xsl:if>
        -->
        <!-- Citation Information -->        
        <!-- Citations -->
        <xsl:call-template name="citationInfo"/>
    </xsl:template>
   
    <!-- Template for page titles -->
    <xsl:template match="t:srophe-title">
        <xsl:call-template name="h1"/>
    </xsl:template>
    <xsl:template match="t:titleStmt">
        <xsl:call-template name="h1"/>
    </xsl:template>
    
    <!-- Main page modules for syriaca.org display -->
    <xsl:template match="t:place | t:person | t:spear | t:bibl[starts-with(@xml:id,'work-')]">
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
        <xsl:if test="self::t:person">
            <div id="persnames">
                <xsl:if test="string-length(t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']) &gt; 1">
                    <div style="margin-bottom:1em;">
                        <h4>Identity</h4>
                        <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']" mode="abstract"/>
                    </div>
                </xsl:if>
                <xsl:if test="t:persName">
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
                        <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="list">
                            <xsl:sort collation="{$mixed}" select="."/>
                        </xsl:apply-templates>
                    </p>
                </xsl:if>
                <br class="clearfix"/>
                <div>
                    <xsl:apply-templates select="t:sex"/>
                </div>
            </div>
        </xsl:if>
        <xsl:if test="self::t:bibl">
            <div class="well">
                <xsl:if test="string-length(t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']) &gt; 1">
                    <h3>Abstract</h3>
                    <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']" mode="abstract"/>
                </xsl:if>
                <xsl:if test="t:title">
                    <h3>Titles:</h3>
                    <ul>
                        <xsl:apply-templates select="t:title[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'syr')]" mode="list">
                            <xsl:sort lang="syr" select="."/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="t:title[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'en')]" mode="list">
                            <xsl:sort collation="{$mixed}" select="."/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="t:title[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                            <xsl:sort lang="syr" select="."/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="t:title[starts-with(@xml:lang, 'ar')]" mode="list">
                            <xsl:sort lang="ar" select="."/>
                        </xsl:apply-templates>
                        <xsl:apply-templates select="t:title[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="list">
                            <xsl:sort collation="{$mixed}" select="."/>
                        </xsl:apply-templates>
                    </ul>
                </xsl:if>
                <xsl:if test="t:idno[not(@type='URI')]">
                    <p>
                        <xsl:for-each select="t:idno[not(@type='URI')]">
                            <xsl:choose>
                                <xsl:when test="@type = 'BHSYRE'">
                                    <xsl:value-of select="concat(replace(@type,'BHSYRE','BHS'),': ',.)"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="concat(@type,': ',.)"/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
                    </p>
                </xsl:if>
            </div>
        </xsl:if>
        <xsl:if test="self::t:place">
            <xsl:if test="t:placeName">
                <div id="placenames" class="well">
                    <h3>Names</h3>
                    <xsl:apply-templates select="t:placeName[@syriaca-tags='#syriaca-headword' and @xml:lang='syr']" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[@syriaca-tags='#syriaca-headword' and @xml:lang='en']" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="list">
                        <xsl:sort lang="syr" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[starts-with(@xml:lang, 'ar')]" mode="list">
                        <xsl:sort lang="ar" select="."/>
                    </xsl:apply-templates>
                    <xsl:apply-templates select="t:placeName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="list">
                        <xsl:sort collation="{$mixed}" select="."/>
                    </xsl:apply-templates>
                </div>
            </xsl:if>
            <!-- Related Places -->
            <xsl:if test="t:related-places/child::*">
                <div id="relations" class="well">
                    <h3>Related Places</h3>
                    <ul>
                        <xsl:apply-templates select="//t:relation" mode="related-place"/>
                    </ul>
                </div>
            </xsl:if>
        </xsl:if>
        <xsl:if test="t:related-items/descendant::t:relation and self::t:person">
            <xsl:if test="not(t:related-items/descendant::t:geo)">
                <h2>Related Places in the Syriac Gazetteer</h2>
            </xsl:if>
            <div>
                <xsl:if test="t:related-items/t:relation[contains(@uri,'place')]">
                    <div>
                        <dl class="dl-horizontal dl-srophe">
                            <xsl:for-each-group select="t:related-items/t:relation[contains(@uri,'place')]" group-by="@name">
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
                                    <xsl:value-of select="substring(t:desc,1,$desc-ln - 1)"/>:
                                    <xsl:for-each select="current-group()">
                                        <xsl:apply-templates select="." mode="relation"/>
                                        <!--<xsl:if test="position() != last()">, </xsl:if>-->
                                    </xsl:for-each>
                                </dd>
                            </xsl:for-each-group>
                        </dl>
                    </div>
                </xsl:if>
                <xsl:if test="t:related-items/t:relation[contains(@uri,'person')]">
                    <div id="relations" class="well">
                        <h3>Related People</h3>
                        <!-- NOTE: currently in list, changed to approved format, list or inline -->
                        <ul>
                            <xsl:for-each-group select="t:related-items/t:relation[contains(@uri,'person')]" group-by="@name">
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
            </div>
        </xsl:if>
        <xsl:if test="t:related-places and self::t:person">
            <div>
                <dl class="dl-horizontal dl-srophe">
                    <xsl:for-each-group select="t:related-places/t:relation[contains(@uri,'place')]" group-by="@name">
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
                            <xsl:value-of select="substring(t:desc,1,$desc-ln - 1)"/>:
                            <xsl:for-each select="current-group()">
                                <xsl:apply-templates select="." mode="relation"/>
                                <!--<xsl:if test="position() != last()">, </xsl:if>-->
                            </xsl:for-each>
                        </dd>
                    </xsl:for-each-group>
                </dl>
            </div>
        </xsl:if>
        
        <!-- Confessions/Religious Communities -->
        <xsl:if test="t:confessions/t:state[@type='confession']">
            <div id="description">
                <h3>Known Religious Communities</h3>
                <p class="caveat">
                    <em>This list is not necessarily exhaustive, and the order does not represent importance or proportion of the population. Dates do not represent starting or ending dates of a group's presence, but rather when they are attested. Instead, the list only represents groups for which Syriaca.org has source(s) and dates.</em>
                </p>
                <xsl:call-template name="confessions"/>
            </div>
        </xsl:if>
        
        <!-- State for persons? NEEDS WORK -->
        <xsl:if test="t:state[not(@type='confession')]">
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
        <!-- Events -->
        <xsl:if test="t:event[not(@type='attestation')]">
            <div id="event">
                <h3>Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if>
                </h3>
                <ul>
                    <xsl:apply-templates select="t:event[not(@type='attestation')]" mode="event"/>
                </ul>
            </div>
        </xsl:if>
        
        <!-- Events/attestation -->
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
        
        <!-- Notes -->
        <!-- NOTE: need to handle abstract notes -->
        <xsl:if test="t:note[not(@type='abstract')]">
            <xsl:for-each-group select="t:note[not(@type='abstract')][exists(@type)]" group-by="@type">
                <h3>
                    <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                </h3>
                <ul>
                    <xsl:for-each select="current-group()">
                        <xsl:apply-templates select="self::*"/>
                    </xsl:for-each>
                </ul>
            </xsl:for-each-group>
            <xsl:for-each select="t:note[not(exists(@type))]">
                <h3>Note</h3>
                <div class="left-padding bottom-padding">
                    <xsl:apply-templates/>
                </div>
            </xsl:for-each>
        </xsl:if>
        <xsl:if test="t:bibl">
            <xsl:call-template name="sources"/>
        </xsl:if>
        <xsl:if test="t:srophe-citation">
            <xsl:call-template name="citationInfo"/>
        </xsl:if>
        <!-- Contains: -->
        <xsl:if test="t:nested-place">
            <div id="contents">
                <h3>Contains</h3>
                <ul>
                    <xsl:for-each select="/child::*/t:nested-place">
                        <xsl:sort collation="{$mixed}" select="t:placeName[@xml:lang='en'][1]/@reg"/>
                        <li>
                            <a href="{concat('/place/',@id,'.html')}">
                                <xsl:value-of select="."/>
                                <xsl:value-of select="concat(' (',@type,')')"/>
                            </a>
                        </li>
                    </xsl:for-each>
                </ul>
            </div>
        </xsl:if>
        <xsl:if test="self::t:person/@ana ='#syriaca-saint'">
            <div>
                <h3>Lives</h3>
                <p>
                    [Under preparation. Syriaca.org is preparing a database of Syriac saints lives, Biblioteca Hagiographica Syriaca Electronica, which will include links to lives for saints here.]
                </p>
            </div>
        </xsl:if>
        
        <!-- Build citation -->
        <xsl:if test="t:citation">
            <xsl:call-template name="citationInfo"/>
        </xsl:if>
        <!-- Build see also -->
        <xsl:if test="t:see-also">
            <xsl:call-template name="link-icons-list">
                <xsl:with-param name="title">
                    <xsl:value-of select="@title"/>
                </xsl:with-param>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    
    <!-- used by search pages not real tei element -->
    <xsl:template match="t:search">
        <!-- Output elements without links -->
        <xsl:apply-templates mode="title"/>
    </xsl:template>
    <!-- used by spear pages not real tei element -->
    <xsl:template match="t:factoid">
        <xsl:if test="string-length(.) &gt; 1">
            <!-- Output elements without links -->
            <div class="panel panel-default">
                <div class="panel-heading clearfix">
                    <h4 class="panel-title pull-left" style="padding-top: 7.5px;">Factoid(s)</h4>
                </div>
                <div class="panel-body">
                    <xsl:for-each select=".">
                        <xsl:apply-templates/>
                        <xsl:if test="/@type != 'event-factoid'">
                            <a href="factoid.html?id={string(ancestor::tei:div/@uri)}">See factoid <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                            </a>
                        </xsl:if>
                    </xsl:for-each>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <!-- suppress bibl -->
    <xsl:template match="t:bibl" mode="title"/>
    <xsl:template name="h1">
        <xsl:if test="descendant-or-self::tei:srophe-title[contains(@ana,'syriaca-saint')]">
            <div style="margin-left:-2em; margin-top:-1em; padding-top:0;">
                <span class="dropdown inline">
                    <button class="btn btn-link dropdown-toggle" type="button" id="saintsMenu" data-toggle="dropdown" aria-expanded="true">
                        <img alt="Syriac.org: Persons" src="/exist/apps/srophe/resources/img/icons-saints.png"/>
                        <span class="caret"/>
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="saintsMenu">
                        <li>
                            <a href="/saints/index.html">Saints home</a>
                        </li>
                        <li class="divider"/>
                        <li>
                            <a href="/saints/browse.html">Saints index</a>
                        </li>
                        <li class="divider"/>
                        <li>
                            <a href="/saints/search.html">Saints search</a>
                        </li>
                    </ul>
                </span>
            </div>
        </xsl:if>
        <xsl:if test="descendant::tei:srophe-title[contains(@ana,'syriaca-author')]">
            <div style="margin-left:-2em; margin-top:-1em; padding-top:0;">
                <span class="dropdown inline">
                    <button class="btn btn-link dropdown-toggle" type="button" id="authorsMenu" data-toggle="dropdown" aria-expanded="true">
                        <img alt="Syriac.org: Persons" src="/exist/apps/srophe/resources/img/icons-authors.png"/>
                        <span class="caret"/>
                    </button>
                    <ul class="dropdown-menu" role="menu" aria-labelledby="authorsMenu">
                        <li>
                            <a href="/authors/index.html">Authors home</a>
                        </li>
                        <!--
                    <li class="divider"/>
                    <li>
                        <a href="/authors/index.html">Saints index</a>
                    </li>
                    <li class="divider"/>
                    <li>
                        <a href="/authors/index.html">Saints search</a>
                    </li>
                    -->
                    </ul>
                </span>
            </div>
        </xsl:if>
        <div class="row title">
            <h1 class="col-md-8">
                <xsl:call-template name="title"/>
                <!-- Format title, calls template in place-title-std.xsl -->
            </h1>
            <!-- Call link icons (located in link-icons.xsl) -->
            <xsl:call-template name="link-icons"/>   
            <!-- End Title -->
        </div>
        <!-- emit record URI and associated help links -->
        <div style="margin:0 1em 1em; color: #999999;">
            <small>
                <a href="../documentation/terms.html#place-uri" title="Click to read more about Place URIs" class="no-print-link">
                    <div class="helper circle noprint">
                        <p>i</p>
                    </div>
                </a>
                <p>
                    <span class="srp-label">URI</span>
                    <xsl:text>: </xsl:text>
                    <xsl:value-of select="$resource-id"/>
                </p>
            </small>
        </div>
    </xsl:template>
    <xsl:template name="title">
        <xsl:choose>
            <xsl:when test="descendant::*[@syriaca-tags='#syriaca-headword']">
                <xsl:apply-templates select="descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'en')][1]" mode="plain"/>
                    <!--<xsl:value-of select="string(descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'en')][1])"/>--> - 
                <xsl:choose>
                    <xsl:when test="descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'syr')]">
                        <span lang="syr" dir="rtl">
                            <xsl:apply-templates select="descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'syr')][1]" mode="plain"/>
                            <!--<xsl:value-of select="string(descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'syr')])"/>-->
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        [ Syriac Not Available ]
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="descendant-or-self::*[not(self::t:idno)]/text()"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="t:srophe-title[@ana] or t:srophe-title/t:birth or t:srophe-title/t:death">
            (
            <xsl:for-each select="tokenize(t:srophe-title/@ana,' ')">
                <xsl:value-of select="substring-after(.,'#syriaca-')"/>
                <xsl:if test="position() != last()">, </xsl:if>
            </xsl:for-each>
            <xsl:if test="t:srophe-title/@ana and t:srophe-title/t:death or t:srophe-title/t:birth">, 
                <xsl:if test="not(t:srophe-title/t:death)">b. </xsl:if>
                <xsl:value-of select="t:srophe-title/t:birth/text()"/>
                <xsl:if test="t:srophe-title/t:death">
                    <xsl:choose>
                        <xsl:when test="t:srophe-title/t:birth"> - </xsl:when>
                        <xsl:otherwise>d. </xsl:otherwise>
                    </xsl:choose>
                    <xsl:value-of select="t:srophe-title/t:death/text()"/>
                </xsl:if>
            </xsl:if>
            )
        </xsl:if>
    </xsl:template>
    <xsl:template name="citationInfo">
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
    <xsl:template name="sources">
        <xsl:param name="node"/>
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
    <xsl:template match="t:title">
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::t:title">
            <xsl:text>: </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:foreign">
        <xsl:choose>
            <xsl:when test="starts-with(@xml:lang,'syr') or starts-with(@xml:lang,'ar')">
                <span lang="syr" dir="rtl">
                    <xsl:value-of select="."/>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:event">
            <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
        <xsl:apply-templates select="child::*" mode="plain"/>
            <!-- Adds dates if available -->
        <xsl:sequence select="local:do-dates(.)"/>
            <!-- Adds footnotes if available -->
        <xsl:if test="@source">
            <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:choice">
        <xsl:text> </xsl:text>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:orig | t:sic">
        <xsl:text> (</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>) </xsl:text>
    </xsl:template>
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
    <!-- Not real tei element -->
    <xsl:template match="t:pers-group">
        <h4>Person</h4>
        <xsl:apply-templates select="*[not(t:listPerson/t:person/t:persName)]"/>
    </xsl:template>
    <xsl:template match="t:listPerson">
        <xsl:choose>
            <!-- Used by spear -->
            <xsl:when test="/t:factoid">
                <li>
                    <xsl:apply-templates/>
                    <xsl:if test="/t:factoid/@type != 'event-factoid'">
                        <a href="factoid.html?id={string(ancestor::tei:div/@uri)}">
                        See factoid <span class="glyphicon glyphicon-circle-arrow-right" aria-hidden="true"/>
                        </a>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li>
                    <xsl:apply-templates/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:biblScope"/>
    <xsl:template match="t:listRelation">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Template to print out confession section -->
    <xsl:template match="t:state[@type='confession']">
        <!-- Get all ancesors of current confession (but only once) -->
        <xsl:variable name="confessions" select="document(concat($app-root,'/documentation/confessions.xml'))//t:body/t:list"/>
        <xsl:variable name="id" select="substring-after(@ref,'#')"/>
        <li>
            <xsl:value-of select="$id"/>: 
            <xsl:for-each select="$confessions//t:item[@xml:id = $id]/ancestor-or-self::*/t:label">
                <xsl:value-of select="."/>
            </xsl:for-each>
        </li>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++  
     handle  output of  locations 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
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
    <xsl:template match="t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- Descriptions for place abstract  added template for abstracts, handles quotes and references.-->
    <xsl:template match="t:desc[starts-with(@xml:id, 'abstract-en')]" mode="abstract">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    
    <!-- General descriptions within the body of the place element, uses lists -->
    <xsl:template match="t:desc[not(starts-with(@xml:id, 'abstract-en'))]">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    <xsl:template match="t:state | t:birth | t:death | t:floruit | t:sex | t:langKnowledge">
        <span class="srp-label">
            <xsl:choose>
                <xsl:when test="self::t:birth">Birth:</xsl:when>
                <xsl:when test="self::t:death">Death:</xsl:when>
                <xsl:when test="self::t:floruit">Floruit:</xsl:when>
                <xsl:when test="self::t:sex">Sex:</xsl:when>
                <xsl:when test="self::t:langKnowledge">Language Knowledge:</xsl:when>
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
    <xsl:template match="t:langKnown">
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of a listBibl element 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:listBibl">
        <ul class="listBibl">
            <xsl:for-each select="t:bibl">
                <li>
                    <xsl:apply-templates mode="biblist"/>
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
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                    <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:note" mode="abstract">
        <p>
            <xsl:apply-templates/>
        </p>
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
                <span dir="ltr">
                    <xsl:text> “</xsl:text>
                </span>
                <span>
                    <xsl:attribute name="dir">
                        <xsl:call-template name="getdirection"/>
                    </xsl:attribute>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </span>
                <span dir="ltr">
                    <xsl:text>” </xsl:text>
                </span>
            </xsl:when>
            <xsl:when test="parent::t:desc/@xml:lang">
                <span dir="ltr">
                    <xsl:text> “</xsl:text>
                </span>
                <span class="langattr">
                    <xsl:attribute name="dir">
                        <xsl:choose>
                            <xsl:when test="parent::t:desc[@xml:lang='en']">ltr</xsl:when>
                            <xsl:when test="parent::t:desc[@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj']">rtl</xsl:when>
                            <xsl:otherwise>ltr</xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <xsl:attribute name="lang">
                        <xsl:value-of select="parent::t:desc/@xml:lang"/>
                    </xsl:attribute>
                    <!--
                    <xsl:attribute name="xml:lang">
                        <xsl:value-of select="parent::t:desc/@xml:lang"/>
                    </xsl:attribute>
                    -->
                    <xsl:apply-templates/>
                </span>
                <span dir="ltr">
                    <xsl:text>” </xsl:text>
                </span>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>“</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>”</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <span class="langattr">
            <xsl:attribute name="dir">
                <xsl:choose>
                    <xsl:when test="parent::t:desc[@xml:lang='en']">ltr</xsl:when>
                    <xsl:when test="parent::t:desc[@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj']">rtl</xsl:when>
                    <xsl:otherwise>ltr</xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
            <xsl:choose>
                <xsl:when test="@source">
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </xsl:when>
                <xsl:when test="parent::*/@source">
                    <xsl:sequence select="local:do-refs(parent::*/@source,ancestor::t:*[@xml:lang][1])"/>
                </xsl:when>
            </xsl:choose>
        </span>
    </xsl:template>
    <xsl:template match="t:persName | t:region | t:settlement | t:placeName">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1"/>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <a class="{local-name(.)}" href="{@ref}">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates/>
                        </a>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <span class="{local-name(.)}">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
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
    <xsl:template match="t:persName" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename | t:addName">
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
    <xsl:template match="t:forename | t:addName" mode="text-normal">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:placeName | t:title" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <li dir="ltr">
                    <!-- write out the placename itself, with appropriate language and directionality indicia -->
                    <span class="placeName">
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </span>
                    <xsl:sequence select="local:do-refs(@source,ancestor::t:*[@xml:lang][1])"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:list">
        <ul>
            <xsl:apply-templates/>
        </ul>
    </xsl:template>
    <xsl:template match="t:item">
        <li>
            <xsl:apply-templates/>
        </li>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle standard output of the licence element in the tei header
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:licence">
        <xsl:if test="@target">
            <a rel="license" href="{@target}">
                <img alt="Creative Commons License" style="border-width:0" src="/exist/apps/srophe/resources/img/cc.png" height="18px"/>
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
    
    
    <!-- NOTE: would really like to get rid of mode=cleanout -->
    <xsl:template match="t:placeName[local-name(..)='desc']" mode="cleanout">
        <xsl:apply-templates select="."/>
    </xsl:template>
    <xsl:template match="text()" mode="cleanout">
        <xsl:value-of select="."/>
    </xsl:template>
    <xsl:template match="t:*" mode="cleanout">
        <xsl:apply-templates mode="cleanout"/>
    </xsl:template>
    <xsl:template name="getdirection">
        <xsl:choose>
            <xsl:when test="@xml:lang='en'">ltr</xsl:when>
            <xsl:when test="@xml:lang='syr' or @xml:lang='ar' or @xml:lang='syc' or @xml:lang='syr-Syrj'">rtl</xsl:when>
            <xsl:when test="not(@xml:lang)">
                <xsl:text/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!-- |||| match=t:*: suppress all TEI elements not otherwise handled -->
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!--<xsl:template match="t:*"/>-->
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     Special Gazetteer templates 
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <!-- Named template to handle nested confessions -->
    <xsl:template name="confessions">
        <!-- Variable stores all confessions from confessions.xml -->
        <xsl:variable name="confessions" select="t:confessions/descendant::t:list"/>
        <xsl:variable name="place-data" select="t:confessions"/>
        <!-- Variable to store the value of the confessions of current place-->
        <xsl:variable name="current-confessions">
            <xsl:for-each select="//t:state[@type='confession']">
                <xsl:variable name="id" select="substring-after(@ref,'#')"/>
                <!-- outputs current confessions as a space seperated list -->
                <xsl:value-of select="concat($id,' ')"/>
            </xsl:for-each>
        </xsl:variable>
        <!-- Works through the tree structure in the confessions.xml to output only the relevant confessions -->
        <xsl:for-each select="t:confessions/descendant::t:list[1]">
            <ul>
                <!-- Checks for top level confessions that may have a match or a descendant with a match, supresses any that do not -->
                <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                    <!-- Goes through each item to check for a match or a child match -->
                    <xsl:for-each select="t:item">
                        <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                            <!-- output current level -->
                            <li>
                                <!-- print label -->
                                <xsl:apply-templates select="t:label" mode="confessions"/>
                                <!-- build dates based on attestation information -->
                                <xsl:call-template name="confession-dates">
                                    <xsl:with-param name="place-data" select="$place-data"/>
                                    <xsl:with-param name="confession-id" select="@xml:id"/>
                                </xsl:call-template>
                                <!-- check next level -->
                                <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                    <ul>
                                        <xsl:for-each select="child::*/t:item">
                                            <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                <li>
                                                    <xsl:apply-templates select="t:label" mode="confessions"/>
                                                    <!-- build dates based on attestation information -->
                                                    <xsl:call-template name="confession-dates">
                                                        <xsl:with-param name="place-data" select="$place-data"/>
                                                        <xsl:with-param name="confession-id" select="@xml:id"/>
                                                    </xsl:call-template>
                                                    <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                                        <ul>
                                                            <xsl:for-each select="child::*/t:item">
                                                                <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                                    <li>
                                                                        <xsl:apply-templates select="t:label" mode="confessions"/>
                                                                        <!-- build dates based on attestation information -->
                                                                        <xsl:call-template name="confession-dates">
                                                                            <xsl:with-param name="place-data" select="$place-data"/>
                                                                            <xsl:with-param name="confession-id" select="@xml:id"/>
                                                                        </xsl:call-template>
                                                                        <xsl:if test="descendant::t:item[contains($current-confessions,@xml:id)]">
                                                                            <ul>
                                                                                <xsl:for-each select="child::*/t:item">
                                                                                    <xsl:if test="descendant-or-self::t:item[contains($current-confessions,@xml:id)]">
                                                                                        <li>
                                                                                            <xsl:apply-templates select="t:label" mode="confessions"/>
                                                                                            <!-- build dates based on attestation information -->
                                                                                            <xsl:call-template name="confession-dates">
                                                                                                <xsl:with-param name="place-data" select="$place-data"/>
                                                                                                <xsl:with-param name="confession-id" select="@xml:id"/>
                                                                                            </xsl:call-template>
                                                                                        </li>
                                                                                    </xsl:if>
                                                                                </xsl:for-each>
                                                                            </ul>
                                                                        </xsl:if>
                                                                    </li>
                                                                </xsl:if>
                                                            </xsl:for-each>
                                                        </ul>
                                                    </xsl:if>
                                                </li>
                                            </xsl:if>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:if>
                            </li>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:if>
            </ul>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Create labels for confessions -->
    <xsl:template match="t:label" mode="confessions">
        <xsl:value-of select="."/>
    </xsl:template>
    
    <!-- Named template to build confession dates bassed on attestation dates -->
    <xsl:template name="confession-dates">
        <!-- param passes place data for processing -->
        <xsl:param name="place-data"/>
        <!-- confession id -->
        <xsl:param name="confession-id"/>
        <!-- find confessions in place data using confession-id -->
        <xsl:choose>
            <xsl:when test="$place-data//t:state[@type='confession' and substring-after(@ref,'#') = $confession-id]">
                <xsl:variable name="child-id" select="string-join(descendant-or-self::t:item/@xml:id,' ')"/>
                <xsl:for-each select="$place-data//t:state[@type='confession' and substring-after(@ref,'#') = $confession-id]">
                    <!-- Build ref id to find attestations -->
                    <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                    <!-- Find attestations with matching confession-id in link/@target  -->
                    <xsl:choose>
                        <xsl:when test="//t:event[@type='attestation' and child::*[contains(@target,$ref-id)] ]">
                            <!-- If there is a match process dates -->
                            (<xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)] ]">
                                <!-- Sort dates -->
                                <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                                <xsl:choose>
                                    <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                    <xsl:when test="./@when">
                                        <xsl:choose>
                                            <xsl:when test="position() = 1">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                            </xsl:when>
                                            <xsl:when test="position()=last()">, as late as <xsl:value-of select="local:trim-date(@when)"/>
                                            </xsl:when>
                                            <xsl:otherwise/>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- process @notBefore dates -->
                                    <xsl:when test="./@notBefore">
                                        <xsl:choose>
                                            <xsl:when test="position() = 1">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:if test="preceding-sibling::*">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notBefore)"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </xsl:when>
                                    <!-- process @notAfter dates -->
                                    <xsl:when test="./@notAfter">
                                        <xsl:if test="./@notBefore">, </xsl:if>as late as <xsl:value-of select="local:trim-date(@notAfter)"/>
                                    </xsl:when>
                                    <xsl:otherwise/>
                                </xsl:choose>
                            </xsl:for-each>
                            <xsl:if test="count(//t:event[@type='attestation' and child::*[contains(@target,$ref-id)] ]) = 1">
                                <xsl:choose>
                                    <xsl:when test="//t:event[@type='attestation' and child::*[contains(@target,$ref-id)]][@notBefore] or //t:event[@type='attestation' and child::*[contains(@target,$ref-id)]][@when]">
                                        <xsl:variable name="end-date-list">
                                            <xsl:for-each select="//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                                                <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                                                <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                                                <!-- Checks for attestations that reference any children of the current confession -->
                                                <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                                                    <xsl:if test="@when or @notAfter">
                                                        <xsl:variable name="date" select="@when | @notAfter"/>
                                                        <li date="{string($date)}">as late as <xsl:value-of select="local:trim-date($date)"/>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:variable name="end-date">
                                            <xsl:for-each select="$end-date-list/child::*">
                                                <!-- sorts list by date and outputs first date -->
                                                <xsl:sort select="@date"/>
                                                <xsl:if test="position()=last()">
                                                    <xsl:value-of select="."/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="concat(', ',$end-date)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:variable name="start-date-list">
                                            <xsl:for-each select="//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                                                <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                                                <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                                                <!-- Checks for attestations that reference any children of the current confession -->
                                                <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                                                    <xsl:if test="@when or @notBefore">
                                                        <xsl:variable name="date" select="@when |@notBefore"/>
                                                        <li date="{string($date)}">
                                                            <xsl:choose>
                                                                <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                                                <xsl:when test="./@when">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                                                </xsl:when>
                                                                <!-- process @notBefore dates -->
                                                                <xsl:when test="./@notBefore">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                                                </xsl:when>
                                                            </xsl:choose>
                                                        </li>
                                                    </xsl:if>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:variable name="start-date">
                                            <xsl:for-each select="$start-date-list/child::*">
                                                <!-- sorts list by date and outputs first date -->
                                                <xsl:sort select="@date"/>
                                                <xsl:if test="position()=1">
                                                    <xsl:value-of select="."/>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:variable>
                                        <xsl:value-of select="concat($start-date,', ')"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>)
                        </xsl:when>
                        <!-- If not attestation information -->
                        <xsl:otherwise> 
                            (no attestations yet recorded)
                        </xsl:otherwise>
                    </xsl:choose>
                    <!-- Add refs if they exist -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,'eng')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise> 
                <!-- Checks for children with of current confession by checking confessions.xml information -->
                <xsl:variable name="child-id" select="string-join(descendant-or-self::t:item/@xml:id,' ')"/>
                <!-- Checks for existing children of current confession by matching against child-id -->
                <xsl:variable name="start-date-list">
                    <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                        <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                        <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                        <!-- Checks for attestations that reference any children of the current confession -->
                        <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                            <xsl:if test="@when or @notBefore">
                                <xsl:variable name="date" select="@when |@notBefore"/>
                                <li date="{string($date)}">
                                    <xsl:choose>
                                        <!-- process @when dates use, local:trim-date function to trim 0 from dates-->
                                        <xsl:when test="./@when">attested as early as <xsl:value-of select="local:trim-date(@when)"/>
                                        </xsl:when>
                                        <!-- process @notBefore dates -->
                                        <xsl:when test="./@notBefore">attested around <xsl:value-of select="local:trim-date(@notBefore)"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="start-date">
                    <xsl:for-each select="$start-date-list/child::*">
                        <!-- sorts list by date and outputs first date -->
                        <xsl:sort select="@date"/>
                        <xsl:if test="position()=1">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- Looks for end dates -->
                <xsl:variable name="end-date-list">
                    <xsl:for-each select="$place-data//t:state[@type='confession' and contains($child-id,substring-after(@ref,'#'))]">
                        <xsl:variable name="confession-id" select="substring-after(@ref,'#')"/>
                        <xsl:variable name="ref-id" select="concat('#',@xml:id)"/>
                        <!-- Checks for attestations that reference any children of the current confession -->
                        <xsl:for-each select="//t:event[@type='attestation' and t:link[contains(@target,$ref-id)]]">
                            <xsl:if test="@when or @notAfter">
                                <xsl:variable name="date" select="@when | @notAfter"/>
                                <li date="{string($date)}">as late as <xsl:value-of select="local:trim-date($date)"/>
                                </li>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="end-date">
                    <xsl:for-each select="$end-date-list/child::*">
                        <!-- sorts list by date and outputs first date -->
                        <xsl:sort select="@date"/>
                        <xsl:if test="position()=last()">
                            <xsl:value-of select="."/>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:variable>
                
                <!-- Putting start and end dates together -->
                <xsl:if test="(string-length($start-date) &gt; 1) or string-length($end-date) &gt;1">
                    (<xsl:if test="string-length($start-date) &gt; 1">
                        <xsl:value-of select="$start-date"/>
                    </xsl:if>
                    <xsl:if test="string-length($end-date) &gt;1">
                        <xsl:if test="string-length($start-date) &gt; 1">, </xsl:if>
                        <xsl:value-of select="$end-date"/>
                    </xsl:if>)
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> 
        
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
        Related Places templates 
        matches the following structure generated by place.xql: 
                <related-items xmlns="http://www.w3.org/1999/xhtml">
                     <relation id="876" 
                             uri="http://syriaca.org/place/876" 
                             varient="passive" 
                             name="contains" 
                             active="#place-602" 
                             passive="http://syriaca.org/place/876 http://syriaca.org/place/1947 http://syriaca.org/place/666 http://syriaca.org/place/507" 
                             source="#bib602-2">
                                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name876-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib876-1 #bib876-2">Trichur</placeName>
                            </relation>
                            <relation id="1947" uri="http://syriaca.org/place/1947" varient="passive" name="contains" active="#place-602" passive="http://syriaca.org/place/876 http://syriaca.org/place/1947 http://syriaca.org/place/666 http://syriaca.org/place/507" source="#bib602-2">
                                <placeName xmlns="http://www.tei-c.org/ns/1.0" xml:id="name1947-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib1947-1">Kottayam</placeName>
                            </relation>                
                   </related-items> 
  
          <tei:related-places>
                                    <relation varient="mutual">
                                        <mutual id="#place-139" name="share-a-name" mutual="#place-139  http://syriaca.org/place/722  http://syriaca.org/place/2346"></mutual>
                                        <mutual id="722" name="share-a-name" mutual="#place-139  http://syriaca.org/place/722  http://syriaca.org/place/2346" type="region">
                                            <placeName xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.tei-c.org/ns/1.0" xml:id="name722-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib722-1">Mosul</placeName>
                                        </mutual>
                                        <mutual id="2346" name="share-a-name" mutual="#place-139  http://syriaca.org/place/722  http://syriaca.org/place/2346" type="diocese">
                                            <placeName xmlns="http://www.w3.org/1999/xhtml" xmlns="http://www.tei-c.org/ns/1.0" xml:id="name2346-1" xml:lang="en" syriaca-tags="#syriaca-headword" source="#bib2346-1">Mosul</placeName>
                                        </mutual>
                                    </relation>
                                </tei:related-places>
    ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:relation" mode="related-place">
        <xsl:variable name="name-string">
            <xsl:choose>
                <!-- Differentiates between resided and other name attributes -->
                <xsl:when test="@name='resided'">
                    <xsl:value-of select="@name"/> in 
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="replace(@name,'-',' ')"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="currentPlace" select="//t:div[@id='heading']/t:placeName[1]/text()"/>
        <xsl:choose>
            <xsl:when test="@id=concat('#place-',$resource-id)"/>
            <xsl:when test="@varient='active'">
                <li>
                    <a href="{concat('/place/',@id,'.html')}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@varient='passive'">
                <li>
                    <xsl:value-of select="$currentPlace"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$name-string"/>
                    <xsl:text> </xsl:text>
                    <a href="{concat('/place/',@id,'.html')}">
                        <xsl:value-of select="t:placeName"/>
                    </a>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="local:do-dates(.)"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs(@source,@xml:lang)"/>
                    </xsl:if>
                </li>
            </xsl:when>
            <xsl:when test="@varient='mutual'">
                <li>
                    <!--                    <xsl:value-of select="$currentPlace"/> -->
                    <!-- Need to test number of groups and output only the first two -->
                    <xsl:variable name="group1-count">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:if test="position()=1">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:variable>
                    <xsl:variable name="group2-count">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:if test="position()=2">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                            </xsl:if>
                        </xsl:for-each-group>
                    </xsl:variable>
                    <xsl:variable name="total-count" select="count(t:mutual/child::*)"/>
                    <xsl:for-each-group select="t:mutual" group-by="@type">
                        <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                        <xsl:variable name="plural-type">
                            <xsl:choose>
                                <xsl:when test="current-grouping-key() = 'building'">Buildings</xsl:when>
                                <xsl:when test="current-grouping-key() = 'church'">Churches</xsl:when>
                                <xsl:when test="current-grouping-key() = 'diocese'">Dioceses</xsl:when>
                                <xsl:when test="current-grouping-key() = 'fortification'">Fortifications</xsl:when>
                                <xsl:when test="current-grouping-key() = 'island'">Islands</xsl:when>
                                <xsl:when test="current-grouping-key() = 'madrasa'">Madrasas</xsl:when>
                                <xsl:when test="current-grouping-key() = 'monastery'">Monasteries</xsl:when>
                                <xsl:when test="current-grouping-key() = 'mosque'">Mosques</xsl:when>
                                <xsl:when test="current-grouping-key() = 'mountain'">Mountains</xsl:when>
                                <xsl:when test="current-grouping-key() = 'open-water'">Bodies of open-water</xsl:when>
                                <xsl:when test="current-grouping-key() = 'parish'">Parishes</xsl:when>
                                <xsl:when test="current-grouping-key() = 'province'">Provinces</xsl:when>
                                <xsl:when test="current-grouping-key() = 'quarter'">Quarters</xsl:when>
                                <xsl:when test="current-grouping-key() = 'region'">Regions</xsl:when>
                                <xsl:when test="current-grouping-key() = 'river'">Rivers</xsl:when>
                                <xsl:when test="current-grouping-key() = 'settlement'">Settlements</xsl:when>
                                <xsl:when test="current-grouping-key() = 'state'">States</xsl:when>
                                <xsl:when test="current-grouping-key() = 'synagogue'">Synagogues</xsl:when>
                                <xsl:when test="current-grouping-key() = 'temple'">Temples</xsl:when>
                                <xsl:when test="current-grouping-key() = 'unknown'">Unknown</xsl:when>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:variable name="type" select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                        <xsl:choose>
                            <xsl:when test="position()=1">
                                <xsl:value-of select="count(current-group()/child::*)"/>
                                <xsl:text> </xsl:text>
                                <xsl:choose>
                                    <xsl:when test="count(current-group()/child::*) &gt; 1">
                                        <xsl:value-of select="$plural-type"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$type"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                                <xsl:text> </xsl:text>
                            </xsl:when>
                            <xsl:when test="position() = 2">
                                <xsl:choose>
                                    <xsl:when test="last() &gt; 2">, </xsl:when>
                                    <xsl:when test="last() = 2"> and </xsl:when>
                                </xsl:choose>
                                <xsl:value-of select="count(current-group()/child::*)"/>
                                <xsl:text> </xsl:text>
                                <xsl:choose>
                                    <xsl:when test="count(current-group()/child::*) &gt; 1">
                                        <xsl:value-of select="$plural-type"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:value-of select="$type"/>
                                    </xsl:otherwise>
                                </xsl:choose>,
                                <!-- Need to count remaining items, this is not correct just place holder -->
                                <xsl:if test="last() &gt; 2"> and 
                                    <xsl:value-of select="$total-count - ($group1-count + $group2-count)"/> 
                                    other places, 
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise/>
                        </xsl:choose>
                    </xsl:for-each-group>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="replace(child::*[1]/@name,'-',' ')"/>
                    with '<xsl:value-of select="$currentPlace"/>'
                    
                    <xsl:value-of select="local:do-dates(child::*[1])"/>
                    <xsl:text> </xsl:text>
                    <!-- If footnotes exist call function do-refs pass footnotes and language variables to function -->
                    <xsl:if test="child::*[1]/@source">
                        <xsl:sequence select="local:do-refs(child::*[1]/@source,@xml:lang)"/>
                    </xsl:if>
                    <!-- toggle to full list, grouped by type -->
                    <a class="togglelink btn-link" data-toggle="collapse" data-target="#relatedlist" data-text-swap="(hide list)">(see list)</a>
                    <dl class="collapse" id="relatedlist">
                        <xsl:for-each-group select="t:mutual" group-by="@type">
                            <xsl:sort select="count(current-group()/child::*)" order="descending"/>
                            <xsl:variable name="plural-type">
                                <xsl:choose>
                                    <xsl:when test="current-grouping-key() = 'building'">Buildings</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'church'">Churches</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'diocese'">Dioceses</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'fortification'">Fortifications</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'island'">Islands</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'madrasa'">Madrasas</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'monastery'">Monasteries</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'mosque'">Mosques</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'mountain'">Mountains</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'open-water'">Bodies of open-water</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'parish'">Parishes</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'province'">Provinces</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'quarter'">Quarters</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'region'">Regions</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'river'">Rivers</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'settlement'">Settlements</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'state'">States</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'synagogue'">Synagogues</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'temple'">Temples</xsl:when>
                                    <xsl:when test="current-grouping-key() = 'unknown'">Unknown</xsl:when>
                                </xsl:choose>
                            </xsl:variable>
                            <dt>
                                <xsl:value-of select="$plural-type"/>
                            </dt>
                            <xsl:for-each select="current-group()">
                                <dd>
                                    <a href="{concat('/place/',@id,'.html')}">
                                        <xsl:value-of select="t:placeName"/>
                                        <xsl:value-of select="concat(' (',string(@type),', place/',@id,')')"/>
                                    </a>
                                </dd>
                            </xsl:for-each>
                        </xsl:for-each-group>
                    </dl>
                </li>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:relation" mode="relation">
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
</xsl:stylesheet>