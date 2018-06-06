<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:t="http://www.tei-c.org/ns/1.0" xmlns:x="http://www.w3.org/1999/xhtml" xmlns:saxon="http://saxon.sf.net/" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:local="http://syriaca.org/ns" exclude-result-prefixes="xs t x saxon local" version="2.0">
    <!-- ==================================================================
        Builds custom collation rules 
        ================================================================== -->
    <!--
    <xsl:variable name="mixed-rules" select="'< a,A < b,B < c,C < d,D < e,E < f,F < g,G < h,H < i,I < j,J < k,K < l,L < m,M < n,N < o,O < p,P < q,Q < r,R < s,S < t,T < u,U < v,V < w,W < x,X < y,Y < z,Z & OE = Œ & oe = œ & a = ẵ & A = Ẵ & e = ễ & E = Ễ & a = ằ & A = Ằ & d = đ & D = Đ & a = ā & A = Ā & s = š & S = Š & u = ū & U = Ū & h = ḥ & H = Ḥ & s = ṣ & S = Ṣ & t = ṭ & T = Ṭ & i = ī & I = Ī'"/>
    <xsl:variable name="mixed" select="concat('http://saxon.sf.net/collation?rules=',encode-for-uri($mixed-rules),';ignore-case=yes;ignore-modifiers=yes;ignore-symbols=yes')"/>
    <xsl:variable name="lang-rules" select="'< syr < ar < en & en=fr & en=de'"/>
    <xsl:variable name="languages" select="concat('http://saxon.sf.net/collation?rules=',encode-for-uri($lang-rules),';ignore-case=yes;ignore-modifiers=yes;ignore-symbols=yes')"/>
    -->
    <!-- Saxon:collation is a depreciated function and does not seem to work with eXist 2.0-->
    <!--
    <saxon:collation name="mixed" rules="'< a,A < b,B < c,C < d,D < e,E < f,F < g,G < h,H < i,I < j,J < k,K < l,L < m,M < n,N < o,O < p,P < q,Q < r,R < s,S < t,T < u,U < v,V < w,W < x,X < y,Y < z,Z & OE = Œ & oe = œ & a = ẵ & A = Ẵ & e = ễ & E = Ễ & a = ằ & A = Ằ & d = đ & D = Đ & a = ā & A = Ā & s = š & S = Š & u = ū & U = Ū & h = ḥ & H = Ḥ & s = ṣ & S = Ṣ & t = ṭ & T = Ṭ & i = ī & I = Ī'" ignore-case="yes" ignore-modifiers="yes" ignore-symbols="yes"/>
    <saxon:collation name="languages" rules="< syr < ar < en & en=fr & en=de" ignore-case="yes" ignore-modifiers="yes" ignore-symbols="yes"/>
   
        <xsl:variable name="mixed-rules">
        <![CDATA[
        '','al-','ʿ','''
        < a,A < b,B < c,C < d,D < e,E < f,F < g,G < h,H < i,I < j,J < k,K 
        < l,L < m,M < n,N < o,O < p,P < q,Q < r,R < s,S < t,T < u,U < v,V 
        < w,W < x,X < y,Y < z,Z & OE = Œ & oe = œ & a = ẵ & A = Ẵ & e = ễ & E = Ễ & a = ằ & A = Ằ & 
        d = đ & D = Đ & a = ā & A = Ā & s = š & S = Š & u = ū & U = Ū & h = ḥ & 
        H = Ḥ & s = ṣ & S = Ṣ & t = ṭ & T = Ṭ & i = ī & I = Ī & ō = o
        ]]>
    </xsl:variable>
    -->
</xsl:stylesheet>