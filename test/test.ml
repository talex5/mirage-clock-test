open Lwt.Infix

module Log = struct
  let messages = ref []

  let info fmt =
    fmt |> Printf.ksprintf @@ fun msg ->
    print_endline msg;
    messages := msg :: !messages

  let collect () =
    let m = List.rev !messages in
    messages := [];
    m

  let expect expected =
    let actual = collect () in
    if actual <> expected then (
      Printf.eprintf "*** FAILURE:\nExpected:\n%s\nGot:\n%s\n"
        (String.concat "\n" expected)
        (String.concat "\n" actual);
      exit 1
    )
end

module App(C : V1.CLOCK)(T : V1_LWT.TIME) = struct
  let rec loop msg delay =
    T.sleep delay >>= fun () ->
    Log.info "[%.2f] %s" (C.time ()) msg;
    loop msg delay

  let main () =
    Lwt.choose [
      loop "fizz" 3.0;
      loop "buzz" 5.0;
    ]
end

module A = App(Mirage_clock_test)(Mirage_clock_test)

let () =
  Lwt_main.run begin
    Mirage_clock_test.reset ();
    Mirage_clock_test.run_to 100.0;   (* Start at time t=100 *)
    (* Start the main thread running. *)
    Lwt.async A.main;
    (* Nothing happens in the first second. *)
    Mirage_clock_test.run_to 101.0;
    Log.expect [];
    (* Lots happens in the first 15 seconds. *)
    Mirage_clock_test.run_to 115.0;
    Log.expect [
      "[103.00] fizz";
      "[105.00] buzz";
      "[106.00] fizz";
      "[109.00] fizz";
      "[110.00] buzz";
      "[112.00] fizz";
      "[115.00] fizz";
      "[115.00] buzz";
    ];
    print_endline "Tests passed!";
    Lwt.return ()
  end
