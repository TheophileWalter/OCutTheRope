(*	DOWNLOAD.ML
 *	
 *	Let others people create levels for you.
 *	Download a collection of levels from an online server.
 *)

open Graphics
open Http
open Scripts
open Gui

(* unit -> (string * string) list 
 * Return a list of string couple, (level id, level description) *)
let getOnlineList () =
	(* Get the list from the server *)
	let resp = httpGET "http://octr.walter.tw/get.php?getlist" in
	if ((fst resp) <> 200) then
		raise HTTPError;
	(* Split the lines *)
	let lines = String.split_on_char '\n' (snd resp) in
	(* Merge the ID and the description *)
	let rec merge inList =
		match inList with
		| e1::e2::q -> [(e1, e2)]@(merge q)
		| _::_ | [] -> []
	in
	merge lines

let rec printStringCoupleList l =
	match l with
	| (s1, s2)::q -> Printf.printf "(%s, %s)\n%!" s1 s2; printStringCoupleList q
	| []          -> ()

(* Main function *)
let rec ocaMain levels i =
	(* Draw a button list *)
	let rec drawList l from =
		match l with
		| e::q ->
			if (from > 0) then
				drawList q (from-1)
			else begin
				drawButton 30 (540 + (60*from)) 440 30 (snd e);
				drawList q (from-1)
			end
		| []   -> ()
	in
	(* Check if a button is pressed *)
	let rec getPressed l from x y =
		match l with
		| e::q ->
			if (from > 0) then
				getPressed q (from-1) x y
			else begin
				if (x >= 30) && (y >= (540 + (60*from))) && (x <= 30+440) && (y <= (540 + (60*from))+30) then
					e
				else
					getPressed q (from-1) x y;
			end
		| []   -> ("", "")
	in
	(* Draw the list from i position *)
	clear_graph ();
	drawList levels i;

	(* Draw up and down buttons *)
	drawButton 10 10 50 30 "Down";
	drawButton (500-60) 10 50 30 "Up";

	(* Wait for a mouse click *)
	let event = wait_next_event [Button_down] in

	(* Check for a click on a level *)
	let pressed = getPressed levels i event.mouse_x event.mouse_y in
	if ((fst pressed) <> "") then begin
	 	(* Download the level *)
	 	let resp = httpGET ("http://octr.walter.tw/get.php?getlevel=" ^ (fst pressed)) in
	 	if ((fst resp) <> 200) then
	 		messageBox "Level downloading" "An error occured!\nYour level has not been downloaded."
	 	else begin
		 	(* Save it *)
		 	let channel = open_out ("levels/online/" ^ (snd pressed) ^ ".lvl") in
			output_string channel (snd resp);
			close_out channel;
			(* Run it *)
			ignore (Sys.command ("./game.native \"levels/online/" ^ (snd pressed) ^ ".lvl\""));
			(* Exit *)
			exit 0
		end

	end else begin
	 	if ((event.mouse_x >= 10) && (event.mouse_x <= 60) && (event.mouse_y >= 10) && (event.mouse_y <= 40)) then
	 		ocaMain levels (min ((List.length levels)-1) (i+1))
	 	else if ((event.mouse_x >= 440) && (event.mouse_x <= 490) && (event.mouse_y >= 10) && (event.mouse_y <= 40)) then
	 		ocaMain levels (max 0 (i-1))
	 	else
	 		ocaMain levels i;
	end

(* Run some usefull stuff *)
let () =
	(* Open a window *)
	open_graph " 500x600";
	set_window_title "OCutTheRope - Online Levels";

	(* Displays a message while downloading list *)
	ignore (
		try
			set_font "-*-fixed-medium-r-semicondensed--25-*-*-*-*-*-iso8859-1"
		with Graphics.Graphic_failure(_) -> ()
	);
	moveto 30 300;
	draw_string "Downloading levels, please wait....";
	ignore (
		try
			set_font "-*-fixed-medium-r-semicondensed--15-*-*-*-*-*-iso8859-1"
		with Graphics.Graphic_failure(_) -> ()
	);

	(* Download the levels and execute the main function *)
	try
		ocaMain (getOnlineList ()) 0
	with Graphics.Graphic_failure(_) -> exit 0
