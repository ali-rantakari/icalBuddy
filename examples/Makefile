


COMPILER_GCC="gcc"
COMPILER_CLANG="/Developer/usr/bin/clang"
COMPILER=$(COMPILER_CLANG)


all: examples

#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# compile tool for generating HTML from command output
#-------------------------------------------------------------------------
cmdStdoutToHTML: cmdStdoutToHTML.m
	@echo
	@echo ---- Compiling cmdStdoutToHTML:
	@echo ======================================
	$(COMPILER) -Wall -std=c99 -arch i386 -framework Cocoa -o $@ cmdStdoutToHTML.m ../ANSIEscapeHelper.m ../HGCLIUtils.m ../HGUtils.m


FontList.swf: FontList.as
	@echo
	@echo ---- Compiling FontList.swf:
	@echo ======================================
	$(FLEX_HOME)/bin/mxmlc -strict=true FontList.as


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# generate usage examples HTML
#-------------------------------------------------------------------------
examples.html: cmdStdoutToHTML FontList.swf examples.markdown generateExamplesHTML.py
	@echo
	@echo ---- Running examples HTML generator:
	@echo ======================================
	./generateExamplesHTML.py > examples.html

examples: examples.html



exampleCommandOutputs.plist: generateExamplesOutput.py
	@echo
	@echo ---- Running example command output generator:
	@echo ======================================
	./generateExamplesOutput.py



#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
clean:
	@echo
	@echo ---- Cleaning up:
	@echo ======================================
	-rm -Rf examples.html
	-rm -Rf cmdStdoutToHTML
	-rm -Rf cmdStdoutToPNG
	-rm -Rf FontList.swf


