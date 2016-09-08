# mirage-clock-test

An implementation of Mirage's CLOCK and TIME types for unit-tests.

It is often useful to test code that uses `sleep` to implement timeouts or delays.
Running with the real clock makes the tests run unnecessarily slow.
`Mirage_clock_test` provides a clock that is under the control of the unit-tests and is independent of any real clock.

The `test/test.ml` file contains a simple example.
The `App` module represents the application being tested.
It runs two Lwt loops in parallel.
One logs "fizz" every three seconds, the other logs "buzz" every five seconds.

```
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
```

The test code applies this to `Mirage_clock_test`, then uses the control functions `reset` and `run_to` to control the virtual clock:

```
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
    (* Lots happens in the first 14 seconds. *)
    Mirage_clock_test.run_to 114.0;
    Log.expect [
      "[103.00] fizz";
      "[105.00] buzz";
      "[106.00] fizz";
      "[109.00] fizz";
      "[110.00] buzz";
      "[112.00] fizz";
    ];
    print_endline "Tests passed!";
    Lwt.return ()
end
```

Note that we stop before 15s.
At that point both events fire at once and so the log messages could appear in either order.
It's helpful to arrange your test events to happen at different times to avoid having to handle multiple cases.

This code is based on the code used for [CueKeeper's unit tests](https://github.com/talex5/cuekeeper/blob/ce81f4e3c40b79d99ac4063d22cfba4cd568e7e5/tests/test.ml#L27).
