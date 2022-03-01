# Simple makefile for things relating to OpenSCAD
.PHONY: all clean

mainfile=chorder.scad
base=$(shell basename $(shell pwd) )

partnames=$(shell sed -rn 's|^//\s*_partname_values ||;tp;b;:p p' $(mainfile) )
outputfiles=$(shell echo $(partnames) | tr ' ' '\n' |  sed -r 's|.*|$(base)_part_&.stl|g' )

all: $(outputfiles)
clean:
	@rm -f *.stl

%.stl: $(mainfile)
	openscad $(shell echo "$@" | sed -re "s/.*_part_([^-.]+).*/ -D'partname=\"\1\"'/") -o $@ $<
