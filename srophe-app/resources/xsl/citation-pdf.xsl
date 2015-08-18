<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" xmlns:fo="http://www.w3.org/1999/XSL/Format" exclude-result-prefixes="xs t" version="2.0">
  
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
       citation.xsl
       
       This XSLT provides templates for output of citation guidance. 
       
       parameters:
       
       assumptions and dependencies:
        + transform has been tested with Saxon PE 9.4.0.6 with initial
          template (-it) option set to "do-index" (i.e., there is no 
          single input file)
        
       code by: 
        + Tom Elliott (http://www.paregorios.org) 
          for the Institute for the Study of the Ancient World, New York
          University, under contract to Vanderbilt University for the
          NEH-funded Syriac Reference Portal project.
          
       funding provided by:
        + National Endowment for the Humanities (http://www.neh.gov). Any 
          views, findings, conclusions, or recommendations expressed in 
          this code do not necessarily reflect those of the National 
          Endowment for the Humanities.
       
       ================================================================== -->
  
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
            <fo:list-block>
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
                <fo:list-block>
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
</xsl:stylesheet>