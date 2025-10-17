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

  <xsl:template match="core:package/@name">
    <xsl:attribute name="name">libnautilus-extension-4</xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
