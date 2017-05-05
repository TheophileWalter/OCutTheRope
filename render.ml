(*  RENDER.ML
 *  
 *  Where magic shows up.
 *  Rendering happens here.
 *)

open Graphics
open Ppm
open Level
open Gametypes

let () = 
    (* Open a graphic window with the size depending on the running programm *)
    if (String.sub Sys.executable_name 2 6) = "editor" then
        open_graph " 620x700"
    else
        open_graph " 500x700";
    (* Enable double buffering, use "synchronize()" to update window *)
    auto_synchronize false

(* Load pictures *)
let background =
    image_from_ppm "sprites/background.ppm"
let player_sprite =
    image_from_ppm "sprites/player.ppm"
let bubble_sprite =
    image_from_ppm "sprites/bubble.ppm"
let star_sprite =
    image_from_ppm "sprites/star.ppm"
let goal_sprite =
    image_from_ppm "sprites/goal.ppm"
let monster_sprite =
    image_from_ppm "sprites/monster.ppm"
let wall_sprite =
    image_from_ppm "sprites/wall.ppm"
let attractor_sprite =
    image_from_ppm "sprites/attractor.ppm"
let unknow_sprite =
    image_from_ppm "sprites/unknow.ppm"

(* Simple function to draw a single element *)
let draw_single_element element =
    match element with
    | Player(((posX, posY), radius), _, _) -> draw_image player_sprite    (int_of_float (posX-.radius)) (int_of_float (posY-.radius))
    | Goal((posX, posY), _)                -> draw_image goal_sprite      (int_of_float posX) (int_of_float posY)
    | Star((posX, posY), radius)           -> draw_image star_sprite      (int_of_float (posX-.radius)) (int_of_float (posY-.radius))
    | Bubble(((posX, posY), radius), _)    -> draw_image bubble_sprite    (int_of_float (posX-.radius)) (int_of_float (posY-.radius))
    | Attractor((posX, posY), _)           -> draw_image attractor_sprite (int_of_float (posX-.25.)) (int_of_float (posY-.25.))
    | Wall((posX, posY), _)                -> draw_image wall_sprite      (int_of_float posX) (int_of_float posY)
    | Monster((posX, posY), _)             -> draw_image monster_sprite   (int_of_float posX) (int_of_float posY)
    | _                                    -> ()


(* Just call this function to draw the level
 * @params
 *   level of context : the level
 *   sync  of bool    : true to synchronize, false to don't
 *)
let draw_level level sync =
    (* Clear old drawing *)
    clear_graph();
    (* Draw background *)
    draw_image background 0 0;
    (* Internal function to draw the elements of a gameElement list *)
    let rec draw_elements elementsList =
        match elementsList with
        | [] -> ()
        | t::q -> draw_single_element t; draw_elements q;
    in
    draw_elements level;
    if sync then synchronize()
