<!-- Depreciated. atom feed built with xquery atom.xql -->
<xsl:stylesheet xmlns="http://www.w3.org/2005/Atom" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:a="http://www.w3.org/2005/Atom" xmlns:georss="http://www.georss.org/georss" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs tei a" version="2.0">
    <xsl:output name="atom" encoding="UTF-8" method="xml" indent="yes" exclude-result-prefixes="xs tei a"/>
    <xsl:output encoding="UTF-8" method="xml" indent="yes" exclude-result-prefixes="xs tei a"/>
    <xsl:template match="/">
        <xsl:choose>
            <xsl:when test="count(//tei:TEI) &gt; 1">
                <feed>
                    <title>The Syriac Gazetteer: Latest Updates</title>
                    <link rel="self" type="application/atom+xml" href="http://syriaca.org/place/latest-atom.xml"/>
                    <id>tag:syriaca.org,2013:gazetteer-latest</id>
                    <updated>
                        <xsl:value-of select="//tei:TEI[1]/tei:teiHeader/tei:fileDesc/tei:publicationStmt[1]/tei:date[1]"/>
                    </updated>
                    <xsl:apply-templates select="//tei:place"/>
                </feed>
            </xsl:when>
            <xsl:otherwise>
                <feed>
                    <title>
                        temp
                    </title>
                    <link rel="self" type="application/atom+xml" href="http://syriaca.org/place/{tei:idno[@type='placeID']}-atom.xml"/>
                    <id>tag:syriaca.org,2013:<xsl:value-of select="@xml:id"/>
                    </id>
                    <updated>
                        <xsl:value-of select="//tei:TEI[1]/tei:teiHeader/tei:fileDesc/tei:publicationStmt[1]/tei:date[1]"/>
                    </updated>
                    <xsl:apply-templates select="//tei:place" mode="a"/>
                </feed>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="tei:place">
        <xsl:variable name="place-id" select="substring-after(@xml:id,'place-')"/>
        <entry>
            <xsl:value-of select="name()"/>
            <title>Test</title>
            <link rel="alternate" type="text/html" href="http://syriaca.org/place/{$place-id}"/>
            <!-- NOTE: need to establish what uris will look like -->
            <link rel="self" type="application/atom+xml" href="http://syriaca.org/place/{$place-id}-atom.xml"/>
            <!-- NOTE: may want to change id to the place-id -->
            <id>tag:syriaca.org,2013:<xsl:value-of select="@xml:id"/>
            </id>
            <updated>
                <xsl:value-of select="ancestor::tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt[1]/tei:date[1]"/>
            </updated>
            <xsl:if test="tei:desc[contains(@xml:id,'abstract')]">
                <summary>
                    <xsl:apply-templates select="tei:desc[contains(@xml:id,'abstract')]" mode="atom"/>
                </summary>
            </xsl:if>
            <!--
            <xsl:apply-templates select="ancestor::t:titleStmt/t:editor"/>
            <xsl:apply-templates select="ancestor::t:titleStmt/t:respStmt"/>
            <xsl:apply-templates select="t:location[@type='gps']"/>
            -->
        </entry>
    </xsl:template>
    <xsl:template match="tei:desc[contains(@xml:id,'abstract')]" mode="atom">
        <xsl:apply-templates/>
    </xsl:template>
</xsl:stylesheet>