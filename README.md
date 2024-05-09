# Introduction 

In this project is a representation of an LambdaCalc-to-English and English-to-LambdaCalc Interpreter.

This is way more complex than the other 2 projects seen so I'll try my best to explain everything. 
## Part 1: The Lexer (aka Scanner or Tokenizer)

The parser will take as input a list of tokens; This list is produced by the *lexer* (also called a *scanner* or *tokenizer*) as a result of processing the input string. Lexing is readily implemented by the use of regular expressions.

### `lex_lambda`

- **Type:** `string -> lambda_token list` 
- **Description:** Converts a lambda calc expression (given as a string) to a corresponding token list using the `lambda_token` types.
- **Exceptions:** `raise (Failure "tokenizing failed")` if the input contains characters which cannot be represented by the tokens.
- **Examples:**
  ```ocaml
  lex_lambda "L" = [Lambda_Lambda; Lambda_EOF]

  lex_lambda "(Lx. (x x))" = [Lambda_LParen; Lambda_Lambda; Lambda_Var "x"; Lambda_Dot; Lambda_LParen; Lambda_Var "x"; Lambda_Var "x"; Lambda_RParen; Lambda_RParen; Lambda_EOF]

  lex_lambda ".. L aL." = [Lambda_Dot; Lambda_Dot; Lambda_Lambda; Lambda_Var "a"; Lambda_Lambda; Lambda_Dot; Lambda_EOF]

  lex_lambda "$" (* raises Failure because $ is not a valid token*)

  lex_lambda "" = [Lambda_EOF]
  ```

The `lambda_token` type is defined in [lccTypes.ml](./src/lccTypes.ml). Here's a list of tokens and their respective lexical representations:

Lexical Representation | Token Name
--- | ---
`(` | `Lambda_LParen`
`)` | `Lambda_RParen`
`.` | `Lambda_Dot`
`[a-z]` | `Lambda_Var`
`L` | `Lambda_Lambda`
`end of string` | `Lambda_EOF`
`_` | `raise (Failure "tokenizing failed")`

#### `lex_engl`

- **Type:** `string -> engl_token list` 
- **Description:** Converts an English expression (given as a string) to a corresponding token list using the `engl_token` types.
- **Exceptions:** `raise (Failure "tokenizing failed")` if the input contains characters which cannot be represented by the tokens.
- **Examples:**
  ```ocaml
  lex_engl "true" = [Engl_True; Engl_EOF]

  lex_engl "if true then false else true" = [Engl_If; Engl_True; Engl_Then; Engl_False; Engl_Else; Engl_True; Engl_EOF]

  lex_engl "true if else" = [Engl_True; Engl_If; Engl_Else; Engl_EOF]

  lex_engl "$" (* raises Failure because $ is not a valid token*)

  lex_engl "" = [Engl_EOF]
  ```

The `engl_token` type is defined in [lccTypes.ml](./src/lccTypes.ml). Here's a list of tokens and their respective lexical representations:

Lexical Representation | Token Name
--- | ---
`(` | `Engl_LParen`
`)` | `Engl_RParen`
`true` | `Engl_True`
`false` | `Engl_False`
`if` | `Engl_If`
`then` | `Engl_Then`
`else` | `Engl_Else`
`and` | `Engl_And`
`or` | `Engl_Or`
`not` | `Engl_Not`
`end of string` | `Engl_EOF`
`_` | `raise (Failure "tokenizing failed")`

### **Important Notes:**
- The lexer input is **case-sensitive**.
- Tokens can be separated by arbitrary amounts of whitespace, which the lexer should discard. Spaces, tabs ('\t'), and newlines ('\n') are all considered whitespace.
- The last token in a token list should always be the `EOF` token. 
- When escaping characters with `\` within OCaml strings/regexp, you must use `\\` to escape from both the string and the regexp.

## Part 2: The Parser
First `parse_lambda`, which takes a list of `lambda_token`s and outputs an AST for the input expression of type `lambda_ast`. 
Second `parse_engl`, which takes a list of `engl_token`s and outputs an AST for the input expression of type `engl_ast`. 
Put all of your parser code in [parser.ml](./src/parser.ml) in accordance with the signature found in [parser.mli](./src/parser.mli). 


### `parse_lambda`
- **Type:** `lambda_token list -> expr`
- **Description:** Takes a list of tokens and returns an AST representing the expression corresponding to the given tokens. Use the CFG below to make your AST.
- **Exceptions:** `raise (Failure "parsing failed")` or `raise (Failure "Empty input to lookahead")` or `raise (Failure "List was empty")` or `raise (Failure "Token passed in does not match first token in list")` if the input fails to parse i.e does not match the expressions grammar.
- **Examples** (more below):
  ```ocaml
  parse_lambda [Lambda_Var "a"; Lambda_EOF] = (Var "a")

  (* lex_lambda "(((Lx. (x x)) a) b)" *)
  parse_lambda [Lambda_LParen; Lambda_LParen; Lambda_LParen;Lambda_Lambda; Lambda_Var "x"; Lambda_Dot; Lambda_LParen; Lambda_Var "x"; Lambda_Var "x"; Lambda_RParen; Lambda_RParen; Lambda_Var "a"; Lambda_RParen; Lambda_Var "b"; Lambda_RParen; Lambda_EOF] = 
  (Application (Application (Func ("x", Application (Var "x", Var "x")), Var "a"),Var "b"))

  parse_lambda [] (* raises Failure *)

  parse_lambda [Lambda_EOF] (* raises Failure *)

  (* lex_lambda "Lx. x" *)
  parse_lambda [Lambda_Lambda; Lambda_Var "x"; Lambda_Dot; Lambda_Var "x"; Lambda_EOF]  (* raises Failure because missing parenthesis *)
  ```

### `parse_engl`
- **Type:** `engl_token list -> engl_ast`
- **Description:** Takes a list of `engl_token` and returns an AST representing the expression corresponding to the given tokens.
- **Exceptions:** `raise (Failure "parsing failed")` or `raise (Failure "Empty input to lookahead")` or `raise (Failure "List was empty")` or `raise (Failure "Token passed in does not match first token in list")`if the input fails to parse i.e does not match the expressions grammar.
- **Examples**
  ```ocaml
  parse_engl [Engl_True; Engl_EOF] = (Bool true)

  (* lex_engl "if true then false else true" *)
  parse_engl [Engl_If; Engl_True; Engl_Then; Engl_False; Engl_Else; Engl_True; Engl_EOF] = 
  If (Bool true, Bool false, Bool true)

  parse_engl [] (* raises Failure *)

  parse_engl [Engl_EOF] (* raises failure *)

  (* lex_engl "true and (false or true" *)
  parse_engl [Engl_True; Engl_And; Engl_LParen; Engl_False; Engl_Or; Engl_True; Engl_EOF]  (* raises Failure because missing parenthesis *)
  ```

### AST and Grammar for `parse_lambda`

Below is the AST (Abstract Syntax Tree) type `lambda_ast`, which is returned by `parse_lambda`.

```ocaml
type var = string

type lambda_ast = 
  | Var of var
  | Func of var * lambda_ast 
  | Application of lambda_ast * lambda_ast
```

In the grammar given below, the syntax matching tokens (lexical representation) is used instead of the token name. For example, the grammar below will use `(` instead of `Lambda_LParen`. 

The grammar is as follows, `x` is any lowercase letter:

```text
e -> x
   | (Lx.e)
   | (e e)
```


### AST and Grammar for `parse_engl`

Below is the AST type `engl_ast`, which is returned by `parse_engl`.

```ocaml
type engl_ast= 
  | If of engl_ast * engl_ast * engl_ast
  | Not of engl_ast
  | And of engl_ast * engl_ast
  | Or of engl_ast * engl_ast
  | Bool of bool
```

In the grammar given below, the syntax matching tokens (lexical representation) is used instead of the token name. For example, the grammar below will use `(` instead of `Engl_LParen`. 

```text
  C -> if C then C else C|H
  H -> U and H|U or H|U
  U -> not U|M
  M -> true|false|(C)
```
Note that for simplicity, `and` + `or` have the same precedence in our grammar.
Due to the fact we are making a left-leaning parser, this means that whichever operation
comes first will have the least precedence.
Consider the following derivation:
```text
true and false or true
C -> H 
  -> U and H 
  -> M and H 
  -> true and H 
  -> true and U or H
  -> true and M or H
  -> true and false or H
  -> true and false or U
  -> true and false or M
  -> true and false or true
```
## Part 3: The Evaluator

The evaluator will consist of six (6) functions, all of which demonstrate properties of an interpreter or compiler. 
The first four functions are related to an interpreter and are `isalpha`, `reduce`, `laze`, and `eager`. 
All of these functions will be implemented in the `eval.ml` file located in [eval.ml](./src/eval.ml). 

### Interpreter
#### `environment`

The `environment` type given in [lccTypes.ml](./src/lccTypes.ml) is defined as below:

```ocaml
type environment = (var * lambda_ast option) list
```

For example, if we wanted to evaluate "let x = 3 in x + 1", then we probably want to evaluate "x + 1" where "x = 3".
In this case, we would want to call `eval [("x",Some(3)] "x + 1"`.


#### `isalpha`
- **Type:** `lambda_ast -> lambda_ast -> bool` 
- **Description:** Returns true if the two inputs are alpha equivalent to each other, false otherwise. `fresh()` might prove to be useful here.
- **Examples:**
  ```ocaml
  (* x, x *)
  isalpha (Var("x")) (Var("x")) = true

  (* y, x *)
  isalpha (Var("y")) (Var("x")) = false 

  (* Lx.x, Ly.y *)
  isalpha (Func("x",Var("x"))) (Func("y",Var("y"))) = true
  ```
  
#### `reduce`

- **Type:** `environment -> lambda_ast -> lambda_ast` 
- **Description:** Reduces a lambda calc expression down to beta normal form. 
- **Examples:**
  ```ocaml
  (* x = x*)
  reduce [] (Var("x")) = Var("x")

  (* Lx.(x y) = Lx.(x y)*)
  reduce [] (Func("x", Application(Var("x"), Var("y")))) = Func("x", Application(Var("x"), Var("y")))

  (* (Lx.x) y = y*)
  reduce [] (Application(Func("x", Var("x")), Var("y"))) = Var("y")
  
  (* ((Lx.x) (y ((Lx.x) b))) = y*)
  reduce [] (Application (Func ("x", Var "x"),
                        Application (Var "y", 
                                    Application (Func ("x", Var "x"), 
                                                 Var "b"))))
            = Application(Var("y"),Var("b"))
  
  (* (a ((Lb.b) y)) = a y*)
  reduce [] (Application (Var("a"), Application (Func ("b", Var("b")), Var("y")))) = Application(Var("a"),Var("y"))

  (* (Lx.x) y with environment [("y", Some(Var("z")))] => z*)
  reduce [("y", Some(Var("z")))] (Application(Func("x", Var("x")), Var("y"))) = Var("z")
  ```


#### `laze`

- **Type:** `environment -> lambda_ast -> lambda_ast` 
- **Description:** Performs a **single** beta reduction using the lazy precedence. You **do not** have to worry about ambiguous applications (see *Important Notes* below for more info).
- **Examples:**
  ```ocaml
  (* x = x*)
  laze [] (Var("x")) = Var("x")

  (* (Lx.x) y = y *)
  laze [] (Application(Func("x", Var("x")), Var("y"))) = Var("y")

  (* (Lx.x) ((Ly.y) z) = ((Ly.y) z)*)
  laze [] (Application(Func("x", Var("x")), Application(Func("y", Var("y")), Var("z")))) = Application(Func("y", Var("y")), Var("z"))

  (* ((Lx.x) (y ((Lx.x) b))) = (y ((Lx.x) b)) *)
  laze [] (Application (Func ("x", Var "x"),
                        Application (Var "y", 
                                    Application (Func ("x", Var "x"), 
                                                 Var "b"))))
            = Application (Var "y", Application (Func ("x", Var "x"), Var "b"))
  
  (* (a ((Lb.b) y)) = a y*)
  laze [] (Application (Var("a"), Application (Func ("b", Var("b")), Var("y")))) = Application(Var("a"),Var("y"))

  (* (Lx.x) ((Ly.y) z) with environment [("z", Some(Var("f")))] = ((Ly.y) z)*)
  laze [("z", Some(Var("f")))] (Application(Func("x", Var("x")), Application(Func("y", Var("y")), Var("z")))) = Application(Func("y", Var("y")), Var("z"))
  ```

  
#### `eager`

- **Type:** `environment -> lambda_ast -> lambda_ast` 
- **Description:** Performs a **single** beta reduction using the eager precedence. You **do not** have to worry about ambiguous applications (see *Important Notes* below for more info).
- **Examples:**
  ```ocaml
  (* x = x *)
  eager [] (Var("x")) = Var("x")

  (* (Lx.x) y = y *)
  eager [] (Application(Func("x", Var("x")), Var("y"))) = Var("y")

  (* ((Lx.x) ((Ly.y) z)) = (Lx.x) z *)
  eager [] (Application(Func("x", Var("x")), Application(Func("y", Var("y")), Var("z")))) = Application(Func("x", Var("x")), Var("z"))

  (* ((Lx.x) (y ((Lx.x) b))) = ((Lx.x) (y b)) *)
  eager [] (Application (Func ("x", Var "x"),
                        Application (Var "y", 
                                    Application (Func ("x", Var "x"), 
                                                 Var "b"))))
            = Application (Func("x",Var("x")),Application(Var("y"),Var("b")))
  
  (* (a ((Lb.b) y)) = a y*)
  eager [] (Application (Var("a"), Application (Func ("b", Var("b")), Var("y")))) = Application(Var("a"),Var("y"))

  (* (Lx.x) ((Ly.y) z) with environment [("z", Some(Var("f")))] = (Lx.x) ((Ly.y) f)*)
  eager [("z", Some(Var("f")))] (Application(Func("x", Var("x")), Application(Func("y", Var("y")), Var("z")))) = Application(Func("x", Var("x")), Application(Func("y",Var("y")),Var("f")))

  (* ((Ly.y) ((Lz.(Lu.u) z))) = ((Ly.y) (Lz.z)) *)
  (* refer to Important Notes section for explanation *)
  eager [] (Application(Func("y", Var("y")), Func("z", Application(Func("u", Var("u")), Var("z"))))) = Application(Func("y", Var("y")), Func("z", Var("z")))

  (* ((Lx.((Ly.y) x)) ((Lx.((Lz.z) x)) y)) = (Lx.((Ly.y) x)) ((Lz.z) y) *)
  eager [] (Application(Func("x", Application(Func("y", Var("y")), Var("x"))), Application(Func("x", Application(Func("z", Var("z")), Var("x"))), Var("y")))) = Application(Func("x", Application(Func("y", Var("y")), Var("x"))), Application(Func("z", Var("z")), Var("y")))
  ```
