#!/bin/bash

export PACKAGE="phylobayes"
export VERSION="1.5a"

export TARGET_MACHINE="gordon"

export BASE_PREFIX="/home/blunt/opt"
export BASE_MODULE_PREFIX="/home/blunt/.privatemodules/${TARGET_MACHINE}"



#later on, choose the compiler based on the target machine, user can override.
export COMPILER="intel"


export INSTALL_PREFIX="${BASE_PREFIX}/${TARGET_MACHINE}/${PACKAGE}/${VERSION}"
export MODULE_FILENAME="${BASE_MODULE_PREFIX}/${PACKAGE}/${VERSION}"

#######################
### BUILDING STEP ###

export SRCDIR=${PACKAGE}_${VERSION}_${TARGET_MACHINE}_src
mkdir -p ${SRCDIR}

module purge
module load gnubase
module load intel
module load openmpi_ib

#Get the sourcecode
(cd ${SRCDIR}; wget http://megasun.bch.umontreal.ca/People/lartillot/www/pb_mpi1.5a.tar.gz; tar -zxvof pb_mpi1.5a.tar.gz; )
export SRCDIR=${SRCDIR}/pb_mpi1.5a

#get the license
(cd ${SRCDIR}; wget http://www.gnu.org/licenses/gpl.txt; )

#patch the Makefile
(cd ${SRCDIR};
patch -N  sources/Makefile <<<'
@@ -1,5 +1,5 @@
 CC=mpic++
-CPPFLAGS= -w -O3 -c
+CPPFLAGS= -xavx -c
 LDFLAGS= -O3
 SRCS=  TaxonSet.cpp Tree.cpp Random.cpp SequenceAlignment.cpp CodonSequenceAlignment.cpp \
        StateSpace.cpp CodonStateSpace.cpp ZippedSequenceAlignment.cpp SubMatrix.cpp \
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



### INSTALL ###
mkdir -p ${INSTALL_PREFIX}
cp -r ${SRCDIR}/bin ${INSTALL_PREFIX}
cp -r ${SRCDIR}/gpl.txt ${INSTALL_PREFIX}


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

        puts stderr "   Loads ${PACKAGE}"
        puts stderr "   Version \$version"
}

module-whatis   "${PACKAGE}"
module-whatis   "Version: ${VERSION}"
module-whatis   "Description: ${PACKAGE}"
module-whatis   "Compiler: ${COMPILER}"
prereq intel openmpi_ib
# for Tcl script use only
set     version          ${VERSION}
set     \$phylobayeshome ${INSTALL_PREFIX}
setenv  PHYLOBAYES_HOME  \$phylobayeshome
append-path     PATH     \$phylobayeshome/bin
EOF

