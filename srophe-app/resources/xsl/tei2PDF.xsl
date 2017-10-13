<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:s="http://syriaca.org" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t s saxon" version="2.0">

 <!-- ================================================================== 
       Copyright 2015 Vanderbilt University
       
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
       tei2PDF.xsl
       
       This XSLT transforms tei.xml to PDF.
       
       code by: 
        + Winona Salesky (wsalesky@gmail.com)
          for use with eXist-db
          
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
    <xsl:import href="collations.xsl"/>
    <!--
    <xsl:import href="citation-pdf.xsl"/>
    <xsl:import href="bibliography-pdf.xsl"/>
    <xsl:import href="collations.xsl"/>
    -->
 <!-- NOTE: would like to elimnate all these extra xslts
    <xsl:import href="helper-functions.xsl"/>
    <xsl:import href="link-icons.xsl"/>
    <xsl:import href="manuscripts.xsl"/>
    <xsl:import href="citation.xsl"/>
    <xsl:import href="bibliography.xsl"/>
    <xsl:import href="json-uri.xsl"/>
    <xsl:import href="langattr.xsl"/>
    <xsl:import href="collations.xsl"/>
   --> 
 <!-- =================================================================== -->
 <!-- set output so we get (mostly) indented HTML -->
 <!-- =================================================================== -->
    <xsl:output name="xml" encoding="UTF-8" indent="yes"/>
   <!-- Local functions-->
    <xsl:function name="local:do-refs-pdf" as="node()">
        <xsl:param name="refs"/>
        <xsl:param name="lang"/>
        <fo:inline>
            <xsl:text> </xsl:text>
            <xsl:for-each select="tokenize($refs,' ')">
                <fo:bidi-override unicode-bidi="bidi-override" direction="ltr" xml:lang="en" xsl:use-attribute-sets="refs">
                    <fo:basic-link xsl:use-attribute-sets="href" internal-destination="url('{.}')">
                        <xsl:value-of select="substring-after(.,'-')"/>
                    </fo:basic-link>
                    <xsl:if test="position() != last()">,<xsl:text> </xsl:text>
                    </xsl:if>
                </fo:bidi-override>
            </xsl:for-each>
            <xsl:text> </xsl:text>
        </fo:inline>
    </xsl:function>
    
 <!-- =================================================================== -->
 <!-- Global styles for PDF  -->
 <!-- =================================================================== -->
    <xsl:attribute-set name="h1">
        <xsl:attribute name="font-size">18pt</xsl:attribute>
        <xsl:attribute name="font-weight">600</xsl:attribute>
        <xsl:attribute name="color">#666666</xsl:attribute>
        <xsl:attribute name="padding-top">12pt</xsl:attribute>
        <xsl:attribute name="margin-top">12pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">12pt</xsl:attribute>
        <xsl:attribute name="text-indent">8pt</xsl:attribute>
        <xsl:attribute name="border-bottom">1pt dotted #666666</xsl:attribute>
        <xsl:attribute name="border-top">2pt solid #333</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h2">
        <xsl:attribute name="margin-top">14pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">8pt</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
        <xsl:attribute name="font-weight">600</xsl:attribute>
        <xsl:attribute name="color">#666666</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h3">
        <xsl:attribute name="font-size">12pt</xsl:attribute>
        <xsl:attribute name="font-weight">700</xsl:attribute>
<!--
        <xsl:attribute name="margin-top">12pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">4pt</xsl:attribute>
        <xsl:attribute name="padding-bottom">0</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
        <xsl:attribute name="border-bottom">1pt solid #333</xsl:attribute>
        <xsl:attribute name="color">#333333</xsl:attribute>
    -->    
        <!--<xsl:attribute name="border-top">4pt solid #333</xsl:attribute>-->
        <!--<xsl:attribute name="border-bottom">1pt dotted #333</xsl:attribute>-->
        <xsl:attribute name="border-bottom">1pt solid #333</xsl:attribute>
        <xsl:attribute name="margin-bottom">12pt</xsl:attribute>
        <xsl:attribute name="margin-top">12pt</xsl:attribute>
        <xsl:attribute name="padding-top">8pt</xsl:attribute>
        <xsl:attribute name="padding-bottom">8pt</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="h4">
        <xsl:attribute name="font-size">10pt</xsl:attribute>
        <xsl:attribute name="font-weight">700</xsl:attribute>
        <xsl:attribute name="margin-top">8pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">4pt</xsl:attribute>
        <xsl:attribute name="padding-bottom">0</xsl:attribute>
        <xsl:attribute name="keep-with-next.within-page">always</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="font-small">
        <xsl:attribute name="font-size">9pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="indent">
        <xsl:attribute name="margin-left">12pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="grey">
        <xsl:attribute name="color">#999999</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="href">
        <xsl:attribute name="color">blue</xsl:attribute>
        <xsl:attribute name="text-decoration">underline</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="bold">
        <xsl:attribute name="font-weight">600</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="label">
        <xsl:attribute name="font-weight">600</xsl:attribute>
        <xsl:attribute name="color">#999999</xsl:attribute>
        <xsl:attribute name="margin-right">8pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="caveat">
        <xsl:attribute name="font-size">10pt</xsl:attribute>
        <xsl:attribute name="font-style">italic</xsl:attribute>
        <!--<xsl:attribute name="color">grey</xsl:attribute>-->
        <xsl:attribute name="margin-top">4pt</xsl:attribute>
        <xsl:attribute name="margin-left">8pt</xsl:attribute>
        <xsl:attribute name="margin-right">8pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">4pt</xsl:attribute>
    </xsl:attribute-set>
    <!-- NOT sure if this is used -->
    <xsl:attribute-set name="list-block">
        <xsl:attribute name="provisional-distance-between-starts">12pt</xsl:attribute>
        <xsl:attribute name="provisional-label-separation">3pt</xsl:attribute>
        <xsl:attribute name="margin-left">12pt</xsl:attribute>
    </xsl:attribute-set>
    <!-- Not effective -->
    <xsl:attribute-set name="list-item">
        <xsl:attribute name="margin-top">0pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">-4pt</xsl:attribute>
        <xsl:attribute name="space-before">0pt</xsl:attribute>
        <xsl:attribute name="space-after">0pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="list-item-padding">
        <xsl:attribute name="margin-top">4pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="inline-list-item">
        <xsl:attribute name="margin">4pt</xsl:attribute>
        <xsl:attribute name="padding">1pt</xsl:attribute>
        <xsl:attribute name="background-color">#F2F2F2</xsl:attribute>
        <xsl:attribute name="border">1pt solid #ccc</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="bullet">
        <xsl:attribute name="font-size">14pt</xsl:attribute>
        <xsl:attribute name="margin-top">4pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="def-list">
        <xsl:attribute name="margin-left">12pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="def-list">
        <xsl:attribute name="margin-top">18pt</xsl:attribute>
        <xsl:attribute name="margin-right">18pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">18pt</xsl:attribute>
        <xsl:attribute name="margin-left">18pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="blockquote">
        <xsl:attribute name="border-left">4pt solid #999999</xsl:attribute>
        <xsl:attribute name="padding-left">8pt</xsl:attribute>
        <xsl:attribute name="margin">12pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="refs">
        <xsl:attribute name="font-size">9pt</xsl:attribute>
        <xsl:attribute name="vertical-align">super</xsl:attribute>
        <xsl:attribute name="font-weight">normal</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="well">
        <xsl:attribute name="margin">8pt</xsl:attribute>
        <xsl:attribute name="padding">8pt</xsl:attribute>
        <xsl:attribute name="border">solid 0.5pt #cccccc</xsl:attribute>
        <xsl:attribute name="background-color">#F2F2F2</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="section">
        <xsl:attribute name="margin-top">12pt</xsl:attribute>
        <xsl:attribute name="margin-right">8pt</xsl:attribute>
        <xsl:attribute name="margin-bottom">8pt</xsl:attribute>
        <xsl:attribute name="margin-left">8pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="outline">
        <xsl:attribute name="margin">12pt</xsl:attribute>
        <xsl:attribute name="padding">8pt</xsl:attribute>
        <xsl:attribute name="border">solid 0.5pt #cccccc</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="smp">
        <xsl:attribute name="margin">4pt</xsl:attribute>
        <xsl:attribute name="padding">4pt</xsl:attribute>
    </xsl:attribute-set>
    <!-- NOTE: will need work once xslt is working -->
    <xsl:attribute-set name="p">
        <xsl:attribute name="margin">8pt</xsl:attribute>
        <xsl:attribute name="font-weight">normal</xsl:attribute>
    </xsl:attribute-set>
    <!-- To use the embedded fonts include a fop-config file with references to fonts see /modules/pdf.xql -->
    <xsl:attribute-set name="syr">
        <xsl:attribute name="font-family">EstrangeloEdessa</xsl:attribute>
        <!-- <xsl:attribute name="writing-mode">rl-tb</xsl:attribute>-->
        <xsl:attribute name="xml:lang">syr</xsl:attribute>
        <xsl:attribute name="direction">rtl</xsl:attribute>
        <!--<xsl:attribute name="unicode-bidi">embed</xsl:attribute>-->
        <!--<xsl:attribute name="language">syr</xsl:attribute>-->
        <xsl:attribute name="font-size">14pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="syr-Syrj">
        <xsl:attribute name="font-family">SertoBatnan</xsl:attribute>
        <xsl:attribute name="xml:lang">syr-Syrj</xsl:attribute>
        <xsl:attribute name="direction">rtl</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="syc-Syre">
        <xsl:attribute name="font-family">EastSyriacAdiabene</xsl:attribute>
        <xsl:attribute name="xml:lang">syc-Syre</xsl:attribute>
        <xsl:attribute name="direction">rtl</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="syr-Syrn">
        <xsl:attribute name="font-family">EastSyriacAdiabene</xsl:attribute>
        <xsl:attribute name="xml:lang">syc-Syre</xsl:attribute>
        <xsl:attribute name="direction">rtl</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
    </xsl:attribute-set>
    <xsl:attribute-set name="ar">
        <xsl:attribute name="xml:lang">ar</xsl:attribute>
        <xsl:attribute name="direction">rtl</xsl:attribute>
        <xsl:attribute name="font-size">14pt</xsl:attribute>
    </xsl:attribute-set>
    
    <!-- To handle dynamic lang attributes -->
    <xsl:template name="langattr">
        <xsl:variable name="lang">
            <xsl:choose>
                <xsl:when test="@xml:lang">
                    <xsl:value-of select="@xml:lang"/>
                </xsl:when>
                <xsl:when test="parent::*/@xml:lang">
                    <xsl:value-of select="parent::*/@xml:lang"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$lang !=''">
            <xsl:choose>
                <xsl:when test="$lang = 'syr'">
                    <xsl:attribute name="font-family">EstrangeloEdessa</xsl:attribute>
                    <xsl:attribute name="direction">rtl</xsl:attribute>
                    <xsl:attribute name="font-size">14pt</xsl:attribute>
                </xsl:when>
                <xsl:when test="$lang = 'syr-Syrj'">
                    <xsl:attribute name="font-family">SertoBatnan</xsl:attribute>
                    <xsl:attribute name="direction">rtl</xsl:attribute>
                    <xsl:attribute name="font-size">14pt</xsl:attribute>
                </xsl:when>
                <xsl:when test="$lang = 'syr-Syre' or $lang = 'syr-Syrn'">
                    <xsl:attribute name="font-family">EastSyriacAdiabene</xsl:attribute>
                    <xsl:attribute name="direction">rtl</xsl:attribute>
                    <xsl:attribute name="font-size">14pt</xsl:attribute>
                </xsl:when>
                <xsl:when test="$lang = 'ar'">
                    <xsl:attribute name="direction">rtl</xsl:attribute>
                    <xsl:attribute name="font-size">14pt</xsl:attribute>
                </xsl:when>
            </xsl:choose>
        </xsl:if>
        <xsl:copy-of select="@xml:lang"/>
    </xsl:template>
 
 <!-- =================================================================== -->
 <!--  initialize top-level variables and transform parameters -->
 <!--  sourcedir: where to look for XML files to summarize/link to -->
 <!--  description: a meta description for the HTML page we will output -->
 <!--  name-app: name of the application (for use in head/title) -->
 <!--  name-page-short: short name of the page (for use in head/title) -->
 <!--  colquery: constructed variable with query for collection fn. -->
 <!-- =================================================================== -->
    
    <!-- Parameters passed from app.xql default values if params are empty -->
    <!-- Parameters passed from global.xqm (set in config.xml) default values if params are empty -->
    <!-- eXist data app root for gazetteer data -->
    <xsl:param name="mode" select="'#all'"/>
    <xsl:param name="data-root" select="'/db/apps/srophe-data'"/>
    <!-- eXist app root for app deployment-->
    <xsl:param name="app-root" select="'/db/apps/srophe'"/>
    <!-- Root of app for building dynamic links. Default is eXist app root -->
    <xsl:param name="nav-base" select="'/db/apps/srophe'"/>
    <!-- Base URI for identifiers in app data -->
    <xsl:param name="base-uri" select="'/db/apps/srophe'"/>
    <!-- Hard coded values-->
    <xsl:param name="normalization">NFKC</xsl:param>
    <xsl:param name="editoruriprefix">http://syriaca.org/documentation/editors.xml#</xsl:param>
    <xsl:variable name="editorssourcedoc" select="concat('xmldb:exist://',$app-root,'/documentation/editors.xml')"/>
    <xsl:variable name="resource-id">
        <xsl:choose>
            <xsl:when test="string(/*/@id)">
                <xsl:value-of select="string(/*/@id)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="starts-with(//idno[@type='URI'],'http://syriaca.org/')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    
 <!-- =================================================================== -->
 <!-- TEMPLATES -->
 <!-- =================================================================== -->

 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
 <!-- |||| Root template matches tei root 
 <fo:flow flow-name="xsl-region-body" font-family="Arial Unicode MS" font-size="10pt" color="#333333">
 -->
 <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="/">
        <fo:root>
            <fo:layout-master-set>
                <fo:simple-page-master master-name="contents" page-width="8.5in" page-height="11in" margin-top="0.25in" margin-bottom="0.5in" margin-left="0.5in" margin-right="0.5in">
                    <fo:region-body margin="0.5in" margin-bottom="1in"/>
                    <fo:region-before extent="0.75in"/>
                    <fo:region-after extent="0.2in"/>
                </fo:simple-page-master>
            </fo:layout-master-set>
            <fo:page-sequence master-reference="contents">
                <fo:static-content flow-name="xsl-region-after">
                    <fo:block border-top-style="solid" border-top-color="#666666" border-top-width=".015in" padding-top=".025in" margin-bottom="0in" padding-after="0in" padding-bottom="0">
                        <fo:block color="gray" padding-top="0in" margin-top="-0.015in" border-top-style="solid" border-top-color="#gray" border-top-width=".01in" xsl:use-attribute-sets="font-small">
                            <fo:block margin-top="4pt">
                                <fo:block text-align="center">Copyright Vanderbilt University, Princeton University, and the Contributor(s), 2014.</fo:block>
                                <fo:block text-align="center">
                                    <xsl:text> Page </xsl:text>
                                    <fo:page-number/>
                                </fo:block>
                            </fo:block>
                        </fo:block>
                    </fo:block>
                </fo:static-content>
                <fo:flow flow-name="xsl-region-body" font-family="Arial" font-size="10pt" color="#333333">
                    <fo:block>
                        <xsl:apply-templates/>
                    </fo:block>
                </fo:flow>
            </fo:page-sequence>
        </fo:root>
    </xsl:template>
    
    <!-- Syriaca.org branding -->
    <!-- NOTE: need to work out path for this, not currently working -->
    <xsl:template name="titleIcon">
        <fo:external-graphic src="url('http://syriaca.org/resources/img/syriaca-logo.png')"/>
    </xsl:template>
    <xsl:template match="t:TEI">
        <fo:block text-align="right" margin-bottom="24pt" padding="0pt" padding-bottom="4pt">
            <xsl:call-template name="titleIcon"/>
        </fo:block>
        <!-- Header -->
        <xsl:apply-templates select="t:teiHeader/t:fileDesc/t:titleStmt"/>
        
        <!-- Body -->
        <xsl:apply-templates select="t:text/t:body/child::*"/>
       
        <!-- Sources -->
        <xsl:if test="t:text/t:body/child::*/child::*/t:bibl">
            <xsl:call-template name="sources">
                <xsl:with-param name="node" select="t:text/t:body/child::*/child::*"/>
            </xsl:call-template>
        </xsl:if>
        
        <!-- Citation Information -->        
        <!-- Citations -->
        <xsl:call-template name="citationInfo"/>
    </xsl:template>
    
    <!-- Handle Titles -->
    <xsl:template match="t:titleStmt">
        <xsl:call-template name="h1"/>
    </xsl:template>
    <xsl:template match="t:title">
        <xsl:apply-templates/>
        <xsl:if test="following-sibling::t:title">
            <xsl:text>: </xsl:text>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:foreign">
        <xsl:choose>
            <xsl:when test="starts-with(@xml:lang,'syr')">
                <fo:bidi-override unicode-bidi="bidi-override" xsl:use-attribute-sets="syr">
                    <xsl:value-of select="."/>
                </fo:bidi-override>
            </xsl:when>
            <xsl:when test="starts-with(@xml:lang,'ar')">
                <fo:bidi-override unicode-bidi="bidi-override" xsl:use-attribute-sets="ar">
                    <xsl:value-of select="."/>
                </fo:bidi-override>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template name="h1">
       <!-- <fo:block><xsl:call-template name="titleIcon"/></fo:block>-->
        <!-- NOTE: Will need to work module icons into headings... -->
        <fo:block xsl:use-attribute-sets="h1">
            <xsl:choose>
                <xsl:when test="/t:TEI/descendant::*[@syriaca-tags='#syriaca-headword']">
                    <xsl:apply-templates select="/t:TEI/descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'en')][1]" mode="plain"/>
                    <xsl:text> - </xsl:text>
                    <xsl:choose>
                        <xsl:when test="/t:TEI/descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'syr')]">
                            <fo:bidi-override unicode-bidi="bidi-override" xsl:use-attribute-sets="syr">
                                <xsl:apply-templates select="/t:TEI/descendant::*[@syriaca-tags='#syriaca-headword'][starts-with(@xml:lang,'syr')][1]" mode="plain"/>
                            </fo:bidi-override>
                        </xsl:when>
                        <xsl:otherwise>
                            <fo:block>[ Syriac Not Available ]</fo:block>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:if test="//t:person[@ana] or //t:birth or //t:death">
                        (
                        <xsl:for-each select="tokenize(//t:person/@ana,' ')">
                            <xsl:value-of select="substring-after(.,'#syriaca-')"/>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
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
                        </xsl:if>
                        )
                    </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:title"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:block>
        <!-- emit record URI and associated help links -->
        <xsl:for-each select="//t:body/child::*/child::*/t:idno[contains(.,'syriaca.org')][@type='URI'][1]">
            <fo:block xsl:use-attribute-sets="font-small indent">
                <fo:inline xsl:use-attribute-sets="label">URI</fo:inline>
                <fo:inline xsl:use-attribute-sets="grey">
                    <xsl:text>: </xsl:text>
                    <xsl:value-of select="."/>
                </fo:inline>
            </fo:block>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:place">
        <fo:block xsl:use-attribute-sets="section">
            <!-- Description -->
            <xsl:if test="t:desc[starts-with(@xml:id,'abstract')]">
                <fo:block xsl:use-attribute-sets="blockquote">
                    <xsl:apply-templates select="t:desc[starts-with(@xml:id,'abstract')]"/>
                </fo:block>
            </xsl:if>
            <fo:table table-layout="fixed" width="100%" margin-top="24pt">
                <fo:table-column column-width="3in"/>
                <fo:table-column column-width="4in"/>
                <fo:table-body>
                    <fo:table-row>
                        <fo:table-cell>
                            <!-- Names -->
                            <fo:block xsl:use-attribute-sets="bold">Names</fo:block>
                            <fo:list-block xsl:use-attribute-sets="indent">
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
                            </fo:list-block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block xsl:use-attribute-sets="p">
                                <fo:inline xsl:use-attribute-sets="bold">Place Type: </fo:inline>
                                <xsl:value-of select="@type"/>
                            </fo:block>
                            <xsl:if test="t:location">
                                <fo:block xsl:use-attribute-sets="p">
                                    <fo:inline xsl:use-attribute-sets="bold">Location: </fo:inline>
                                </fo:block>
                                <fo:block xsl:use-attribute-sets="indent p">
                                    <xsl:apply-templates select="t:location"/>
                                </fo:block>
                            </xsl:if>
                        </fo:table-cell>
                    </fo:table-row>
                </fo:table-body>
            </fo:table>
            
            <!-- Descriptions -->
            <xsl:if test="string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &gt; 1">
                <fo:block xsl:use-attribute-sets="h3">Brief Descriptions</fo:block>
                <xsl:for-each-group select="t:desc[not(starts-with(@xml:id,'abstract'))]" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                    <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                    <xsl:for-each select="current-group()">
                        <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                        <xsl:apply-templates select="." mode="p"/>
                    </xsl:for-each>
                </xsl:for-each-group>
            </xsl:if> 
           
            <!-- Events -->
            <xsl:if test="t:event[not(@type='attestation')]">
                <fo:block xsl:use-attribute-sets="h3">Event<xsl:if test="count(t:event[not(@type='attestation')]) &gt; 1">s</xsl:if>
                </fo:block>
                <fo:list-block xsl:use-attribute-sets="indent">
                    <xsl:apply-templates select="t:event[not(@type='attestation')]"/>
                </fo:list-block>
            </xsl:if>
            
            <!-- Events/attestation -->
            <xsl:if test="t:event[@type='attestation']">
                <fo:block xsl:use-attribute-sets="h3">Attestation<xsl:if test="count(t:event[@type='attestation']) &gt; 1">s</xsl:if>
                </fo:block>
                <fo:list-block xsl:use-attribute-sets="indent">
                        <!-- Sorts events on dates, checks first for @notBefore and if not present, uses @when -->
                    <xsl:for-each select="t:event[@type='attestation']">
                        <xsl:sort select="if(exists(@notBefore)) then @notBefore else @when"/>
                        <xsl:apply-templates select="."/>
                    </xsl:for-each>
                </fo:list-block>
            </xsl:if>
            
            <!-- Notes -->
            <!-- NOTE: need to handle abstract notes -->
            <xsl:if test="t:note[not(@type='abstract')]">
                <xsl:for-each-group select="t:note[not(@type='abstract')][exists(@type)]" group-by="@type">
                    <fo:block xsl:use-attribute-sets="h3">
                        <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                    </fo:block>
                    <xsl:for-each select="current-group()">
                        <xsl:apply-templates/>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each select="t:note[not(exists(@type))]">
                    <fo:block xsl:use-attribute-sets="h3">Note</fo:block>
                    <xsl:apply-templates/>
                </xsl:for-each>
            </xsl:if>
            
            <!-- Known religious communities -->
        </fo:block>
    </xsl:template>
    <xsl:template match="t:person">
        <fo:block xsl:use-attribute-sets="section">
            <xsl:if test="string-length(t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']) &gt; 1">
                <fo:block xsl:use-attribute-sets="h4">Identity</fo:block>
                <xsl:apply-templates select="t:desc[@type='abstract' or starts-with(@xml:id, 'abstract-en')][1] | t:note[@type='abstract']" mode="abstract"/>
            </xsl:if>
            <fo:block xsl:use-attribute-sets="bold">Names:</fo:block>
            <fo:list-block xsl:use-attribute-sets="indent">
                <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'syr')]" mode="inline-list">
                    <xsl:sort lang="syr" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[@syriaca-tags='#syriaca-headword' and starts-with(@xml:lang,'en')]" mode="inline-list">
                    <xsl:sort collation="{$mixed}" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and starts-with(@xml:lang, 'syr')]" mode="inline-list">
                    <xsl:sort lang="syr" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[starts-with(@xml:lang, 'ar')]" mode="inline-list">
                    <xsl:sort lang="ar" select="."/>
                </xsl:apply-templates>
                <xsl:apply-templates select="t:persName[(not(@syriaca-tags) or @syriaca-tags!='#syriaca-headword') and not(starts-with(@xml:lang, 'syr') or starts-with(@xml:lang, 'ar')) and not(@syriaca-tags='#syriaca-simplified-script')]" mode="inline-list">
                    <xsl:sort collation="{$mixed}" select="."/>
                </xsl:apply-templates>
            </fo:list-block>
            <fo:block>
                <xsl:apply-templates select="t:sex"/>
            </fo:block>
        
            <!-- Description -->
            <xsl:if test="string-length(t:desc[not(starts-with(@xml:id,'abstract'))][1]) &gt; 1">
                <fo:block xsl:use-attribute-sets="h3">Brief Descriptions</fo:block>
                <xsl:for-each-group select="t:desc" group-by="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang">
                    <xsl:sort collation="{$languages}" select="if (contains(@xml:lang, '-')=true()) then substring-before(@xml:lang, '-') else @xml:lang"/>
                    <xsl:for-each select="current-group()">
                        <xsl:sort lang="{current-grouping-key()}" select="normalize-space(.)"/>
                        <xsl:apply-templates select="."/>
                    </xsl:for-each>
                </xsl:for-each-group>
            </xsl:if>    
            <!-- Events -->
            <xsl:if test="t:event">
                <fo:block xsl:use-attribute-sets="h3">Event<xsl:if test="count(t:event) &gt; 1">s</xsl:if>
                </fo:block>
                <fo:list-block xsl:use-attribute-sets="indent">
                    <xsl:apply-templates select="t:event"/>
                </fo:list-block>
            </xsl:if>
            <!-- State -->
            <xsl:for-each-group select="t:state" group-by="@type">
                <fo:block xsl:use-attribute-sets="p">
                    <xsl:for-each select="current-group()[not(t:desc/@xml:lang = 'en-x-gedsh')]">
                        <fo:block>
                            <xsl:apply-templates select="."/>
                        </fo:block>
                    </xsl:for-each>
                </fo:block>
            </xsl:for-each-group>
            <xsl:for-each-group select="t:birth | t:death | t:floruit | t:sex | t:langKnowledge" group-by=".">
                <fo:block xsl:use-attribute-sets="p">
                    <xsl:for-each select="current-group()">
                        <fo:block>
                            <xsl:apply-templates select="."/>
                        </fo:block>
                    </xsl:for-each>
                </fo:block>
            </xsl:for-each-group>
            
            <!-- NOTE: need to handle abstract notes -->
            <xsl:if test="t:note[not(@type='abstract')]">
                <xsl:for-each-group select="t:note[not(@type='abstract')][exists(@type)]" group-by="@type">
                    <fo:block xsl:use-attribute-sets="h3">
                        <xsl:value-of select="concat(upper-case(substring(current-grouping-key(),1,1)),substring(current-grouping-key(),2))"/>
                    </fo:block>
                    <xsl:for-each select="current-group()">
                        <xsl:apply-templates/>
                    </xsl:for-each>
                </xsl:for-each-group>
                <xsl:for-each select="t:note[not(exists(@type))]">
                    <fo:block xsl:use-attribute-sets="h3">Note</fo:block>
                    <xsl:apply-templates/>
                </xsl:for-each>
            </xsl:if>
            <xsl:apply-templates select="parent::t:relation"/>
        </fo:block>
    </xsl:template>
    <xsl:template match="t:event">
        <fo:list-item>
            <fo:list-item-label end-indent="label-end()">
                <fo:block xsl:use-attribute-sets="bullet">•</fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>
                    <xsl:apply-templates select="child::*" mode="plain"/>
                    <!-- Adds dates if available -->
                    <xsl:sequence select="local:do-dates(.)"/>
                    <!-- Adds footnotes if available -->
                    <xsl:if test="@source">
                        <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
                    </xsl:if>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    <xsl:template match="t:event" mode="plain">
        <!-- There are several desc templates, this 'plain' mode ouputs all the child elements with no p or li tags -->
        <xsl:apply-templates select="child::*" mode="plain"/>
        <!-- Adds dates if available -->
        <xsl:sequence select="local:do-dates(.)"/>
        <!-- Adds footnotes if available -->
        <xsl:if test="@source">
            <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
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
    
    <!-- Locations -->
    <xsl:template match="t:location[@type='geopolitical' or @type='relative']">
        <fo:block xsl:use-attribute-sets="indent">
            <xsl:choose>
                <xsl:when test="@subtype='quote'">"<xsl:apply-templates/>"</xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
        </fo:block>
    </xsl:template>
    <xsl:template match="t:location[@type='nested']">
        <fo:block xsl:use-attribute-sets="indent">
            <xsl:text>Within </xsl:text>
            <xsl:for-each select="t:*">
                <xsl:apply-templates select="."/>
                <xsl:if test="following-sibling::t:*">
                    <xsl:text> within </xsl:text>
                </xsl:if>
            </xsl:for-each>
            <xsl:text>.</xsl:text>
            <xsl:sequence select="local:do-refs-pdf(@source,'eng')"/>
        </fo:block>
    </xsl:template>
    <xsl:template match="t:location[@type='gps' and t:geo]">
        <fo:block xsl:use-attribute-sets="indent">
            <xsl:text>Coordinates: </xsl:text>
            <fo:block xsl:use-attribute-sets="indent">
                <xsl:value-of select="concat('Lat. ',tokenize(t:geo,' ')[1],'°')"/>
            </fo:block>
            <fo:block xsl:use-attribute-sets="indent">
                <xsl:value-of select="concat('Long. ',tokenize(t:geo,' ')[2],'°')"/>
            </fo:block>
        </fo:block>
    </xsl:template>
    <xsl:template match="t:offset | t:measure">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="pdf-out-normal"/>
    </xsl:template>

    <!-- Descriptions -->
    <!-- Descriptions without list elements or paragraph elements -->
    <xsl:template match="t:desc">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="t:desc" mode="plain">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="plain"/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="t:label" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!-- Descriptions for place abstract  added template for abstracts, handles quotes and references.-->
    <xsl:template match="t:desc[starts-with(@xml:id, 'abstract-en')]" mode="abstract">
        <fo:block xsl:use-attribute-sets="p">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    <!-- General descriptions within the body of the place element, uses lists -->
    <xsl:template match="t:desc[not(starts-with(@xml:id, 'abstract-en'))]" mode="p">
        <fo:block xsl:use-attribute-sets="p">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    <xsl:template match="t:state | t:birth | t:death | t:floruit | t:sex | t:langKnowledge">
        <fo:inline xsl:use-attribute-sets="label">
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
        </fo:inline>
        <xsl:text> </xsl:text>
        <xsl:apply-templates mode="plain"/>
        <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:state[@type='saint']">
        <fo:inline xsl:use-attribute-sets="label">Saint: </fo:inline>
        <fo:inline>yes</fo:inline>
    </xsl:template>
    <xsl:template match="t:langKnown">
        <xsl:apply-templates/>
        <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    
    <!-- listBibl -->
    <xsl:template match="t:listBibl">
        <fo:list-block xsl:use-attribute-sets="indent">
            <xsl:for-each select="t:bibl">
                <fo:list-item xsl:use-attribute-sets="list-item-padding">
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block xsl:use-attribute-sets="bullet">•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                            <xsl:apply-templates mode="biblist"/>
                            <xsl:text>.</xsl:text>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:for-each>
        </fo:list-block>
    </xsl:template>

    <!-- note elements -->
    <xsl:template match="t:note">
        <xsl:variable name="xmlid" select="@xml:id"/>
        <xsl:choose>
            <!-- Adds definition list for depreciated names -->
            <xsl:when test="@type='deprecation'">
                <fo:block xsl:use-attribute-sets="p">
                    <xsl:apply-templates select="../t:link[contains(@target,$xmlid)]"/>:
                    <xsl:apply-templates/>
                    <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </fo:block>
            </xsl:when>
            <xsl:when test="@type='corrigenda' or @type='incerta' or @type ='errata'">
                <fo:block xsl:use-attribute-sets="p">
                    <xsl:apply-templates/>
                </fo:block>
            </xsl:when>
            <xsl:otherwise>
                <fo:block xsl:use-attribute-sets="p">
                    <xsl:apply-templates/>
                    <!-- Check for ending punctuation, if none, add . -->
                    <xsl:if test="not(ends-with(.,'.'))">
                        <xsl:text>.</xsl:text>
                    </xsl:if>
                </fo:block>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:note" mode="abstract">
        <fo:block xsl:use-attribute-sets="p">
            <xsl:apply-templates/>
        </fo:block>
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
    
    <!-- p elements -->
    <xsl:template match="t:p" mode="plain">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="t:p">
        <fo:block xsl:use-attribute-sets="p">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>
    
    <!-- NOTE: need to untangle bid direction and langattr for fo -->
    <xsl:template match="t:quote">
        <xsl:choose>
            <xsl:when test="@xml:lang">
                <xsl:text>“</xsl:text>
                <fo:bidi-override unicode-bidi="bidi-override">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </fo:bidi-override>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <xsl:when test="parent::t:desc/@xml:lang">
                <xsl:text>“</xsl:text>
                <fo:bidi-override unicode-bidi="bidi-override">
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates/>
                </fo:bidi-override>
                <xsl:text>”</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>“</xsl:text>
                <xsl:apply-templates/>
                <xsl:text>”</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
    </xsl:template>
    <xsl:template match="t:persName | t:region | t:settlement | t:placeName">
        <xsl:choose>
            <xsl:when test="@ref">
                <xsl:choose>
                    <xsl:when test="string-length(@ref) &lt; 1"/>
                    <xsl:otherwise>
                        <xsl:text> </xsl:text>
                        <fo:basic-link xsl:use-attribute-sets="href" external-destination="url('{@ref}')">
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates mode="cleanout"/>
                        </fo:basic-link>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline>
                    <xsl:call-template name="langattr"/>
                    <xsl:apply-templates mode="cleanout"/>
                    <xsl:sequence select="local:do-refs-pdf(@source,@xml:lang)"/>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="title">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="text-normal"/>
        </fo:inline>
    </xsl:template>
    <xsl:template match="t:persName" mode="inline-list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <fo:list-item xsl:use-attribute-sets="list-item">
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block xsl:use-attribute-sets="bullet">•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                <!--<fo:block xsl:use-attribute-sets="inline-list-item">-->
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates/>
                            <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
                <!--</fo:block>-->
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:persName" mode="plain">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="t:roleName">
        <xsl:apply-templates mode="pdf-out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename | t:addName">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="pdf-out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:roleName" mode="text-normal">
        <xsl:apply-templates mode="pdf-out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:forename | t:addName" mode="text-normal">
        <xsl:if test="preceding-sibling::*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="pdf-out-normal"/>
        <xsl:text> </xsl:text>
    </xsl:template>
    <xsl:template match="t:placeName" mode="list">
        <xsl:variable name="nameID" select="concat('#',@xml:id)"/>
        <xsl:choose>
            <!-- Suppress depreciated names here -->
            <xsl:when test="/descendant-or-self::t:link[substring-before(@target,' ') = $nameID][contains(@target,'deprecation')]"/>
            <!-- Output all other names -->
            <xsl:otherwise>
                <fo:list-item xsl:use-attribute-sets="list-item">
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block xsl:use-attribute-sets="bullet">•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                            <xsl:call-template name="langattr"/>
                            <xsl:apply-templates select="." mode="pdf-out-normal"/>
                            <xsl:sequence select="local:do-refs-pdf(@source,ancestor::t:*[@xml:lang][1])"/>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:list">
        <fo:list-block xsl:use-attribute-sets="indent">
            <xsl:apply-templates/>
        </fo:list-block>
    </xsl:template>
    <xsl:template match="t:item">
        <fo:list-item xsl:use-attribute-sets="list-item">
            <fo:list-item-label end-indent="label-end()">
                <fo:block xsl:use-attribute-sets="bullet">•</fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>
                    <xsl:apply-templates/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <!-- handle standard output of the licence element in the tei header -->
    <xsl:template match="t:licence">
        <xsl:if test="@target">
            <fo:basic-link xsl:use-attribute-sets="href" external-destination="url('{@target}')">
                <fo:external-graphic src="url('http://syriaca.org/resources/img/cc.png')"/>
            </fo:basic-link>
        </xsl:if>
        <xsl:apply-templates/>
    </xsl:template>
    
    <!--  handle standard output of the ref element -->
    <xsl:template match="t:ref">
        <fo:basic-link xsl:use-attribute-sets="href" external-destination="url('{@target}')">
            <xsl:apply-templates/>
        </fo:basic-link>
    </xsl:template>
        
    <!-- Sources -->
    <xsl:template name="sources">
        <xsl:param name="node"/>
            <!-- Sources -->
        <fo:block xsl:use-attribute-sets="h3">Sources</fo:block>
        <fo:block xsl:use-attribute-sets="p">
            <fo:block xsl:use-attribute-sets="caveat">Any information without attribution has been created following the Syriaca.org 
                    <fo:basic-link xsl:use-attribute-sets="href" external-destination="url('http://syriaca.org/documentation/')">editorial guidelines</fo:basic-link>.
                </fo:block>
        </fo:block>
        <fo:list-block>
                <!-- Bibliography elements are processed by bibliography.xsl -->
            <xsl:apply-templates select="$node/t:bibl" mode="footnote"/>
        </fo:list-block>
    </xsl:template>
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a footnote for the matched bibl entry; if it contains a 
     pointer, try to look up the master bibliography file and use that
     
     assumption: you want the footnote in a list item (li) element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="footnote">
        <xsl:param name="footnote-number">-1</xsl:param>
        <xsl:variable name="thisnum">
            <!-- Isolates footnote number in @xml:id-->
            <xsl:choose>
                <xsl:when test="$footnote-number='-1'">
                    <xsl:value-of select="substring-after(@xml:id, '-')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$footnote-number"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <fo:list-item id="{@xml:id}">
            <fo:list-item-label end-indent="label-end()">
                <fo:block>
                    <xsl:value-of select="$thisnum"/>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body start-indent="body-start()">
                <fo:block>
                    <!-- if there is an analytic title present, then we have a separately titled book section -->
                    <xsl:if test="t:title[@level='a']">
                        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                        <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',2)"/>
                        <xsl:if test="t:author">
                            <xsl:text>, </xsl:text>
                        </xsl:if>
                        <xsl:text>“</xsl:text>
                        <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
                        <xsl:text>” in </xsl:text>
                    </xsl:if>
                    <!-- if the reference points at a master bibliographic record file, use it; otherwise, do 
                what you can with the contents of the present element -->
                    <xsl:choose>
                        <xsl:when test="t:ptr[@target and starts-with(@target, 'http://syriaca.org/bibl/')]">
                            <!-- Find file path for bibliographic record -->
                            <xsl:variable name="biblfilepath">
                                <xsl:value-of select="concat('/db/apps/srophe-data/data/bibl/tei/',substring-after(t:ptr/@target, 'http://syriaca.org/bibl/'),'.xml')"/>
                            </xsl:variable>
                            <!-- Check if record exists in db with doc-available function -->
                            <xsl:if test="doc-available($biblfilepath)">
                                <!-- Process record as a footnote -->
                                <xsl:apply-templates select="document($biblfilepath)/t:TEI/t:text/t:body/t:biblStruct" mode="footnote"/>
                            </xsl:if>
                            <!-- Process all citedRange elements as footnotes -->
                            <xsl:if test="t:citedRange">
                                <xsl:for-each select="t:citedRange">
                                    <xsl:text>, </xsl:text>
                                    <xsl:apply-templates select="." mode="footnote"/>
                                </xsl:for-each>
                            </xsl:if>
                            <xsl:text>.</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a footnote for a book
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct[t:monogr]" mode="footnote">
        <!-- this is a monograph/book -->
        <!-- handle editors/authors and abbreviate as necessary -->
        <xsl:variable name="edited" select="if (t:monogr/t:editor[not(@role) or @role!='translator']) then true() else false()"/>
        <!-- count editors/authors  -->
        <xsl:variable name="rcount">
            <xsl:choose>
                <xsl:when test="$edited">
                    <xsl:value-of select="count(t:monogr/t:editor[not(@role) or @role!='translator'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="count(t:monogr/t:author)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:choose>
            <xsl:when test="$edited">
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:editor[not(@role) or @role!='translator'],'footnote',2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:author,'footnote',2)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$edited">
            <xsl:choose>
                <xsl:when test="$rcount = 1">
                    <xsl:text> (ed.)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> (eds.)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:text>, </xsl:text>
        
        <!-- handle titles -->
        <xsl:for-each select="t:monogr[1]">
            <xsl:choose>
                <xsl:when test="t:title[@xml:lang='en']">
                    <xsl:apply-templates select="t:title[@xml:lang='en']" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:title[1]" mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        
        <!-- handle translator, if present -->
        <xsl:if test="count(t:monogr[1]/t:editor[@role='translator']) &gt; 0">
            <xsl:text>, trans. </xsl:text>
            <!-- Process translator using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons(t:monogr[1]/t:editor[@role='translator'],'footnote',2)"/>
        </xsl:if>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="t:monogr/t:imprint" mode="footnote"/>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a bibllist entry for a book
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct[t:monogr and not(t:analytic)]" mode="biblist">
        <!-- this is a monograph/book -->
        
        <!-- handle editors/authors and abbreviate as necessary -->
        <xsl:variable name="edited" select="if (t:monogr/t:editor[not(@role) or @role!='translator']) then true() else false()"/>
        <xsl:variable name="rcount">
            <xsl:choose>
                <xsl:when test="$edited">
                    <xsl:value-of select="count(t:monogr/t:editor[not(@role) or @role!='translator'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="count(t:monogr/t:author)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:choose>
            <xsl:when test="$edited">
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:editor[not(@role) or @role!='translator'],'biblist',2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:author,'biblist',2)"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$edited">
            <xsl:choose>
                <xsl:when test="$rcount = 1">
                    <xsl:text> (ed.)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> (eds.)</xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:text>. </xsl:text>
        
        <!-- handle titles -->
        <xsl:for-each select="t:monogr[1]">
            <xsl:choose>
                <xsl:when test="t:title[@xml:lang='en']">
                    <xsl:apply-templates select="t:title[@xml:lang='en']" mode="biblist"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:title[1]" mode="biblist"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="t:monogr/t:imprint" mode="biblist"/>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a bibl list entry for the matched bibl; if it contains a 
     pointer, try to look up the master bibliography file and use that
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="biblist">
        <xsl:choose>
            <xsl:when test="t:ptr">
                <xsl:apply-templates select="t:ptr" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="biblist"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>  

    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a ptr inside a bibl: try to look up the corresponding item
     internally or externally and process that
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:ptr[ancestor::t:*[1]/self::t:bibl]" mode="biblist">
        <xsl:if test="starts-with(@target, '#')">
            <xsl:variable name="thistarget" select="substring-after(@target, '#')"/>
            <xsl:apply-templates select="/descendant::t:bibl[@xml:id=$thistarget]" mode="biblist"/>
        </xsl:if>
        <xsl:if test="starts-with(@target, 'http://syriaca.org/bibl/')">
            <xsl:variable name="biblfilepath">
                <xsl:value-of select="concat('/db/apps/srophe-data/data/bibl/tei/',substring-after(@target, 'syriaca.org/bibl/'),'.xml')"/>
            </xsl:variable>
            <xsl:if test="doc-available($biblfilepath)">
                <xsl:apply-templates select="document($biblfilepath)/descendant::t:biblStruct[1]" mode="biblist"/>
            </xsl:if>
        </xsl:if>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle name components in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:forename | t:addName | t:surname" mode="footnote" priority="1">
        <xsl:if test="preceding-sibling::t:*">
            <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:apply-templates mode="footnote"/>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle date, publisher, place of publication, placenames and foreign
     tags (i.e., language+script changes) in footnote context (the main
     reason for this is to capture language and script changes at these
     levels)
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:date | t:publisher | t:pubPlace | t:placeName | t:foreign" mode="footnote" priority="1">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="footnote"/>
        </fo:inline>
    </xsl:template>
   
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName | t:name" mode="footnote">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:choose>
                <xsl:when test="t:*">
                    <xsl:apply-templates select="t:*" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:inline>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names last-name first
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName" mode="lastname-first">
        <fo:inline>
            <xsl:call-template name="langattr"/>
            <xsl:choose>
                <xsl:when test="t:surname and t:forename">
                    <xsl:apply-templates select="t:surname" mode="footnote"/>
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="t:*[local-name()!='surname']" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="t:*" mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </fo:inline>
    </xsl:template>    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person" mode="footnote biblist" priority="1">
        <xsl:choose>
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix)">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <xsl:apply-templates select="document($editorssourcedoc)/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline>
                    <xsl:choose>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle authors and editors in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:author | t:editor | t:principal | t:person" mode="lastname-first" priority="1">
        <xsl:choose>
            <!-- if @ref exists use external editors.xml document from database -->
            <xsl:when test="@ref and starts-with(@ref, $editoruriprefix)">
                <xsl:variable name="sought" select="substring-after(@ref, $editoruriprefix)"/>
                <!-- grab editors.xml and process appropriate elements based in ref # -->
                <xsl:apply-templates select="document($editorssourcedoc)/descendant::t:body/t:listPerson[1]/t:person[@xml:id=$sought][1]" mode="lastname-first"/>
            </xsl:when>
            <!-- otherwise processes name as exists in place page -->
            <xsl:otherwise>
                <fo:inline>
                    <xsl:choose>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="lastname-first"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblStruct
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:imprint" mode="footnote biblist" priority="1">
        <xsl:text>(</xsl:text>
        <xsl:choose>
            <xsl:when test="t:pubPlace">
                <xsl:apply-templates select="t:pubPlace" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no place of publication">n.p.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>: </xsl:text>
        <xsl:choose>
            <xsl:when test="t:publisher[@xml:lang='en']">
                <xsl:apply-templates select="t:publisher[@xml:lang='en']" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:publisher">
                <xsl:apply-templates select="t:publisher[1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no publisher">n.p.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>, </xsl:text>
        <xsl:choose>
            <xsl:when test="t:date">
                <xsl:apply-templates select="t:date" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no date of publication">n.d.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>)</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle cited ranges in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:citedRange[ancestor::t:bibl or ancestor::t:biblStruct]" mode="footnote" priority="1">
        <xsl:variable name="prefix">
            <xsl:choose>
                <xsl:when test="@unit='entry'">
                    <xsl:text>“</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="suffix">
            <xsl:choose>
                <xsl:when test="@unit='entry'">
                    <xsl:text>”</xsl:text>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$prefix"/>
        <xsl:choose>
            <xsl:when test="@target">
                <fo:basic-link external-destination="url('{@target}')" xsl:use-attribute-sets="href">
                    <xsl:apply-templates select="." mode="out-normal"/>
                </fo:basic-link>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="out-normal"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$suffix"/>
    </xsl:template>


    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle bibliographic titles in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:title" mode="allbib" priority="1">
        <xsl:for-each select="./node()">
            <xsl:if test="not(self::text()) or string-length(normalize-space(.))&gt;0 or count(following-sibling::node())=0">
                <xsl:for-each select="ancestor-or-self::t:*[@xml:lang][1]">
                    <fo:inline>
                        <xsl:call-template name="langattr"/>
                        <xsl:apply-templates select="." mode="text-normal"/>
                    </fo:inline>
                </xsl:for-each>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>
    <xsl:template match="t:title" mode="biblist footnote">
        <xsl:for-each select="./node()">
            <fo:inline>
                <xsl:call-template name="langattr"/>
                <xsl:apply-templates select="." mode="text-normal"/>
            </fo:inline>
        </xsl:for-each>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes and attibutes of bibl or 
     biblStruct in the context of a footnote 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:* | @*" mode="footnote"/>
   
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in the context of a bibliographic list 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="biblist"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in universal bibliographic context 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="allbibl"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     suppress otherwise unhandled descendent nodes of bibl or biblStruct
     in universal bibliographic context 
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:*" mode="lastname-first"/>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     emit the footnote number for a bibl
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:bibl" mode="footnote-ref">
        <xsl:param name="footnote-number">1</xsl:param>
        <fo:basic-link internal-destination="{@xml:id}" xsl:use-attribute-sets="href">
            <xsl:value-of select="$footnote-number"/>
        </fo:basic-link>
    </xsl:template>

    <!-- Citation Information -->
    <xsl:template name="citationInfo">
        <fo:block border-top="4pt solid #333" space-before="12pt" background-color="#F2F2F2" padding="12pt">
            <fo:block xsl:use-attribute-sets="h2">How to Cite This Entry</fo:block>
            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-foot"/>
            <fo:block xsl:use-attribute-sets="h4">Bibliography:</fo:block>
            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="cite-biblist"/>
            <fo:block xsl:use-attribute-sets="h4">About this Entry</fo:block>
            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:titleStmt" mode="about"/>
            <fo:block xsl:use-attribute-sets="h4">Copyright and License for Reuse</fo:block>
            <fo:block xsl:use-attribute-sets="p">
                <xsl:text>Except otherwise noted, this page is © </xsl:text>
                <xsl:choose>
                    <xsl:when test="//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]/text() castable as xs:date">
                        <xsl:value-of select="format-date(xs:date(//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]), '[Y]')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:date[1]"/>
                    </xsl:otherwise>
                </xsl:choose>.
             </fo:block>
            <xsl:apply-templates select="//t:teiHeader/t:fileDesc/t:publicationStmt/t:availability/t:licence"/>
        </fo:block>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a footnote for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-foot">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'footnote',2)"/>
        <xsl:text>, </xsl:text>
        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
        <xsl:text>”</xsl:text>
        
        <!-- monographic title -->
        <xsl:text> in </xsl:text>
        <xsl:apply-templates select="t:title[@level='m'][1]" mode="footnote"/>
        
        <!-- general editors -->
        <xsl:text>, eds. </xsl:text>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='general'],'footnote',2)"/>
        <xsl:text>,</xsl:text>
        
        <!-- publication date statement -->
        <xsl:text> entry published </xsl:text>
        <xsl:for-each select="../t:publicationStmt/t:date[1]">
            <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
        </xsl:for-each>
        <xsl:text>,</xsl:text>
        
        <!-- project -->
        <xsl:text> </xsl:text>
        <xsl:value-of select="t:sponsor[1]"/>
        <xsl:text>, ed. </xsl:text>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:principal,'footnote',2)"/>
        <xsl:text>, </xsl:text>
        <xsl:text> </xsl:text>
        <!-- NOTE:       <xsl:value-of select="$htmluri"/>-->
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate a bibliographic entry for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="cite-biblist">
        <!-- creator(s) of the entry -->
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'biblist',2)"/>
        <xsl:text>, </xsl:text>
        
        <!-- title of the entry -->
        <xsl:text>“</xsl:text>
        <xsl:apply-templates select="t:title[@level='a'][1]" mode="biblist"/>
        <xsl:text>.”</xsl:text>
        
        <!-- monographic title -->
        <xsl:text> In </xsl:text>
        <xsl:apply-templates select="t:title[@level='m'][1]" mode="biblist"/>
        
        <!-- general editors -->
        <xsl:text>, edited by </xsl:text>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='general'],'footnote',2)"/>
        <xsl:text>.</xsl:text>
        
        <!-- publication date statement -->
        <xsl:text> Entry published </xsl:text>
        <xsl:for-each select="../t:publicationStmt/t:date[1]">
            <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
        </xsl:for-each>
        <xsl:text>.</xsl:text>
        
        <!-- project -->
        <xsl:text> </xsl:text>
        <xsl:value-of select="t:sponsor[1]"/>
        <xsl:text>, edited by </xsl:text>
        <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
        <xsl:sequence select="local:emit-responsible-persons(t:principal,'footnote',2)"/>
        <xsl:text>.</xsl:text>
        <xsl:text> </xsl:text>
        <!-- NOTE:       <xsl:value-of select="$htmluri"/>-->
        <xsl:text>.</xsl:text>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     generate an "about this entry" section for the matched titleStmt element
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:titleStmt" mode="about">
        <fo:block xsl:use-attribute-sets="p">
            <fo:inline xsl:use-attribute-sets="bold">Entry Title:</fo:inline>
            <xsl:text> </xsl:text>
            <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
        </fo:block>
        <fo:block xsl:use-attribute-sets="p">
            <fo:inline xsl:use-attribute-sets="bold">Entry Contributor<xsl:if test="count(t:editor[@role='creator'])&gt;1">s</xsl:if>:</fo:inline>
            <xsl:text> </xsl:text>
            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'footnote',count(t:editor[@role='creator'])+1)"/>
        </fo:block>
        <fo:block xsl:use-attribute-sets="p">
            <fo:inline xsl:use-attribute-sets="bold">Publication Date:</fo:inline>
            <xsl:text> </xsl:text>
            <xsl:for-each select="../t:publicationStmt/t:date[1]">
                <xsl:value-of select="format-date(xs:date(.), '[MNn] [D], [Y]')"/>
            </xsl:for-each>
        </fo:block>
        <fo:block>
            <fo:block xsl:use-attribute-sets="h4">Authorial and Editorial Responsibility:</fo:block>
            <fo:list-block xsl:use-attribute-sets="indent">
                <fo:list-item>
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block>•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                            <xsl:sequence select="local:emit-responsible-persons(t:principal,'footnote',2)"/>
                            <xsl:text>, general editor</xsl:text>
                            <xsl:if test="count(t:principal) &gt; 1">s</xsl:if>
                            <xsl:text>, </xsl:text>
                            <xsl:value-of select="t:sponsor[1]"/>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
                <fo:list-item>
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block>•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='general'],'footnote',2)"/>
                            <xsl:text>, editor</xsl:text>
                            <xsl:if test="count(t:editor[@role='general'])&gt; 1">s</xsl:if>
                            <xsl:text>, </xsl:text>
                            <xsl:apply-templates select="t:title[@level='m'][1]" mode="footnote"/>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
                <fo:list-item>
                    <fo:list-item-label end-indent="label-end()">
                        <fo:block>•</fo:block>
                    </fo:list-item-label>
                    <fo:list-item-body start-indent="body-start()">
                        <fo:block>
                            <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                            <xsl:sequence select="local:emit-responsible-persons(t:editor[@role='creator'],'biblist',2)"/>
                            <xsl:text>, entry contributor</xsl:text>
                            <xsl:if test="count(t:editor[@role='creator'])&gt; 1">s</xsl:if>
                            <xsl:text>, </xsl:text>
                            <xsl:text>“</xsl:text>
                            <xsl:apply-templates select="t:title[@level='a'][1]" mode="footnote"/>
                            <xsl:text>”</xsl:text>
                        </fo:block>
                    </fo:list-item-body>
                </fo:list-item>
            </fo:list-block>
        </fo:block>
        <xsl:if test="t:respStmt">
            <fo:block>
                <fo:block xsl:use-attribute-sets="h4">Additional Credit:</fo:block>
                <fo:list-block xsl:use-attribute-sets="indent">
                    <xsl:for-each select="t:respStmt">
                        <fo:list-item>
                            <fo:list-item-label end-indent="label-end()">
                                <fo:block>•</fo:block>
                            </fo:list-item-label>
                            <fo:list-item-body start-indent="body-start()">
                                <fo:block>
                                    <xsl:value-of select="t:resp"/>
                                    <xsl:text> </xsl:text>
                                    <xsl:apply-templates select="t:name" mode="footnote"/>
                                </fo:block>
                            </fo:list-item-body>
                        </fo:list-item>
                    </xsl:for-each>
                </fo:list-block>
            </fo:block>
        </xsl:if>
    </xsl:template>
    
    
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <!-- |||| match=t:*: suppress all TEI elements not otherwise handled -->
    <!-- ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||| -->
    <xsl:template match="t:teiHeader/child::*[not(child::t:titleStmt/t:title)]"/>
    <xsl:template match="t:*" mode="pdf-out-normal">
        <xsl:apply-templates select="." mode="text-normal"/>
    </xsl:template>
</xsl:stylesheet>