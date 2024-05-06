open LccTypes 

let cntr = ref (-1)

let fresh () =
  cntr := !cntr + 1 ;
  !cntr

let rec lookup env var = match env with 
  [] -> None
  |(v,e)::t -> if v = var then e else lookup t var

let match_lookup env x = 
  match lookup env x with
  | None -> Var x
  | Some (Var v) -> Var v

let match_lookup_mod env x = 
   match lookup env x with
  | None -> Var(x)
  | Some(v) -> v

let rec alpha_convert e = 
  let rec helper e env = match e with 
  | Var(x) -> match_lookup env x

  | Func(x, body) -> 
    let f = string_of_int (fresh()) in
    Func (f, helper body ((x, Some(Var(f))) :: env))

  | Application(e_1, e_2) -> 
    let s = helper e_1 env in 
    let x = helper e_2 env in
    Application(s, x)
  in helper e []

let rec isalpha e1 e2 = 
  let rec comp e1 e2 env = match (e1, e2) with
  | (Var x1, Var x2) -> 
    (match (lookup env x1, lookup env x2) with
      | (Some v1, Some v2) -> v1 = v2
      | _ -> x1 = x2)

  | (Func(x, body1), Func(y, body2)) -> 
    let fresh_var = string_of_int (fresh()) in
    comp body1 body2 ((x, Some(fresh_var)) :: (y, Some(fresh_var)) :: env)

  | (Application(e_1, e_2), Application(e_3, e_4)) ->
    comp e_1 e_3 env && comp e_2 e_4 env
  in comp (alpha_convert e1) (alpha_convert e2) []
  
 let reduce env e = 
  let rec reduce_aux env e = 
    match e with
    | Var(v) -> match_lookup_mod env v
                 
    | Func(v, body) -> Func(v, reduce_aux env body) 

    | Application(Func(v, body), value) ->
      let s = reduce_aux ((v, Some value) :: env) body
      in reduce_aux env s

    | Application(e1, e2) -> 
      if Application(e1, e2) <> Application(reduce_aux env e1, reduce_aux env e2) then 
        reduce_aux env (Application(reduce_aux env e1, reduce_aux env e2))
      else
        Application(reduce_aux env e1, reduce_aux env e2)
  in
  reduce_aux env (alpha_convert e)

let laze env e = 
  let rec laze_helper env e = 
    match e with 
  | Var(v) -> match_lookup_mod env v

  | Func(v, body) -> Func(v, laze_helper ((v, None) :: env) body) (* call it recursively cuz we dont know what the body is *)

  | Application(Func(v, body), value) -> laze_helper ((v, Some(value)) :: env) body

  | Application(Var(v), e2) -> Application(Var(v), laze_helper env e2)

  | Application(e1, e2) -> let e1' = laze_helper env e1 in 
  if isalpha e1 e1' then Application(e1, laze_helper env e2) else Application(e1', e2)

  | _ -> e

  in laze_helper env (alpha_convert e)

 let eager env e = 
  let rec eager_helper env e = 
  match e with
  | Var(v) -> match_lookup_mod env v
  | Func (v, body) -> Func (v, eager_helper env body)
  
  | Application(Func(v, body), value) ->  
    let val1 = eager_helper env value in
    if val1 = value 
    then eager_helper ((v, Some(value)) :: env) body 
    else Application (Func(v, body), val1)

  | Application (e1, e2) -> Application (eager_helper env e1, eager_helper env e2)
  in eager_helper env (alpha_convert e)

let rec convert tree =
  match tree with
  | Bool true -> "(Lx.(Ly.x))"
  | Bool false -> "(Lx.(Ly.y))"
  | If (a, b, c) -> 
      "((" ^ (convert a) ^ " " ^ (convert b) ^ ") " ^ (convert c) ^ ")"
  | Not a -> 
      "((Lx.((x (Lx.(Ly.y))) (Lx.(Ly.x)))) " ^ (convert a) ^ ")"
  | And (a, b) -> 
      "(((Lx.(Ly.((x y) (Lx.(Ly.y))))) " ^ (convert a) ^ ") " ^ (convert b) ^ ")"
  | Or (a, b) -> 
      "(((Lx.(Ly.((x (Lx.(Ly.x))) y))) " ^ (convert a) ^ ") " ^ (convert b) ^ ")"

let readable tree =
  let rec helper tree = 
  match tree with 
  | Func(x, Func(_, Var x')) when x = x' -> "true" 

  | Func(_, Func(y, Var y')) when y = y' -> "false"
  
  | Application(Func(x1, Application(Application(Var x2,Func(p, Func(y1, Var y2))), Func(x3, Func(f, Var x4)))), a) 
    when x1 = x2 && y1 = y2 && x3 = x4  -> "(not " ^ (helper a) ^ ")" (* Not *)
   
  | Application(Application(Func(x1, Func(y1, Application(Application(Var x2, Var y2), Func(t, Func(y3, Var y4))))),a),b)
    when x1 = x2 && y1 = y2 && y3 = y4 -> "(" ^ (helper a) ^ " and " ^ (helper b) ^ ")" (* And *)

  | Application(Application(Func(x1, Func(y1, Application(Application(Var x2, Func(x3, Func(g, Var x4))), Var y2))),a), b)
    when x1 = x2 && y1 = y2 && x3 = x4 -> "(" ^ (helper a) ^ " or " ^ (helper b) ^ ")" (* Or *)

  | Application(Application(a, b), c) -> "(if " ^ (helper a) ^ " then " ^ (helper b) ^ " else " ^ (helper c) ^ ")" (* If-Then-Else *)

  | _ -> raise (Failure "parsing failed")
    in helper (alpha_convert tree)