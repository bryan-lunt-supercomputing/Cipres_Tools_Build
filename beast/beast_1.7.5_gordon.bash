#!/bin/bash

export INSTALLPREFIX=/opt/beast/1.7.5
export BEAGLE_HOME=/opt/beagle/1.1

source /etc/profile.d/modules.sh

module load gnubase
module load intel

#Patch some run scripts and the makefile (Maybe not really important)
patch -N -p1 <<<'
diff --git a/release/Linux/scripts/beast b/release/Linux/scripts/beast
index ac37679..380d07d 100755
--- a/release/Linux/scripts/beast
+++ b/release/Linux/scripts/beast
@@ -22,5 +22,6 @@ if [ -z "$BEAST" ]; then
        cd "$saveddir"
 fi
 
+BEAGLE_LIB="${BEAGLE_HOME}/lib"
 BEAST_LIB="$BEAST/lib"
-java -Xms64m -Xmx1024m -Djava.library.path="$BEAST_LIB:/usr/local/lib" -cp "$BEAST_LIB/beast.jar:$BEAST_LIB/beast-beagle.jar" dr.app.beast.BeastMain $*
+java -Xms64m -Xmx1024m -Djava.library.path="${BEAGLE_LIB}:$BEAST_LIB:/usr/local/lib" -cp "$BEAST_LIB/beast.jar:$BEAST_LIB/beast-beagle.jar" dr.app.beast.BeastMain $*
'

cat > native/Makefile.icc <<<'CC=icc
CFLAGS=-O3 -xhost -fPIC
INCLUDES=-I${JAVA_HOME}/include/ -I${JAVA_HOME}/include/linux

all: libAminoAcidLikelihoodCore.so  libGeneralLikelihoodCore.so  libNativeMemoryLikelihoodCore.so  libNativeSubstitutionModel.so  libNucleotideLikelihoodCore.so

%.o: %.c
	${CC} ${CFLAGS} ${INCLUDES} -c $< -o $@


lib%.so: %.o
	${CC} -shared ${CFLAGS} -o $@ $<

clean:
	rm *.so *.o
'

#Make Autoreconf work
export LC_ALL="en_US"

#Make sure we link against the selected version of beagle.
export LD_LIBRARY_PATH=${BEAGLE_HOME}/lib:${LD_LIBRARY_PATH}
export LIBPATH=${BEAGLE_HOME}/lib:${LD_LIBRARY_PATH}

#Compilation for gordon/trestles.
export CC=icc
export CXX=icc
export CFLAGS="-xhost"
export CXXFLAGS="-xhost"

(cd native; make -f Makefile.icc clean; make -f Makefile.icc;)

ant linux

#INSTALLATION
mkdir -p ${INSTALLPREFIX}
cp -r release/Linux/BEASTv1.7.5/* ${INSTALLPREFIX}
