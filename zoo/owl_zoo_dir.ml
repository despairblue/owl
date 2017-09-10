(*
 * OWL - an OCaml numerical library for scientific computing
 * Copyright (c) 2016-2017 Liang Wang <liang.wang@cl.cam.ac.uk>
 *)


let rec _extract_zoo_gist f =
  let s = Owl.Utils.read_file_string f in
  let regex = Str.regexp "#zoo \"\\([0-9A-Za-z]+\\)\"" in
  try
    let pos = ref 0 in
    while true do
      pos := Str.search_forward regex s !pos;
      let gist = Str.matched_group 1 s in
      pos := !pos + (String.length gist);
      process_dir_zoo gist
    done
  with Not_found -> ()


and _deploy_gist dir gist =
  if Sys.file_exists (dir ^ gist) = true then (
    Log.info "owl_zoo: %s cached" gist
  )
  else (
    Log.info "owl_zoo: %s missing" gist;
    Owl_zoo_cmd.download_gist gist
  )


and _dir_zoo_ocaml dir gist =
  let dir_gist = dir ^ gist in
  Sys.readdir (dir_gist)
  |> Array.to_list
  |> List.filter (fun s -> Filename.check_suffix s "ml")
  |> List.iter (fun l ->
      let f = Printf.sprintf "%s/%s" dir_gist l in
      _extract_zoo_gist f;
      Toploop.mod_use_file Format.std_formatter f
      |> ignore
    )


and process_dir_zoo gist =
  let dir = Sys.getenv "HOME" ^ "/.owl/zoo/" in
  _deploy_gist dir gist;
  _dir_zoo_ocaml dir gist


and add_dir_zoo () =
  let section = "owl" in
  let doc =
    "owl's zoo system\n" ^
    "ditribute code snippet via gist\n"
  in
  let info = Toploop.({ section; doc }) in
  let dir_fun = Toploop.Directive_string process_dir_zoo in
  Toploop.add_directive "zoo" dir_fun info


(* register zoo directive *)
let _ = add_dir_zoo ()
