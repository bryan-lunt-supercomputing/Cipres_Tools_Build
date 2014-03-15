#!/bin/bash

######################
### BASIC SETTINGS ###


export PACKAGE="beagle"
export VERSION="1.1"

export TARGET_MACHINE="gordon"

export BASE_PREFIX="/home/blunt/opt/${TARGET_MACHINE}"
export BASE_MODULE_PREFIX="/home/blunt/.privatemodules/${TARGET_MACHINE}"

#later on, choose the compiler based on the target machine, user can override.
export COMPILER="intel"
export PREREQ_MODULES=""

export INSTALL_PREFIX="${BASE_PREFIX}/${PACKAGE}/${VERSION}"

#######################
### FUNCTIONS FOR EACH STEP ###


########
#The requested modules will be loaded before compilation
#SRCDIR will be available in the environment.
function compilation_step () {
#The user must fetch the sourcecode into SRCDIR
#The user may update SRCDIR to some subdirectory of the original SRCDIR if that is conveninent.

svn co http://beagle-lib.googlecode.com/svn/tags/beagle_release_1_1/ ${SRCDIR}

(cd ${SRCDIR}; 
patch -N -p1 <<<'
diff --git a/configure.ac b/configure.ac
index 03d9546..1524da0 100644
--- a/configure.ac
+++ b/configure.ac
@@ -53,7 +53,7 @@ AC_CONFIG_AUX_DIR(.config)
 AC_CONFIG_MACRO_DIR([m4])
 AC_CONFIG_SRCDIR(libhmsbeagle/beagle.cpp)
 
-AM_INIT_AUTOMAKE($PACKAGE, $VERSION, no-define)
+AM_INIT_AUTOMAKE([no-define])
 
 AC_PROG_CC
 AC_PROG_CXX
@@ -64,7 +64,7 @@ AM_DISABLE_STATIC
 AC_PROG_LIBTOOL
 AM_PROG_LIBTOOL
 
-AM_CONFIG_HEADER(libhmsbeagle/config.h)
+AC_CONFIG_HEADER(libhmsbeagle/config.h)
 
 # needed to support old automake versions
 AC_SUBST(abs_top_builddir)
@@ -108,7 +108,7 @@ AS_IF([test "$enable_openmp" = "yes"], [
 		[AM_CONDITIONAL(HAVE_OPENMP,false)])
 	fi
 ],[
-AM_CONDITIONAL(HAVE_OPENMP, test true = false)
+AM_CONDITIONAL(HAVE_OPENMP,false)
 ])
 AC_SUBST(OPENMP_CFLAGS)
 dnl OpenMP checker only defines for C when compiling both C and C++
@@ -209,8 +209,11 @@ AC_ARG_ENABLE(sse,
 
 SSE_CFLAGS=
 if test  "$enable_sse" = yes; then
+	AM_CONDITIONAL(HAVE_SSE2,true)
 	SSE_CFLAGS+="-DENABLE_SSE"
     AM_CXXFLAGS="$AM_CXXFLAGS -msse2"
+else
+	AM_CONDITIONAL(HAVE_SSE2,false)
 fi
 
 # ------------------------------------------------------------------------------
diff --git a/libhmsbeagle/CPU/BeagleCPUSSEPlugin.cpp b/libhmsbeagle/CPU/BeagleCPUSSEPlugin.cpp
index 1f6bfbd..e4aebc7 100644
--- a/libhmsbeagle/CPU/BeagleCPUSSEPlugin.cpp
+++ b/libhmsbeagle/CPU/BeagleCPUSSEPlugin.cpp
@@ -11,9 +11,13 @@
 #include <iostream>
 
 #ifdef __GNUC__
-#include "cpuid.h"
+	#ifndef __INTEL_COMPILER
+		//ICC also defines __GNUC__ ....
+		#include "cpuid.h"
+	#endif
 #endif
 
+
 namespace beagle {
 namespace cpu {
 
@@ -83,6 +87,7 @@ bool check_sse2(){
 #endif
 
 #ifdef __GNUC__
+#ifndef __INTEL_COMPILER
 bool check_sse2()
 {
   unsigned int eax, ebx, ecx, edx;
@@ -103,14 +108,17 @@ bool check_sse2()
 
 	return false;
 }
-
+#endif
 #endif
 
 
 void* plugin_init(void){
+	#ifndef __INTEL_COMPILER
+	//Trust the guy who uses the intel compiler to know what his CPU supports.
 	if(!check_sse2()){
 		return NULL;	// no SSE no plugin?! 
 	}
+	#endif
 	return new beagle::cpu::BeagleCPUSSEPlugin();
 }
 }
' )

export LC_ALL="en_US"

(cd ${SRCDIR}; libtoolize --force; aclocal; autoheader; automake --force-missing --add-missing; autoconf; sh ./autogen.sh; )

export CC=icc
export CXX=icc
export CFLAGS='-xhost -lstdc++'
export CXXFLAGS='-xhost -lstdc++'

(cd ${SRCDIR}; ./configure --prefix=${INSTALL_PREFIX} --libdir=${INSTALL_PREFIX}/lib --enable-sse=yes --enable-openmp=no )

(cd ${SRCDIR}; make )


#The program should be compiled by the end.
}

#########
#Install everyting into ${INSTALL_PREFIX}
#${INSTALL_PREFIX} can be assumed to exist
function install_step () {

(cd ${SRCDIR}; make install )

}


########
## see http://modules.sourceforge.net/man/modulefile.html for more help writing module files
#MODULE_FILENAME will already be setup properly from BASE_MODULE_PREFIX
function modulefile_step () {
cat > ${MODULE_FILENAME} << EOF
#%Module########################################################################
##
## ${PACKAGE} modulefile
##
proc ModulesHelp { } {
        global version

        puts stderr "   Loads ${PACKAGE}"
        puts stderr "   Version \$version"
}

module-whatis   "${PACKAGE}"
module-whatis   "Version: ${VERSION}"
module-whatis   "Description: ${PACKAGE}"
module-whatis   "Compiler: ${COMPILER}"
prereq ${COMPILER} ${PREREQ_MODULES}
# for Tcl script use only
set     version          ${VERSION}
set     beaglehome   ${INSTALL_PREFIX}
setenv  BEAGLE_HOME  \$beaglehome
setenv  BEAGLE_LIB   \$beaglehome/lib
append-path LD_LIBRARY_PATH \$beaglehome/lib
EOF
}



##################
##################
### The end user should not modify anything below this ###
#####
# By modifying the above functions, you should be able to compile any appropriate code.
# This code may change in future versions.


#do setup
module purge
module load gnubase
module load ${COMPILER} ${PREREQ_MODULES}



#do compilation step
export SRCDIR=${PACKAGE}_${VERSION}_${TARGET_MACHINE}_src
mkdir -p ${SRCDIR}

compilation_step


### INSTALL ###
mkdir -p ${INSTALL_PREFIX}
install_step

#######################
### Create a Module File ###
export MODULE_FILENAME="${BASE_MODULE_PREFIX}/${PACKAGE}/${VERSION}"
mkdir -p $(dirname ${MODULE_FILENAME})
modulefile_step
