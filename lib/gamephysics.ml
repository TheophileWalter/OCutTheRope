(*	GAMEPHYSICS.ML
 *	
 *	Where magic happens.
 *	Physics computations happen here.
 *)

open Basephysics
open Gametypes
open List

let dt = 0.01
let air_friction_coef = 0.001

(* Attraction vector formula *)
let attract obj_pos attr_pos attr_str =
	let pl_to_attr = normalize (obj_pos -.. attr_pos) in
	(attr_str /. (len_of_vec (obj_pos -.. attr_pos) ** 2.)) **. pl_to_attr

(* Computes acceleration for a player given its position and the context *)
let acc_of_context ((pos, _), _, _) ctx =
	fold_left (fun acc c ->
		match c with
		| GravField(a)		-> (a +.. acc)
		| Attractor(xy,str)	-> ((attract pos xy str) +.. acc)
		| _					-> acc
	) (0., 0.) ctx

(* Computes acceleration for a given player given its velocity, position and modifiers *)
let acc_of_player_mod ((pos, _), vel, modifs) =
	let friction = (-1. *. air_friction_coef *. (len_of_vec vel)) **. vel in
	fold_left (fun acc m ->
		match m with
		| Bubbled(a)	-> (a +.. acc)
		| Roped(r)		-> ((handle_rope_collision pos r) +.. acc)
		| _				-> acc
	) friction modifs

(* Computes the speed of a player given a context *)
let vel_of_player player ctx =
	let accel = (acc_of_context player ctx) +.. (acc_of_player_mod player) in
	let (_, vel, m) = player in
	apply_der vel accel dt

(* Handles environment collisions then returns a new player and context. *)
let handle_env_collision player context =
	fold_left (fun (player, nc) elm ->
		let (sph, vel, m) = player in
		match elm with
		| Star(s) when (check_col_ss sph s)										-> ((sph, vel, Point::m), nc)
		| Bubble(s, accel) when (check_col_ss sph s)							-> ((sph, vel, (Bubbled(accel)::m)), nc)
		| Goal(r) when (check_col_corner_sr sph r) || (check_col_wall_sr sph r) -> raise (EndGame(Win))
		| Monster(r) when (check_col_corner_sr sph r) || (check_col_wall_sr sph r) -> raise (EndGame(Die))
		| Wall(r) ->
				let (nsph, nvel) = sr_corner_collide sph r vel in
				let (nnsph, nnvel) = sr_wall_collide nsph r nvel in
				((nnsph, nnvel, m), Wall(r)::nc)
		
				(* When player gets out of the borders. *)
		| _  when let (((px, py),_),_,_) = player in (px < -50. || py < -50. || px > 550. || py > 750.) -> raise (EndGame(Die))
		| _ -> (player, (elm::nc))
	) (player, []) context