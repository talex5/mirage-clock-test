.PHONY: all test clean

bin:
	ocaml pkg/pkg.ml build

test: bin
	ocaml pkg/pkg.ml test

clean:
	ocaml pkg/pkg.ml clean
