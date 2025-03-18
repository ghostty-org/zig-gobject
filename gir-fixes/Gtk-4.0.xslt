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
  <xsl:template match="core:class[@name='IMContext']/core:virtual-method[@name='get_preedit_string']/core:parameters/core:parameter[@name='str'] |
                       core:class[@name='IMContext']/core:virtual-method[@name='get_preedit_string']/core:parameters/core:parameter[@name='attrs'] |
                       core:class[@name='IMContext']/core:virtual-method[@name='get_preedit_string']/core:parameters/core:parameter[@name='cursor_pos']">
     <xsl:copy>
       <xsl:attribute name="nullable">1</xsl:attribute>
       <xsl:copy-of select="@* | node()"/>
     </xsl:copy>
  </xsl:template>
  <xsl:template match="core:method[@c:identifier='gtk_im_context_get_preedit_string']/core:parameters/core:parameter[@name='str'] |
                       core:method[@c:identifier='gtk_im_context_get_preedit_string']/core:parameters/core:parameter[@name='attrs'] |
   					   core:method[@c:identifier='gtk_im_context_get_preedit_string']/core:parameters/core:parameter[@name='cursor_pos']">
     <xsl:copy>
       <xsl:attribute name="nullable">1</xsl:attribute>
       <xsl:copy-of select="@* | node()"/>
     </xsl:copy>
   </xsl:template>
   <xsl:template match="core:method[@c:identifier='gtk_application_set_accels_for_action']/core:parameters/core:parameter[@name='accels']">
     <xsl:copy>
       <xsl:attribute name="nullable">1</xsl:attribute>
       <xsl:apply-templates select="@* | node()"/>
     </xsl:copy>
   </xsl:template>
   <xsl:template match="core:method[@c:identifier='gtk_application_set_accels_for_action']/core:parameters/core:parameter[@name='accels']/core:array">
     <xsl:copy>
       <xsl:attribute name="zero-terminated">1</xsl:attribute>
       <xsl:copy-of select="@* | node()"/>
     </xsl:copy>
   </xsl:template>
</xsl:stylesheet>
