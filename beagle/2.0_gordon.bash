#!/bin/bash

######################
### BASIC SETTINGS ###


export PACKAGE="beagle"
export VERSION="2.0"

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

export LC_ALL="en_US"

svn checkout http://beagle-lib.googlecode.com/svn/tags/beagle_release_2_0/ ${SRCDIR}

(cd ${SRCDIR} ; ./autogen.sh; )

export CC=icc
export CXX=icc
export CFLAGS='-xhost -I/opt/gnu/include'
export CXXFLAGS='-xhost -I/opt/gnu/include'

(cd ${SRCDIR} ; ./configure --prefix=${INSTALL_PREFIX} --libdir=${INSTALL_PREFIX}/lib --enable-sse=yes --enable-openmp=no)
(cd ${SRCDIR} ; make )


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
set     beaglehome    ${INSTALL_PREFIX}
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
