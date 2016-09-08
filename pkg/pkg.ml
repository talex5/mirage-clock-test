#!/usr/bin/env ocaml
#use "topfind"
#require "topkg"
open Topkg

let build_with_visible_warnings c os =
  let ocamlbuild = Conf.tool "ocamlbuild" os in
  let build_dir = Conf.build_dir c in
  let debug = Cmd.(on (Conf.debug c) (v "-tag" % "debug")) in
  let profile = Cmd.(on (Conf.profile c) (v "-tag" % "profile")) in
  Cmd.(ocamlbuild % "-use-ocamlfind" %% debug %% profile % "-build-dir" % build_dir)

let cmd c os files =
  OS.Cmd.run @@ Cmd.(build_with_visible_warnings c os %% of_list files)

let () =
  Pkg.describe "mirage-clock-test"
    ~change_logs:[]
    ~build:(Pkg.build ~cmd ())
  @@ fun c ->
  Ok [
    Pkg.mllib "src/mirage-clock-test.mllib";
    Pkg.test "test/test";
  ]
