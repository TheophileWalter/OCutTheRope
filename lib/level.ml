(*	LEVEL.ML
 *	
 *	Where magic is loaded and stored.
 *	Levels are loaded and stored here (Will be used for the editor).
 *)

open Str
open String
open Gametypes

(* The regular expression to match the object in a line *)
let regExpFloat =
	"\\(\\-?[0-9]+\\.[0-9]*\\)"
(* Types from basephysics.ml *)
let regExpPos =
	"\\((" ^ regExpFloat ^ "," ^ regExpFloat ^ ")\\)"
let regExpVel = regExpPos
let regExpAccel = regExpPos
let regExpSize = regExpPos
let regExpDim = regExpPos
let regExpMass = regExpFloat
let regExpLength = regExpFloat
let regExpSphere =
	"\\((" ^ regExpPos ^ "," ^ regExpLength ^ ")\\)"
let regExpRect =
	"\\((" ^ regExpPos ^ "," ^ regExpSize ^ ")\\)"
let regExpRope =
	"\\((" ^ regExpPos ^ "," ^ regExpLength ^ "," ^ regExpFloat ^ ")\\)"
(* Types from gametypes.ml *)
let regExpBubbled =
	"\\(Bubbled(" ^ regExpAccel ^ ")\\)"
let regExpRoped =
	"\\(Roped(" ^ regExpRope ^ ")\\)"
let regExpPoint =
	"\\(Point\\)"
let regExpModifier =
	"\\(" ^ regExpBubbled ^ "\\|" ^ regExpRoped ^ "\\|" ^ regExpPoint ^  "\\)"
let regExpModifiersInner =
	"\\(" ^ regExpModifier ^ "\\(;" ^ regExpModifier ^ "\\)*" ^ "\\)?"
let regExpModifiers =
	"\\(\\[" ^ regExpModifiersInner ^ "?\\]\\)"
let regExpPlayer =
	"\\(Player(" ^ regExpSphere ^ "," ^ regExpVel ^ "," ^ regExpModifiers ^ ")\\)"
let regExpGoal =
	"\\(Goal(" ^ regExpRect ^ ")\\)"
let regExpGravField =
	"\\(GravField(" ^ regExpAccel ^ ")\\)"
let regExpStar =
	"\\(Star(" ^ regExpSphere ^ ")\\)"
let regExpBubble =
	"\\(Bubble(" ^ regExpSphere ^ "," ^ regExpAccel ^ ")\\)"
let regExpAttractor =
	"\\(Attractor(" ^ regExpPos ^ "," ^ regExpFloat ^ ")\\)"
let regExpWall =
	"\\(Wall(" ^ regExpRect ^ ")\\)"
let regExpMonster =
	"\\(Monster(" ^ regExpRect ^ ")\\)"
let regExpRopeMaker =
	"\\(RopeMaker(" ^ regExpSphere ^ "," ^ regExpRope ^ ")\\)"
(* Match any gameObject *)
let regExpGameObject =
	"^\\(" ^
		regExpPlayer ^ "\\|" ^
		regExpGoal ^ "\\|" ^
		regExpGravField ^ "\\|" ^
		regExpStar ^ "\\|" ^
		regExpBubble ^ "\\|" ^
		regExpAttractor ^ "\\|" ^
		regExpWall ^ "\\|" ^
		regExpMonster ^ "\\|" ^
		regExpRopeMaker ^
	"\\)$"
let regExpLine = regexp regExpGameObject

(* Prints the groups mathced by the last regexp 
 * Warning: Always raise a uncaught exception! 
 *          Use only for dubugging.
 *)
let rec print_groups str n =
	Printf.printf "print_groups:%s\n" (matched_group n str);
	print_groups str (n+1)

(* Check if a string contains a substring *)
let contains s1 s2 =
	let re = Str.regexp_string s2 in
	try ignore (Str.search_forward re s1 0); true
	with Not_found -> false

(* Return the position of an object *)
let objectPosition o =
	match o with
	| Player((((x, y), _), _, _))
	| Star(((x, y), _))
	| Attractor((x, y), _)
	| Bubble(((x, y), _), _)
	| Goal(((x, y), _))
	| Wall(((x, y), _))
	| Monster(((x, y), _))
	| RopeMaker(((x, y), _), _)  -> (int_of_float x, int_of_float y)
	| _                          -> (0, 0)

(* Update the position of a gameObject *)
let updatePosition o x y =
	match o with
	| Player(((_, a), b, c))       -> Player((((x, y), a), b, c))
	| Star((_, a))                 -> Star(((x, y), a))
	| Attractor(_, a)              -> Attractor((x, y), a)
	| Bubble((_, a), b)            -> Bubble(((x, y), a), b)
	| Goal((_, a))                 -> Goal(((x, y), a))
	| Wall((_, a))                 -> Wall(((x, y), a))
	| Monster((_, a))              -> Monster(((x, y), a))
	| RopeMaker((_, a), (_, b, c)) -> RopeMaker(((x, y), a), ((x, y) ,b, c))
	| _                            -> o

(* Detect if a point is in an given game object *)
let pointIsInObject pointX pointY o =
	let pX = float_of_int pointX in
	let pY = float_of_int pointY in
	match o with
	| Player((((x, y), radius), _, _))   
	| Star(((x, y), radius))             
	| Bubble(((x, y), radius), _)        -> sqrt((pX-.x)**2. +. (pY-.y)**2.) <= radius
	| Attractor((x, y), _)               -> sqrt((pX-.x)**2. +. (pY-.y)**2.) <= 25. (* Attractor has only the size of its sprite *)
	| Goal(((x, y), (width, height)))
	| Wall(((x, y), (width, height)))
	| Monster(((x, y), (width, height))) -> pX >= x && pX <= (x +. width) && pY >= y && pY <= (y +. height)
	| RopeMaker(((x, y), radius), _)     -> sqrt((pX-.x)**2. +. (pY-.y)**2.) <= radius
	| _                                  -> false

(* Remove an object from a level *)
let removeFromLevel obj level =
	List.filter (fun e -> e <> obj) level

(* Remove a modifier from a list *)
let removeModifier m modifierList =
	List.filter (fun e -> e <> m) modifierList

(* Get the player of a level *)
let getPlayer level =
	List.find (fun e -> match e with | Player(_) -> true | _ -> false) level

(* Check for Bubbled in a list *)
let rec checkBubled m =
	match m with
	| Bubbled(_)::_ -> true
	| _::q          -> checkBubled q
	| []            -> false

(* Return the number of stars of the player *)
let getScore m =
	let rec countStars l acc =
		match l with
		| Point::q -> countStars q (acc+1)
		| _::q     -> countStars q acc
		| []       -> acc
	in
	countStars m 0

(* Return an array of string representing the result of matched_group for a given regexp *)
let get_matched_groups exp str =
	(* Match the string for using matched_group *)
	if string_match exp str 0 then begin
		(* Reccursive function who build the array *)
		let rec gmg str arr n =
			try
				gmg str (Array.append arr [|matched_group n str|]) (n+1)
			with
			| Not_found -> arr
			| Invalid_argument(_) -> arr
		in
		(* We put an element in the array so the indice will match with matched_group's indice *)
		gmg str [|""|] 1
	end else [||]

(* Print a string array *)
let print_array arr =
	print_string "[|\n";
	Array.iter (fun s -> print_string ("	" ^ s ^ "\n")) arr;
	print_string "|]\n"

exception UnknowModifier
exception UnknowGameObject

(* Returns a modifiers list from a text *)
let rec loadModifiers str =
	if (length str) = 0 then
		[]
	else begin
		(* Check if match *)
		if not (string_match (regexp regExpModifiersInner) str 0) then
			failwith ("loadModifiers: Given string is not a corret modifier list! \"" ^ str ^ "\"");
		(* Get the current modifier and its informations *)
		let modifiersGroups = get_matched_groups (regexp regExpModifiersInner) str in
		let currentModifier = modifiersGroups.(2) in
		let currentModifierLen = (length currentModifier) in
		let nextModifierLen = ((length str) - currentModifierLen - 1) in
		let nextModifier = if nextModifierLen <= 0 then "" else (sub str (currentModifierLen + 1) nextModifierLen) in
		(* Match the modifier *)
		match (sub str 0 1) with
		| "B" -> let bubbledGroups = get_matched_groups (regexp regExpBubbled) str in
				(loadModifiers nextModifier)@
				[Bubbled(((float_of_string bubbledGroups.(3)),(float_of_string bubbledGroups.(4))))]
		| "R" -> let ropedGroups = get_matched_groups (regexp regExpRoped) str in
				(loadModifiers nextModifier)@
				[Roped(((float_of_string ropedGroups.(4)),(float_of_string ropedGroups.(5))),(float_of_string ropedGroups.(6)),(float_of_string ropedGroups.(7)))]
		| "P" -> (loadModifiers nextModifier)@
				[Point]
		| _   -> raise UnknowModifier
	end

(*	Object loading *)
let loadObject str =
	(* Check the string *)
	if not (string_match regExpLine str 0) then
		failwith ("loadObject: Given string is not a correct game object! \"" ^ str ^ "\"");
	(* Match the object *)
	match (sub str 0 2) with
	| "Pl" -> let playGroups = get_matched_groups (regexp regExpPlayer) str in
				Player (
					(((float_of_string playGroups.(4)), (float_of_string playGroups.(5))), (float_of_string playGroups.(6))),
					((float_of_string playGroups.(8)), (float_of_string playGroups.(9))),
					(if (Array.length playGroups) >= 12 then loadModifiers playGroups.(11) else [])
				)
	| "Go" -> let goalGroups = get_matched_groups (regexp regExpGoal) str in
				Goal(
					((float_of_string goalGroups.(4)),(float_of_string goalGroups.(5))),
					((float_of_string goalGroups.(7)),(float_of_string goalGroups.(8)))
				)
	| "Gr" -> let gravFieldGroups = get_matched_groups (regexp regExpGravField) str in
				GravField(((float_of_string gravFieldGroups.(3)),(float_of_string gravFieldGroups.(4))))
	| "St" -> let starGroups = get_matched_groups (regexp regExpStar) str in
				Star(((float_of_string starGroups.(4)),(float_of_string starGroups.(5))),(float_of_string starGroups.(6)))
	| "Bu" -> let bubbleGroups = get_matched_groups (regexp regExpBubble) str in
				Bubble(
					(((float_of_string bubbleGroups.(4)),(float_of_string bubbleGroups.(5))),(float_of_string bubbleGroups.(6))),
					((float_of_string bubbleGroups.(8)),(float_of_string bubbleGroups.(9)))
				)
	| "At" -> let attractorGroups = get_matched_groups (regexp regExpAttractor) str in
				Attractor(((float_of_string attractorGroups.(3)),(float_of_string attractorGroups.(4))), (float_of_string attractorGroups.(5)))
	| "Wa" -> let wallGroups = get_matched_groups (regexp regExpWall) str in
				Wall((
						((float_of_string wallGroups.(4)), (float_of_string wallGroups.(5))),
						((float_of_string wallGroups.(7)), (float_of_string wallGroups.(8)))
					))
	| "Mo" -> let monsterGroups = get_matched_groups (regexp regExpMonster) str in
				Monster((
						((float_of_string monsterGroups.(4)), (float_of_string monsterGroups.(5))),
						((float_of_string monsterGroups.(7)), (float_of_string monsterGroups.(8)))
					))
	| "Ro" -> let ropeMakerGroups = get_matched_groups (regexp regExpRopeMaker) str in
				RopeMaker(
					(((float_of_string ropeMakerGroups.(4)),(float_of_string ropeMakerGroups.(5))),(float_of_string ropeMakerGroups.(6))),
					(((float_of_string ropeMakerGroups.(9)),(float_of_string ropeMakerGroups.(10))),(float_of_string ropeMakerGroups.(11)),(float_of_string ropeMakerGroups.(12)))
				)
	| _    -> raise UnknowGameObject

(* The exception returned if the level is not found or innaccessible *)
exception LevelLoadError

(* The level header *)
let defaultLevelHeader = "# OCutTheRope Level File 1.0"

(*	Level loading *)
let loadLevel file =
	(* Reccursive function to read the file *)
	let rec read_file handle check_header level =
		(* The file must have "# OCutTheRope Level File 1.0" on it's first line *)
		if check_header then begin
			if (input_line handle) <> defaultLevelHeader then
				raise LevelLoadError;
			read_file handle false level
		end
		else begin
			try
				(* Give the line to the loading object function *)
				read_file handle false (level@[(loadObject (input_line handle))])
			with End_of_file ->
				close_in handle;
				level
		end;
	in
	(* Catch the exception when a file doesn't exists *)
	try
		read_file (open_in file) true []
	with Sys_error(_) ->
		(* If we're in the level editor, we can use an unexisting file *)
		if (contains Sys.executable_name "editor") then
			[]
		else
			raise LevelLoadError


(* Transforms modifiers to string *)
let modifiers2String m =
	let rec m2s s m =
		match m with
		| h::q -> (
			match h with
			| Bubbled((a,b))     -> m2s ("Bubbled((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ "));" ^ s) q
			| Roped(((a,b),c,d)) -> m2s ("Roped(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ "," ^ (string_of_float d) ^ "));" ^ s) q
			| Point              -> m2s ("Point;" ^ s) q
		)
		| [] -> (sub s 0 (max 0 ((length s)-1))) (* Remove the last semicolon *)
	in
	m2s "" m

(* Transform a level to a string *)
(* TODO match others gameObjects and modifiers *)
let level2String level =
	let rec matchGameObjects str level =
		match level with
		| h::q -> (
			match h with
			| Player(((a, b), c),(d,e),f)      -> matchGameObjects (str ^ "\nPlayer(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ "),(" ^ (string_of_float d) ^ "," ^ (string_of_float e) ^ "),[" ^ (modifiers2String f) ^ "])") q
			| GravField((a,b))                 -> matchGameObjects (str ^ "\nGravField((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ "))") q
			| Star(((a,b),c))                  -> matchGameObjects (str ^ "\nStar(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ "))") q
			| Bubble(((a,b),c),(d,e))          -> matchGameObjects (str ^ "\nBubble(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ "),(" ^ (string_of_float d) ^ "," ^ (string_of_float e) ^ "))") q
			| Attractor((a,b),c)               -> matchGameObjects (str ^ "\nAttractor((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ ")") q
			| Goal(((a,b),(c,d)))		       -> matchGameObjects (str ^ "\nGoal(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ "),(" ^ (string_of_float c) ^ "," ^ (string_of_float d) ^ ")))") q
			| Wall(((a,b),(c,d)))		       -> matchGameObjects (str ^ "\nWall(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ "),(" ^ (string_of_float c) ^ "," ^ (string_of_float d) ^ ")))") q
			| Monster(((a,b),(c,d)))           -> matchGameObjects (str ^ "\nMonster(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ "),(" ^ (string_of_float c) ^ "," ^ (string_of_float d) ^ ")))") q
			| RopeMaker(((a,b),c),((d,e),f,g)) -> matchGameObjects (str ^ "\nRopeMaker(((" ^ (string_of_float a) ^ "," ^ (string_of_float b) ^ ")," ^ (string_of_float c) ^ "),((" ^ (string_of_float d) ^ "," ^ (string_of_float e) ^ ")," ^ (string_of_float f) ^ "," ^ (string_of_float g) ^ "))") q
		)
		| [] -> str
	in
	matchGameObjects defaultLevelHeader level

(* Save a level to a file *)
let saveLevel level file =
	let channel = open_out file in
	output_string channel (level2String level);
	close_out channel
