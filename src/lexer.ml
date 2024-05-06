open LccTypes

let lex_lambda input = 
  let len = String.length input in

  let rec tok pos = 
    if pos >= len then [Lambda_EOF]

    else if Str.string_match (Str.regexp "(") input pos then
      Lambda_LParen :: (tok (pos + 1))
    
    else if Str.string_match (Str.regexp ")") input pos then
      Lambda_RParen :: (tok (pos + 1))

    else if Str.string_match (Str.regexp "L") input pos then
      Lambda_Lambda :: (tok (pos + 1))

    else if Str.string_match (Str.regexp "\\.") input pos then
      Lambda_Dot :: (tok (pos + 1))

    else if Str.string_match (Str.regexp "[a-z]") input pos then
      let var = Str.matched_string input in
      Lambda_Var var :: (tok (pos + String.length var))

    else if Str.string_match (Str.regexp " ") input pos then
      tok (pos + 1)
      
    else 
      raise (Failure "tokenizing failed")
    in tok 0

let lex_engl input = 
  let len = String.length input in

  let rec tok pos = 
    if pos >= len then [Engl_EOF]

    else if Str.string_match (Str.regexp "(") input pos then
      Engl_LParen :: (tok (pos + 1))
    
    else if Str.string_match (Str.regexp ")") input pos then
      Engl_RParen :: (tok (pos + 1))

    else if Str.string_match (Str.regexp "true") input pos then
      let inp = Str.matched_string input in
      Engl_True :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "false") input pos then
      let inp = Str.matched_string input in
      Engl_False :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "if") input pos then
      let inp = Str.matched_string input in
      Engl_If :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "then") input pos then
      let inp = Str.matched_string input in
      Engl_Then :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "else") input pos then
      let inp = Str.matched_string input in
      Engl_Else :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "and") input pos then
      let inp = Str.matched_string input in
      Engl_And :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp "or") input pos then
      let inp = Str.matched_string input in
      Engl_Or :: (tok (pos + String.length inp))
      
    else if Str.string_match (Str.regexp "not") input pos then
      let inp = Str.matched_string input in
      Engl_Not :: (tok (pos + String.length inp))

    else if Str.string_match (Str.regexp " ") input pos then
      tok (pos + 1)
    else 
      raise (Failure "tokenizing failed")
    in tok 0

