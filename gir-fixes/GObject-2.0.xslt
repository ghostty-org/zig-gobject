<?xml version="1.0"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:core="http://www.gtk.org/introspection/core/1.0"
	xmlns:c="http://www.gtk.org/introspection/c/1.0"
	xmlns:glib="http://www.gtk.org/introspection/glib/1.0"
	version="1.0">

  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="core:record[@name='WeakRef']/core:method[@name='get']/core:return-value">
     <xsl:copy>
       <xsl:attribute name="nullable">1</xsl:attribute>
       <xsl:copy-of select="@* | node()"/>
     </xsl:copy>
   </xsl:template>

</xsl:stylesheet>

