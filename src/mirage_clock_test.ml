type 'a io = 'a Lwt.t

type tm = Unix.tm = {
  tm_sec : int;
  tm_min : int;
  tm_hour : int;
  tm_mday : int;
  tm_mon : int;
  tm_year : int;
  tm_wday : int;
  tm_yday : int;
  tm_isdst : bool;
}

let gmtime = Unix.gmtime

let src = Logs.Src.create "mirage-clock-test" ~doc:"Mirage test clock"
module Log = (val Logs.src_log src : Logs.LOG)

module Queue = Lwt_pqueue.Make(struct
  type t = (float * unit Lwt.u)
  let compare a b =
    compare (fst a) (fst b)
end)

let schedule = ref Queue.empty
let now = ref 0.0

let time () = !now

let sleep delay =
  assert (delay >= 0.0);
  let result, waker = Lwt.task () in
  schedule := !schedule |> Queue.add (!now +. delay, waker);
  result

let rec run_to t =
  Log.debug (fun f -> f "run_to %.2f\n" t);
  match Queue.lookup_min !schedule with
  | Some (wake_time, w) when wake_time <= t ->
      schedule := !schedule |> Queue.remove_min;
      now := wake_time;
      Log.debug (fun f -> f "time = %.2f (waking)\n" !now);
      Lwt.wakeup w ();
      run_to t
  | _ ->
      now := t;
      Log.debug (fun f -> f "time = %.2f\n" !now)

let reset () =
  schedule := Queue.empty;
  now := 0.0
