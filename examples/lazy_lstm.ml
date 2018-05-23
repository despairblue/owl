#!/usr/bin/env owl
(* This example demonstrates using lazy functor to train a LSTM network. *)

#zoo "217ef87bc36845c4e78e398d52bc4c5b"

open Owl
module L = Owl_lazyy.Make (Dense.Ndarray.S)
include Owl_algodiff_generic.Make (L)
include Owl_neural_generic.Make (L)
open Graph


let prepare window step =
  Owl_log.info "build vocabulary and tokenise ...";
  let chars = load_file ~gist:"217ef87bc36845c4e78e398d52bc4c5b" "wonderland.txt" |> String.lowercase_ascii in
  let vocab = Nlp.Vocabulary.build_from_string ~alphabet:true chars in
  let t_arr = Nlp.Vocabulary.tokenise vocab chars |> Array.map float_of_int in
  let tokens = Dense.Ndarray.S.of_array t_arr [| Array.length t_arr |] in

  Owl_log.info "construct x (sliding) and y (one-hot) ...";
  let x = Dense.Ndarray.S.slide ~step:1 ~window tokens in
  let y = Dense.Ndarray.S.(one_hot (Nlp.Vocabulary.length vocab) tokens.${[[window;-1]]}) in

  Owl_log.info "chars:%i, symbols:%i, wndsz:%i, stepsz:%i"
    (String.length chars) (Nlp.Vocabulary.length vocab) window step;
  vocab, x, y


let make_network wndsz vocabsz =
  input [|wndsz|]
  |> embedding vocabsz 40
  |> lstm 128
  |> linear 512 ~act_typ:Activation.Relu
  |> linear vocabsz ~act_typ:Activation.(Softmax 1)
  |> get_network


let train () =
  let wndsz = 100 and stepsz = 1 in
  let vocab, x, y = prepare wndsz stepsz in
  let vocabsz = Nlp.Vocabulary.length vocab in

  let network = make_network wndsz vocabsz in
  Graph.print network;
  let params = Params.config
    ~batch:(Batch.Mini 100) ~learning_rate:(Learning_Rate.Adagrad 0.01) 50.
  in
  train ~params network (L.pack_arr x) (L.pack_arr y) |> ignore


let _ = train ()
