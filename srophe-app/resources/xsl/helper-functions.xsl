<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t" version="2.0">
    
    <!-- 
  Function to output dates in correct formats passes whole element to function, 
  function also uses trim-date to strip leading 0
 -->
    <xsl:function name="local:do-dates">
        <xsl:param name="element" as="node()"/>
        <xsl:if test="$element/@when or $element/@notBefore or $element/@notAfter or $element/@from or $element/@to">
            (<xsl:choose>
                <!-- Formats to and from dates -->
                <xsl:when test="$element/@from">
                    <xsl:choose>
                        <xsl:when test="$element/@to">
                            <xsl:value-of select="local:trim-date($element/@from)"/>-<xsl:value-of select="local:trim-date($element/@to)"/>
                        </xsl:when>
                        <xsl:otherwise>from <xsl:value-of select="local:trim-date($element/@from)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$element/@to">to <xsl:value-of select="local:trim-date($element/@to)"/>
                </xsl:when>
            </xsl:choose>
            <!-- Formats notBefore and notAfter dates -->
            <xsl:if test="$element/@notBefore">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from">, </xsl:if>not before <xsl:value-of select="local:trim-date($element/@notBefore)"/>
            </xsl:if>
            <xsl:if test="$element/@notAfter">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore">, </xsl:if>not after <xsl:value-of select="local:trim-date($element/@notAfter)"/>
            </xsl:if>
            <!-- Formats when, single date -->
            <xsl:if test="$element/@when">
                <!-- Adds comma if there are other dates -->
                <xsl:if test="$element/@to or $element/@from or $element/@notBefore or $element/@notAfter">, </xsl:if>
                <xsl:value-of select="local:trim-date($element/@when)"/>
            </xsl:if>)
        </xsl:if>
    </xsl:function>
    
    <!-- Date function to remove leading 0s -->
    <xsl:function name="local:trim-date">
        <xsl:param name="date"/>
        <xsl:choose>
            <!-- NOTE: This can easily be changed to display BCE instead -->
            <!-- removes leading 0 but leaves -  -->
            <xsl:when test="starts-with($date,'-0')">
                <xsl:value-of select="concat(substring($date,3),' BCE')"/>
            </xsl:when>
            <!-- removes leading 0 -->
            <xsl:when test="starts-with($date,'0')">
                <xsl:value-of select="substring($date,2)"/>
            </xsl:when>
            <!-- passes value through without changing it -->
            <xsl:otherwise>
                <xsl:value-of select="$date"/>
            </xsl:otherwise>
        </xsl:choose>
        <!--  <xsl:value-of select="string(number($date))"/>-->
    </xsl:function>
    
    <!-- To be made: Date function to pretty print dates as Month Day, Year -->
    
    <!-- Function for adding footnotes -->
    <xsl:function name="local:do-refs" as="node()">
        <xsl:param name="refs"/>
        <xsl:param name="lang"/>
        <!-- 
           <bdi class="footnote-refs" dir="ltr"> <span class="footnote-ref"><a href="#bib78-5">5</a></span></bdi>
           NOTE: check to see if this is the real rule accross footnotes, otherwise it will need to get more complicated.
          -->
        <bdi class="footnote-refs" dir="ltr">
            <xsl:if test="$lang != 'en'">
                <xsl:attribute name="lang">en</xsl:attribute>
                <xsl:attribute name="xml:lang">en</xsl:attribute>
            </xsl:if>
            <xsl:for-each select="tokenize($refs,' ')">
                <span class="footnote-ref">
                    <a href="{.}">
                        <xsl:value-of select="substring-after(.,'-')"/>
                    </a>
                    <xsl:if test="position() != last()">,<xsl:text> </xsl:text>
                    </xsl:if>
                </span>
            </xsl:for-each>
            <xsl:text> </xsl:text>
        </bdi>
    </xsl:function>
    
    <!-- Process names editors/authors ect -->
    <xsl:function name="local:emit-responsible-persons">
        <!-- node passed by refering stylesheet -->
        <xsl:param name="current-node"/>
        <!-- mode, footnote or biblist -->
        <xsl:param name="moded"/>
        <!-- max number of authors -->
        <xsl:param name="maxauthors"/>
        <!-- count number of relevant persons -->
        <xsl:variable name="ccount">
            <xsl:value-of select="count($current-node)"/>
        </xsl:variable> 
        <!-- process based on above parameters -->
        <xsl:variable name="persons">
            <xsl:choose>
                <xsl:when test="$ccount=1 and $moded='footnote'">
                    <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                </xsl:when>
                <xsl:when test="$ccount=1 and $moded='biblist'">
                    <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                </xsl:when>
                <xsl:when test="$ccount &gt; $maxauthors and $moded='footnote'">
                    <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                    <xsl:text> et al.</xsl:text>
                </xsl:when>
                <xsl:when test="$ccount &gt; $maxauthors and $moded='biblist'">
                    <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                    <xsl:text> et al.</xsl:text>
                </xsl:when>
                <xsl:when test="$ccount = 2 and $moded='footnote'">
                    <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates select="$current-node[2]" mode="footnote"/>
                </xsl:when>
                <xsl:when test="$ccount = 2 and $moded='biblist'">
                    <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates select="$current-node[2]" mode="biblist"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$current-node[position() &lt; $maxauthors+1]">
                        <xsl:choose>
                            <xsl:when test="position() = $maxauthors">
                                <xsl:text> and </xsl:text>
                            </xsl:when>
                            <xsl:when test="position() &gt; 1">
                                <xsl:text>, </xsl:text>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="$moded='footnote'">
                                <xsl:apply-templates mode="footnote"/>
                            </xsl:when>
                            <xsl:when test="$moded='biblist'">
                                <xsl:apply-templates mode="biblist"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="normalize-space($persons)"/>
    </xsl:function>
    
    <!-- Process names editors/authors ect -->
    <xsl:function name="local:emit-responsible-persons-all">
        <!-- node passed by refering stylesheet -->
        <xsl:param name="current-node"/>
        <!-- mode, footnote or biblist -->
        <xsl:param name="moded"/>
        <!-- count number of relevant persons -->
        <xsl:variable name="ccount">
            <xsl:value-of select="count($current-node)"/>
        </xsl:variable>  
        <!-- process based on above parameters -->
        <xsl:variable name="persons">
            <xsl:choose>
                <xsl:when test="$ccount=1 and $moded='footnote'">
                    <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                </xsl:when>
                <xsl:when test="$ccount=1 and $moded='biblist'">
                    <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                </xsl:when>
                <xsl:when test="$ccount = 2 and $moded='footnote'">
                    <xsl:apply-templates select="$current-node[1]" mode="footnote"/>
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates select="$current-node[2]" mode="footnote"/>
                </xsl:when>
                <xsl:when test="$ccount = 2 and $moded='biblist'">
                    <xsl:apply-templates select="$current-node[1]" mode="lastname-first"/>
                    <xsl:text> and </xsl:text>
                    <xsl:apply-templates select="$current-node[2]" mode="biblist"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$current-node">
                        <xsl:choose>
                            <xsl:when test="position() = $ccount">
                                <xsl:if test="$ccount &gt; 2">
                                    <xsl:text>,</xsl:text>
                                </xsl:if>
                                <xsl:text> and </xsl:text>
                            </xsl:when>
                            <xsl:when test="position() &gt; 1">
                                <xsl:text>, </xsl:text>
                            </xsl:when>
                        </xsl:choose>
                        <xsl:choose>
                            <xsl:when test="$moded='footnote'">
                                <xsl:apply-templates mode="footnote"/>
                            </xsl:when>
                            <xsl:when test="$moded='biblist'">
                                <xsl:apply-templates mode="biblist"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="normalize-space($persons)"/>
    </xsl:function>
    <!-- Text normalization functions -->
    <xsl:template match="t:*" mode="out-normal">
        <xsl:variable name="thislang" select="ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
        <xsl:choose>
            <xsl:when test="starts-with($thislang, 'syr') or starts-with($thislang, 'syc') or starts-with($thislang, 'ar')">
                <bdi dir="rtl">
                    <xsl:apply-templates select="." mode="text-normal"/>
                </bdi>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="text-normal"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="t:*" mode="text-normal">
        <xsl:value-of select="normalize-space(normalize-unicode(., $normalization))"/>
    </xsl:template>
    <xsl:template match="text()" mode="text-normal">
        <xsl:variable name="prefix">
            <xsl:if test="(preceding-sibling::t:* or preceding-sibling::text()[normalize-space()!='']) and string-length(.) &gt; 0 and substring(., 1, 1)=' '">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:variable name="suffix">
            <xsl:if test="(following-sibling::t:* or following-sibling::text()[normalize-space()!='']) and string-length(.) &gt; 0 and substring(., string-length(.), 1)=' '">
                <xsl:text> </xsl:text>
            </xsl:if>
        </xsl:variable>
        <xsl:value-of select="$prefix"/>
        <xsl:value-of select="normalize-space(normalize-unicode(., $normalization))"/>
        <xsl:value-of select="$suffix"/>
    </xsl:template>
</xsl:stylesheet>