open LccTypes 

let match_token (toks : 'a list) (tok : 'a) : 'a list =
  match toks with
  | [] -> raise (Failure("List was empty"))
  | h::t when h = tok -> t
  | h::_ -> raise (Failure( 
      Printf.sprintf "Token passed in does not match first token in list"
    ))

let lookahead toks = match toks with
   h::t -> h
  | _ -> raise (Failure("Empty input to lookahead"))


(* Write your code below *)

let rec parse_stuff toks = 
  match toks with
  | Lambda_Var i :: tail -> (tail, Var i)

  | Lambda_LParen :: Lambda_Lambda :: Lambda_Var (a) :: Lambda_Dot :: tail -> 
                  let (t_1, s) = parse_stuff tail in let t_2 = 
                  match_token t_1 Lambda_RParen in (t_2, Func(a, s))
  
  | Lambda_LParen :: tail -> let (t_3, e1) = parse_stuff tail in 
                             let(t_4, e2) = parse_stuff t_3 in
                            let s = match_token t_4 Lambda_RParen in (s, Application(e1, e2))
  
  | _ -> raise (Failure "parsing failed")

let rec parse_lambda toks = 
  let (t, exp) = parse_stuff toks in
  if t <> [Lambda_EOF] then
    raise (Failure "parsing failed")
  else
    exp

let rec parse_engl toks = 
  let (t, exp) = parse_C toks in
  if t <> [Engl_EOF] then
    raise (Failure "parsing failed")
  else
    exp

and parse_C toks = 
  match lookahead toks with 
  | Engl_If -> let t = match_token toks Engl_If in
               let (t_1, e_1) = parse_C t in 
               let t_2 = match_token t_1 Engl_Then in
               let (t_3, e_3) =  parse_C t_2 in
               let t_4 = match_token t_3 Engl_Else in
               let (t_5, e_5) = parse_C t_4 in
               (t_5, If(e_1, e_3, e_5))
  | _ -> parse_H toks

and parse_H toks = 
  let (t,e) = parse_U toks in 
  match lookahead t with 
  | Engl_And -> let t = match_token t Engl_And in
                let (t_1, e_1) = parse_H t in
                (t_1, And(e, e_1))
  | Engl_Or -> let t = match_token t Engl_Or in
               let (t_1, e_1) = parse_H t in
               (t_1, Or(e, e_1))
  | _ -> (t,e)

and parse_U toks = 
  match lookahead toks with
  | Engl_Not -> let t = match_token toks Engl_Not in
                let (t_1, e_1) = parse_U t in 
                (t_1, Not e_1)
  | _ -> parse_M toks 

and parse_M toks = 
  match lookahead toks with 
  | Engl_True -> let t = match_token toks Engl_True in (t, Bool true)
  | Engl_False -> let t = match_token toks Engl_False in (t, Bool false)
  | Engl_LParen -> let t = match_token toks Engl_LParen in
                   let (t_1, e_1) = parse_C t in
                   let t_2 = match_token t_1 Engl_RParen in (t_2, e_1)
  | _ -> raise (Failure "parsing failed")
