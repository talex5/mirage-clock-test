include V1.CLOCK
include V1_LWT.TIME

val run_to : float -> unit
(** [run_to t] runs the event loop until virtual time [t]. *)

val reset :  unit -> unit
(** [reset ()] sets the virtual time to zero and clears any scheduled events. *)
