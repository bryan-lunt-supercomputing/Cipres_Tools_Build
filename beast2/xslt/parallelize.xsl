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


<xsl:template match="distribution[@spec='CompoundDistribution' or @spec='util.CompoundDistribution' or @spec='core.util.CompoundDistribution' or @spec='beast.core.util.CompoundDistribution']/@useThreads">
	<xsl:attribute name="useThreads">
		<xsl:value-of select="'false'"/>
	</xsl:attribute>
</xsl:template>

<!-- This was for turning threading on in CompoundDistributions, in that case, I think that it's only the "likelihood" one that we want to turn on
     Now we want to turn it off for the thread safety issue, and in that case we want it off on all of them.
     Once thread-safety is fixed, maybe we'll want to ensure threading is off in most and turn it on only in "likelihood".
     -->
<!--
<xsl:template match="distribution[@id='likelihood']">
	<xsl:copy>
		<xsl:attribute name="useThreads">true</xsl:attribute>
		<xsl:copy-of select="@*" />
		<xsl:apply-templates />
	</xsl:copy>
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

<xsl:template match="run[@spec='PathSampler' or @spec='inference.PathSampler' or @spec='beast.inference.PathSampler']/text()">
	<contact-CIPRES-admins-if-you-absolutely-need-pathsampling>
	Please do not use PathSampler on CIPRES.
	Contact CIPRES administrators if this is absolutely necessary for your science.
	</contact-CIPRES-admins-if-you-absolutely-need-pathsampling>
</xsl:template>

</xsl:stylesheet>
