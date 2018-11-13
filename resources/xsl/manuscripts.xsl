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
       manuscripts.xsl
       
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
 <!-- TEMPLATES -->
 <!-- =================================================================== -->

    <!-- Manuscript templates -->
    <xsl:template match="t:msDesc">
        <div class="row">
            <div class="col-md-4">
                <div class="well">
                    <xsl:apply-templates select="descendant::t:textLang[@mainLang] | descendant::t:msIdentifier"/>
                </div>
                <div>
                    <xsl:apply-templates select="descendant::t:physDesc | descendant::t:profileDesc/t:langUsager"/>
                </div>
                <div class="well">
                    <xsl:apply-templates select="descendant::t:history | descendant::t:additional | descendant::t:encodingDesc"/>
                </div>
            </div>
            <div class="col-md-8 column1">
                <div>
                    <h3>Manuscript Contents</h3>
                    <p style="margin:0 2em;" class="well">This manuscript contains 
                        <xsl:value-of select="count(descendant::t:msItem)"/>
                         items 
                        <xsl:if test="descendant::t:msItem/t:msItem">
                            <xsl:text> including nested subsections</xsl:text>
                        </xsl:if>. N.B. Items were re-numbered by Syriaca.org and may not reflect previous numeration.</p>
                </div>
                <xsl:apply-templates select="descendant::t:msContents | descendant::t:teiHeader/descendant::t:msPart"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:msPart">
        <div class="row">
            <xsl:if test="t:msIdentifier">
                <h3>
                    <xsl:apply-templates select="t:altIdentifier"/>
                </h3>
                <h4>
                    <xsl:apply-templates select="t:idno"/>
                </h4>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="t:physDesc">
                    <div class="col-md-4">
                        <xsl:apply-templates select="t:physDesc"/>
                    </div>
                    <div class="col-md-8">
                        <xsl:apply-templates select="*[not(self::t:physDesc)]"/>
                    </div>
                </xsl:when>
                <xsl:otherwise>
                    <div class="col-md-12">
                        <xsl:apply-templates/>
                    </div>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>
    <xsl:template match="t:msIdentifier">
        <h4>Current location: </h4>
        <div class="msItem">
            <xsl:value-of select="t:country"/>
            <xsl:if test="t:country/following-sibling::*"> - </xsl:if>
            <xsl:value-of select="t:settlement"/>
            <xsl:if test="t:settlement/following-sibling::*"> - </xsl:if>
            <xsl:value-of select="t:repository"/>
            <xsl:if test="t:repository/following-sibling::*"> - </xsl:if>
            <xsl:value-of select="t:collection"/>
        </div>
        <h4>Identification</h4>
        <xsl:apply-templates select="t:altIdentifier"/>
    </xsl:template>
    <xsl:template match="t:altIdentifier">
        <xsl:choose>
            <xsl:when test="t:idno[@type ='Wright-BL-Arabic']">
                <div class="msItem">
                    <div>
                        <xsl:value-of select="t:collection"/>
                    </div>
                    <div>
                        <strong>Wright number:</strong>
                        <xsl:value-of select="t:idno"/>
                        (<xsl:value-of select="following-sibling::t:altIdentifier[child::t:idno[@type='Wright-BL-Roman']]/t:idno"/>)
                    </div>
                </div>
            </xsl:when>
            <xsl:when test="t:idno[@type ='BL-Shelfmark']">
                <div class="msItem">
                    <xsl:value-of select="."/>
                </div>
            </xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:history/t:origin">
        <xsl:for-each select="t:origDate">
            <p>
                <span class="srp-label">Date of Origin: </span>
                <xsl:variable name="range">
                    <xsl:if test="@notBefore or @notAfter or @to or @from or @when">
                        <xsl:text> (</xsl:text>
                        <xsl:value-of select="@notBefore|@from|@when"/>
                        <xsl:if test="@notAfter or @to">
                            <xsl:text> - </xsl:text>
                            <xsl:value-of select="@notAfter|@to"/>
                        </xsl:if>
                        <xsl:text>)</xsl:text>
                    </xsl:if>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:value-of select="."/>
                        <xsl:sequence select="$range"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$range"/>
                    </xsl:otherwise>
                </xsl:choose>
            </p>
        </xsl:for-each>
        <xsl:for-each select="t:origPlace">
            <p>
                <span class="srp-label">Place of Origin: </span>
                <xsl:choose>
                    <xsl:when test="text()">
                        <xsl:value-of select="."/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- Add date range handling -->
                    </xsl:otherwise>
                </xsl:choose>
            </p>
        </xsl:for-each>
        <!-- NOTE: Are there other children of origin that should be visualized? -->
    </xsl:template>
    <xsl:template match="t:textLang[@mainLang]">
        <xsl:if test="not(parent::*)">
            <p>
                <strong>Language: </strong>
                <xsl:apply-templates/>
            </p>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:origPlace">
        <xsl:choose>
            <xsl:when test="string-length(text()) &lt; 1">Not available</xsl:when>
            <xsl:otherwise>
                <span>
                    Place:  <xsl:apply-templates/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:msContents">
        <div>
            <div class="msItem">
                <div>
                    <xsl:apply-templates/>
                </div>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:physDesc">
        <div class="well">
            <h3 class="srp-label">Physical Description</h3>
            <div style="margin-left:.5em;">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:msAuthors"/>
    <xsl:template match="t:msItem">
        <xsl:choose>
            <xsl:when test="@defective = 'true'">
                <div name="{string(@xml:id)}" class="msItem">
                    <div>
                        <strong>Item <xsl:value-of select="@n"/>
                        </strong> (defective)
                    </div>
                    <div class="msItem">
                        <xsl:call-template name="msItem-child"/>
                    </div>
                </div>
            </xsl:when>
            <xsl:when test="@defective ='unknown'">
                <div name="{string(@xml:id)}" class="msItem">
                    <div>
                        <strong>Item <xsl:value-of select="@n"/>
                        </strong> (defective?)
                    </div>
                    <div class="msItem">
                        <xsl:call-template name="msItem-child"/>
                    </div>
                </div>
            </xsl:when>
            <xsl:otherwise>
                <div name="{string(@xml:id)}" class="msItem">
                    <div>
                        <strong>Item <xsl:value-of select="@n"/>
                        </strong>
                    </div>
                    <div class="msItem">
                        <xsl:call-template name="msItem-child"/>
                    </div>
                </div>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:additional">
        <div>
            <h4>Origin: </h4>
            <div class="msItem">
                <xsl:apply-templates select="*[not(self::t:listBibl)]"/>
            </div>
            <div>
                <strong>Bibliographic list:</strong>
                <xsl:apply-templates select="t:listBibl"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template name="msItem-child">
        <xsl:apply-templates select="t:title"/>
        <!-- Have to pull in author via xquery? or just doc? -->
        <p>
            <strong>Author: </strong>
            <xsl:for-each select="t:author">
                <xsl:variable name="author" select="string(@ref)"/>
                <a href="{$author}">
                    <xsl:value-of select="string-join(/t:msAuthors/t:msAuthor[@id = $author][1],' ')"/>
                </a>
            </xsl:for-each>
        </p>
        <xsl:apply-templates select="*[not(self::t:title or self::t:author or self::t:listBibl)]"/>
        <xsl:if test="t:listBibl">
            <div>
                <strong>Bibliographic list:</strong>
                <xsl:apply-templates select="t:listBibl"/>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:rubric">
        <p>
            <xsl:choose>
                <xsl:when test="@xml:lang='syr'">
                    <strong>Syriac Title: </strong>
                    <bdi lang="syr">
                        <xsl:apply-templates/>
                    </bdi>
                </xsl:when>
                <xsl:otherwise>
                    <strong>Rubric: </strong>
                    <xsl:apply-templates/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <xsl:template match="t:incipit">
        <p>
            <strong>Incipit: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:msItem/t:title">
        <p>
            <strong>Title: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:msItem/t:author">
        <!-- Have to pull in author via xquery? or just doc? -->
        <p>
            <strong>Author: </strong>
            <xsl:variable name="author" select="string(@ref)"/>
            <a href="{$author}">
                <xsl:value-of select="string-join(/t:msAuthors/t:msAuthor[@id = $author][1],' ')"/>
            </a>
        </p>
    </xsl:template>
    <xsl:template match="t:editor">
        <p>
            <strong>Editor: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:locus">
        <xsl:choose>
            <xsl:when test="parent::t:msItem">
                <p>
                    <xsl:choose>
                        <xsl:when test="parent::t:msItem"/>
                        <xsl:otherwise>
                            <xsl:attribute name="class">msItem</xsl:attribute>
                        </xsl:otherwise>
                    </xsl:choose>
                    <strong>Locus: </strong>
                    <xsl:choose>
                        <xsl:when test="string-length(.) &gt; 0">
                            <xsl:apply-templates/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:if test="@from"> from <xsl:value-of select="@from"/>
                            </xsl:if>
                            <xsl:if test="@to"> to <xsl:value-of select="@to"/>
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:quote[parent::t:msItem]">
        <p>
            <strong>Quote: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:explicit">
        <p>
            <strong>Explicit: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:colophon">
        <p>
            <strong>Colophon: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:finalRubric">
        <p>
            <strong>Desinit: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:note[ancestor::t:msItem]">
        <p>
            <strong>Note</strong>
            <br/>
            <xsl:apply-templates select="." mode="plain"/>
        </p>
    </xsl:template>
    <xsl:template match="t:filiation">
        <p>
            <strong>Filiation: </strong>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="t:material">
        <div>
            <strong>Material: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:extent[ancestor::t:physDesc]">
        <div>
            <h4>Extent:</h4>
            <xsl:apply-templates mode="msExtent"/>
        </div>
    </xsl:template>
    <xsl:template match="t:measure" mode="msExtent">
        <span class="msExtent">
            <xsl:value-of select="concat(upper-case(substring(@type,1,1)),substring(@type,2))"/> (<xsl:value-of select="@unit"/>) <xsl:value-of select="."/>
        </span>
    </xsl:template>
    <xsl:template match="t:foliation">
        <div>
            <strong>Foliation: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:collation">
        <div>
            <strong>Collation: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:additions">
        <div>
            <strong>Additions: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:condition">
        <div>
            <strong>Condition: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:layoutDesc">
        <div>
            <strong>Layout: </strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:handNote">
        <div name="{string(@xml:id)}">
            Hand <xsl:value-of select="substring-after(string(@xml:id),'ote')"/>:
            <div class="msItem">
                <xsl:if test="@scope">
                    Scope:  <xsl:value-of select="@scope"/>
                </xsl:if>
                <xsl:if test="@script">
                    <xsl:variable name="script" select="@script"/>
                    <div>
                        Script: <xsl:value-of select="//t:langUsage/t:language[@ident = $script]/text()"/>
                    </div>
                </xsl:if>
                <xsl:if test="@medium">
                    <div>
                        Medium: <xsl:value-of select="@medium"/>
                    </div>
                </xsl:if>
                <xsl:apply-templates mode="plain"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:decoNote">
        <div name="{string(@xml:id)}">
            Decoration <xsl:value-of select="substring-after(string(@xml:id),'ote')"/>:
            <div class="msItem">
                <xsl:if test="@type">
                    <div>
                        Type: <xsl:value-of select="@type"/>
                    </div>
                </xsl:if>
                <xsl:if test="@medium">
                    <div>
                        Medium: <xsl:value-of select="@medium"/>
                    </div>
                </xsl:if>
                <xsl:apply-templates mode="plain"/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:binding">
        <div class="msItem" name="{string(@xml:id)}">
            Binding Note <xsl:value-of select="substring-after(string(@xml:id),'ing')"/>:
            <div class="msItem">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:seal">
        <div class="msItem" name="{string(@xml:id)}">
            Seal Note <xsl:value-of select="substring-after(string(@xml:id),'seal')"/>: 
            <div class="msItem">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:history">
        <xsl:if test="not(empty(.))">
            <div>
                <h4>History: </h4>
                <div class="msItem">
                    <xsl:apply-templates/>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:summary">
        <xsl:if test="string-length(.) &gt; 0">
            <div>
                <h4>Summary: </h4>
                <div class="msItem">
                    <xsl:apply-templates/>
                </div>
            </div>
        </xsl:if>
    </xsl:template>
    <xsl:template match="t:origin">
        <div>
            <h4>Origin: </h4>
            <div class="msItem">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    <xsl:template match="t:origDate">
        <div>
            Date:  <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:provenance">
        <div>Provenance: <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:acquisition">
        <div>Acquisition: <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:availability">
        <div>Availability: <xsl:value-of select="string(@status)"/>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:custodialHist">
        <div>
            <strong>Custodial History:</strong>
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    <xsl:template match="t:custEvent">
        <div>Type: <xsl:value-of select="string(@type)"/>
            <div class="msItem">
                <xsl:apply-templates/>
            </div>
        </div>
    </xsl:template>
    
    <!--
    <xsl:template match="* | @*" mode="labeled">
        <xsl:if test="not(empty(.))">
            <span>
                <span class="srp-label"><xsl:value-of select="name(.)"/>: </span>
                <span class="note"><xsl:apply-templates/></span>
            </span>            
        </xsl:if>
    </xsl:template>
    -->
</xsl:stylesheet>