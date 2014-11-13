<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t" version="2.0">
    
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
       bibliography.xsl
       
       This XSLT provides templates for output of bibliographic material. 
       
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
        <li id="{@xml:id}">
            <span class="anchor"/>
            <!-- Display footnote number -->
            <span class="footnote-tgt">
                <xsl:value-of select="$thisnum"/>
            </span>
            <xsl:text> </xsl:text>
            <span class="footnote-content">
                <!-- if there is an analytic title present, then we have a separately titled book section -->
                <xsl:if test="t:title[@level='a']">
                    <!-- Process editors/authors using local function in helper-functions.xsl local:emit-responsible-persons -->
                    <xsl:sequence select="local:emit-responsible-persons(t:author,'footnote',3)"/>
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
                            <xsl:value-of select="concat('/db/apps/srophe/data/bibl/tei/',substring-after(t:ptr/@target, 'http://syriaca.org/bibl/'),'.xml')"/>
                        </xsl:variable>
                        <!-- Check if record exists in db with doc-available function -->
                        <xsl:if test="doc-available($biblfilepath)">
                            <!-- Process record as a footnote -->
                            <xsl:apply-templates select="document($biblfilepath)/descendant::t:biblStruct[1]" mode="footnote"/>
                        </xsl:if>
                        <!-- Process all citedRange elements as footnotes -->
                        <xsl:if test="t:citedRange">, 
                            <xsl:for-each select="t:citedRange">
                                <xsl:apply-templates select="." mode="footnote"/>
                            </xsl:for-each>
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="footnote"/>
                    </xsl:otherwise>
                </xsl:choose>
            </span>
        </li>
    </xsl:template>
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle a footnote for a book
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:biblStruct[t:monogr and not(t:analytic)]" mode="footnote">
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
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:editor[not(@role) or @role!='translator'],'footnote',3)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:author,'footnote',3)"/>
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
                <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                    <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')]" mode="footnote"/>
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
            <xsl:sequence select="local:emit-responsible-persons(t:monogr[1]/t:editor[@role='translator'],'footnote',3)"/>
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
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:editor[not(@role) or @role!='translator'],'biblist',3)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:author,'biblist',3)"/>
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
                <xsl:when test="t:title[starts-with(@xml:lang,'en')]">
                    <xsl:apply-templates select="t:title[starts-with(@xml:lang,'en')]" mode="biblist"/>
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
                <xsl:value-of select="concat('/db/apps/srophe/data/bibl/tei/',substring-after(@target, 'syriaca.org/bibl/'),'.xml')"/>
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
        <span class="{local-name()}">
            <xsl:call-template name="langattr"/>
            <xsl:apply-templates mode="footnote"/>
        </span>
    </xsl:template>
   
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName | t:name" mode="footnote">
        <span class="{local-name()}">
            <xsl:call-template name="langattr"/>
            <xsl:choose>
                <xsl:when test="t:*">
                    <xsl:apply-templates select="t:*" mode="footnote"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates mode="footnote"/>
                </xsl:otherwise>
            </xsl:choose>
        </span>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle personal names last-name first
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:persName" mode="lastname-first">
        <span class="persName">
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
        </span>
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
                <span class="{local-name()}">
                    <xsl:choose>
                        <xsl:when test="t:persName[starts-with(@xml:lang,'en')]">
                            <xsl:apply-templates select="t:persName[starts-with(@xml:lang,'en')][1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="footnote"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
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
                <span class="{local-name()}">
                    <xsl:choose>
                        <xsl:when test="t:persName">
                            <xsl:apply-templates select="t:persName[1]" mode="lastname-first"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates mode="footnote"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle the imprint component of a biblStruct
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:imprint" mode="footnote biblist" priority="1">
        <xsl:text>(</xsl:text>
        <xsl:choose>
            <xsl:when test="t:pubPlace[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:pubPlace[starts-with(@xml:lang,'en')]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="t:pubPlace">
                <xsl:apply-templates select="t:pubPlace[1]" mode="footnote"/>
            </xsl:when>
            <xsl:otherwise>
                <abbr title="no place of publication">n.p.</abbr>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>: </xsl:text>
        <xsl:choose>
            <xsl:when test="t:publisher[starts-with(@xml:lang,'en')]">
                <xsl:apply-templates select="t:publisher[starts-with(@xml:lang,'en')]" mode="footnote"/>
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
        <xsl:choose>
            <xsl:when test="@unit='ff'"/>
            <xsl:otherwise><xsl:value-of select="concat(@unit,': ')"/></xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
            <xsl:when test="@target">
                <a href="{@target}">
                    <xsl:choose>
                        <xsl:when test="@unit='ff'">
                            <xsl:text>, f. </xsl:text>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:apply-templates select="." mode="out-normal"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="@unit='ff'">
                        <xsl:text>, f. </xsl:text>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="out-normal"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="following-sibling::*">,</xsl:if>
        <xsl:if test="not(following-sibling::*)">.</xsl:if>
    </xsl:template>

    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
        depreciated, use local:emit-responsible-persons function, ex:
        <xsl:sequence select="local:emit-responsible-persons(t:monogr/t:editor[not(@role) or @role!='translator'],'footnote',2)"/>
        handle creators for type footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template name="emit-responsible-persons">
        <xsl:param name="perss"/>
        <xsl:param name="moded">footnote</xsl:param>
        <xsl:param name="maxauthorsfootnote">2</xsl:param>
        <xsl:param name="maxauthorsbiblist">2</xsl:param>
        <xsl:variable name="ccount" select="count($perss/t:*)"/>
        <xsl:choose>
            <!-- When the author is included in the bibl element on the place page there is no child element -->
            <xsl:when test="$ccount &lt; 1">
                <xsl:apply-templates select="$perss" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount=1 and $moded='footnote'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount=1 and $moded='biblist'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="lastname-first"/>
            </xsl:when>
            <xsl:when test="$ccount &gt; $maxauthorsfootnote and $moded='footnote'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="footnote"/>
                <xsl:text> et al.</xsl:text>
            </xsl:when>
            <xsl:when test="$ccount &gt; $maxauthorsbiblist and $moded='biblist'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="lastname-first"/>
                <xsl:text> et al.</xsl:text>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='footnote'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="footnote"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$perss/t:*[2]" mode="footnote"/>
            </xsl:when>
            <xsl:when test="$ccount = 2 and $moded='biblist'">
                <xsl:apply-templates select="$perss/t:*[1]" mode="lastname-first"/>
                <xsl:text> and </xsl:text>
                <xsl:apply-templates select="$perss/t:*[2]" mode="biblist"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$perss/t:*[position() &lt; $maxauthorsfootnote+1]">
                    <xsl:choose>
                        <xsl:when test="position() = $maxauthorsfootnote">
                            <xsl:text> and </xsl:text>
                        </xsl:when>
                        <xsl:when test="position() &gt; 1">
                            <xsl:text>, </xsl:text>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:choose>
                        <xsl:when test="$moded='footnote'">
                            <xsl:apply-templates select="." mode="footnote"/>
                        </xsl:when>
                        <xsl:when test="$moded='biblist'">
                            <xsl:apply-templates select="." mode="biblist"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <!-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
     handle bibliographic titles in the context of a footnote
     ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ -->
    <xsl:template match="t:title" mode="footnote biblist allbib" priority="1">
        <span>
            <xsl:attribute name="class">
                <xsl:text>title</xsl:text>
                <xsl:choose>
                    <xsl:when test="@level='a'">
                        <xsl:text>-analytic</xsl:text>
                    </xsl:when>
                    <xsl:when test="@level='m'">
                        <xsl:text>-monographic</xsl:text>
                    </xsl:when>
                    <xsl:when test="@level='j'">
                        <xsl:text>-journal</xsl:text>
                    </xsl:when>
                    <xsl:when test="@level='s'">
                        <xsl:text>-series</xsl:text>
                    </xsl:when>
                    <xsl:when test="@level='u'">
                        <xsl:text>-unpublished</xsl:text>
                    </xsl:when>
                </xsl:choose>
            </xsl:attribute>
            <xsl:for-each select="./node()">
                <xsl:if test="not(self::text()) or string-length(normalize-space(.))&gt;0 or count(following-sibling::node())=0">
                    <bdi>
                        <xsl:for-each select="ancestor-or-self::t:*[@xml:lang][1]">
                            <xsl:attribute name="dir">
                                <xsl:call-template name="getdirection"/>
                            </xsl:attribute>
                            <xsl:call-template name="langattr"/>
                        </xsl:for-each>
                        <xsl:apply-templates select="." mode="text-normal"/>
                    </bdi>
                </xsl:if>
            </xsl:for-each>
        </span>
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
        <span class="footnote-ref">
            <a href="#{@xml:id}">
                <xsl:value-of select="$footnote-number"/>
            </a>
        </span>
    </xsl:template>
</xsl:stylesheet>