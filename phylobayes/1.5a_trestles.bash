#!/bin/bash

######################
### BASIC SETTINGS ###


export PACKAGE="phylobayes"
export VERSION="1.5a"

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

#Get the sourcecode
(cd ${SRCDIR}; wget http://megasun.bch.umontreal.ca/People/lartillot/www/pb_mpi1.5a.tar.gz; tar -zxvof pb_mpi1.5a.tar.gz; )
export SRCDIR=${SRCDIR}/pb_mpi1.5a

#get the license
(cd ${SRCDIR}; wget http://www.gnu.org/licenses/gpl.txt; )

#patch the Makefile
(cd ${SRCDIR};
patch -N  sources/Makefile <<<'
@@ -41,7 +41,7 @@ OBJS=$(patsubst %.cpp,%.o,$(SRCS))
 ALL_SRCS=$(wildcard *.cpp)
 ALL_OBJS=$(patsubst %.cpp,%.o,$(ALL_SRCS))
 
-PROGSDIR=../data
+PROGSDIR=../bin
 ALL= pb_mpi readpb_mpi tracecomp bpcomp bpcomp2
 PROGS=$(addprefix $(PROGSDIR)/, $(ALL))
 
';
)

#build
(cd ${SRCDIR}; mkdir -p bin; rm -f bin/*; make -C sources clean all; )



#The program should be compiled by the end.
}

#########
#Install everyting into ${INSTALL_PREFIX}
#${INSTALL_PREFIX} can be assumed to exist
function install_step () {
cp -r ${SRCDIR}/bin ${INSTALL_PREFIX}
cp -r ${SRCDIR}/gpl.txt ${INSTALL_PREFIX}

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
set     phylobayeshome   ${INSTALL_PREFIX}
setenv  PHYLOBAYES_HOME  \$phylobayeshome
append-path     PATH     \$phylobayeshome/bin
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
