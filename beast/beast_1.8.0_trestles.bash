#!/bin/bash

export PACKAGE="beast"
export VERSION="1.8"

export TARGET_MACHINE="trestles"

export BASE_PREFIX="/home/blunt/opt"
export BASE_MODULE_PREFIX="/home/blunt/.privatemodules/${TARGET_MACHINE}"



#later on, choose the compiler based on the target machine, user can override.
export COMPILER="gnu"


export INSTALL_PREFIX="${BASE_PREFIX}/${TARGET_MACHINE}/${PACKAGE}/${VERSION}"
export MODULE_FILENAME="${BASE_MODULE_PREFIX}/${PACKAGE}/${VERSION}"

#######################
### BUILDING STEP ###

export SRCDIR=${PACKAGE}_${VERSION}_${TARGET_MACHINE}_src

module purge
module load gnubase
module load gnu

svn co http://beast-mcmc.googlecode.com/svn/tags/beast_release_1_8_0/ ${SRCDIR}

#fix wrong indentation in makefiles, Make REQUIRES TAB characters
(cd ${SRCDIR}/native; for onemkfile in Makefile*; do unexpand ${onemkfile} > ${onemkfile}.unexpanded; done )

#build native
(cd ${SRCDIR}/native; rm -f *.so *.o; make -f Makefile.amd64.unexpanded;)


#patch the script file to put BEAGLE_LIB on the java.library.path
patch ${SRCDIR}/release/Linux/scripts/beast << EOF
26c26,27
< java -Xms64m -Xmx2048m -Djava.library.path="\$BEAST_LIB:/usr/local/lib" -cp "\$BEAST_LIB/beast.jar:\$BEAST_LIB/beast-beagle.jar" dr.app.beast.BeastMain \$*
---
> BEAGLE_LIB="\$BEAGLE_HOME/lib"
> java -Xms64m -Xmx2048m -Djava.library.path="\$BEAGLE_LIB:\$BEAST_LIB:/usr/local/lib" -cp "\$BEAST_LIB/beast.jar:\$BEAST_LIB/beast-beagle.jar" dr.app.beast.BeastMain \$*
EOF



#build java
(cd ${SRCDIR} ; ant build; )
(cd ${SRCDIR} ; ant dist-all; )
(cd ${SRCDIR} ; ant linux; )

### INSTALL ###
mkdir -p ${INSTALL_PREFIX}
cp -r ${SRCDIR}/release/Linux/BEASTv1.8.0/* ${INSTALL_PREFIX}

#######################
### Create a Module File ###

mkdir -p $(dirname ${MODULE_FILENAME})

cat > ${MODULE_FILENAME} << EOF
#%Module########################################################################
##
## ${PACKAGE} modulefile
##
proc ModulesHelp { } {
        global version

        puts stderr "   Loads beast"
        puts stderr "   Version \$version"
}

module-whatis   "${PACKAGE}"
module-whatis   "Version: ${VERSION}"
module-whatis   "Description: ${PACKAGE}"
module-whatis   "Compiler: ${COMPILER}"
prereq  beagle
# for Tcl script use only
set     version         ${VERSION}
set     beasthome       ${INSTALL_PREFIX}
setenv  BEAST           \$beasthome
setenv  BEAST_HOME      \$beasthome
setenv  BEAST_LIB       \$beasthome/lib
append-path     PATH    \$beasthome/bin
append-path     LD_LIBRARY_PATH \$beasthome/lib
append-path     CLASSPATH       \$beasthome/lib/beast.jar
append-path     CLASSPATH       \$beasthome/lib/beauti.jar
EOF

