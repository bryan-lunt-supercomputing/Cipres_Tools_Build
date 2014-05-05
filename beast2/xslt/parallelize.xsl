<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="@*|node()">
	<xsl:copy>
		<xsl:apply-templates select="@*|node()"/>
	</xsl:copy>
</xsl:template>

<xsl:template match="distribution[@spec='TreeLikelihood' or @spec='likelihood.TreeLikelihood' or @spec='evolution.likelihood.TreeLikelihood' or @spec='beast.evolution.likelihood.TreeLikelihood']/@spec">
	<xsl:attribute name="spec">
		<xsl:value-of select="'beast.evolution.likelihood.ThreadedTreeLikelihood'"/>
	</xsl:attribute>
</xsl:template>

<!--
<xsl:template match="distribution[@spec='CompoundDistribution' or @spec='util.CompoundDistribution']/">
	<xsl:attribute name="useThreads">
		<xsl:value-of select="'true'"/>
	</xsl:attribute>
</xsl:template>
-->

<!-- You can just replace the content of this template with the appropriate script to run ParticleFilter -->
<!-- See http://www.beast2.org/wiki/index.php/Performance_Suggestions#Particle_Filter -->
<xsl:template match="run[@spec='ParticleFilter' or @spec='inference.ParticleFilter' or @spec='beast.inference.ParticleFilter']/text()">
	<contact-CIPRES-admins-if-you-absolutely-need-particlefilter>
	Please do not use ParticleFilter on CIPRES.
	Contact CIPRES administrators if this is absolutely necessary for your science.
	</contact-CIPRES-admins-if-you-absolutely-need-particlefilter>
</xsl:template>

</xsl:stylesheet>
