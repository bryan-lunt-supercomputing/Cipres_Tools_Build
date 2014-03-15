#!/bin/bash

######################
### BASIC SETTINGS ###


export PACKAGE="garli"
export VERSION="2.01"

export TARGET_MACHINE="trestles"

export BASE_PREFIX="/home/blunt/opt/${TARGET_MACHINE}"
export BASE_MODULE_PREFIX="/home/blunt/.privatemodules/${TARGET_MACHINE}"

#later on, choose the compiler based on the target machine, user can override.
export COMPILER="gnu"
export PREREQ_MODULES="openmpi_ib"

export INSTALL_PREFIX="${BASE_PREFIX}/${PACKAGE}/${VERSION}"

#######################
### FUNCTIONS FOR EACH STEP ###


########
#The requested modules will be loaded before compilation
#SRCDIR will be available in the environment.
function compilation_step () {
#The user must fetch the sourcecode into SRCDIR
#The user may update SRCDIR to some subdirectory of the original SRCDIR if that is conveninent.

#Checkout the code
svn checkout http://garli.googlecode.com/svn/garli/tags/2.01-release/ ${SRCDIR}

#Prepare NCL, we are actually going to link it statically...
(cd ${SRCDIR}; svn checkout http://svn.code.sf.net/p/ncl/code/branches/v2.1/ ncl-svn;)
(cd ${SRCDIR}/ncl-svn; ./bootstrap.sh ; automake --add-missing; ./bootstrap.sh; ./configure --prefix=${PWD}  --with-constfuncs=yes --disable-shared --enable-static; make; make install; )

#build GARLI itself.
(cd ${SRCDIR}; ./bootstrap.sh; automake --add-missing; ./bootstrap.sh; CC='mpicc' CXX='mpic++' ./configure --with-ncl=$PWD/ncl-svn --prefix=${INSTALL_PREFIX} --enable-mpi; make;)


#The program should be compiled by the end.
}

#########
#Install everyting into ${INSTALL_PREFIX}
#${INSTALL_PREFIX} can be assumed to exist
function install_step () {

(cd ${SRCDIR}; make install;)

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
set     garlihome   ${INSTALL_PREFIX}
setenv  GARLI_HOME  \$garlihome
append-path     PATH     \$garlihome/bin
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
