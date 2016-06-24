# Socktroll

Just for fun project, re-implementing an old protocol chat protocol in
elixir to learn about low level TCP in elixir.

## BNF

    <message> ::= ( <nick> | <nick-answer> | <rename> | <names> ) <LF>
    |  ( <names-answer> | <quit> | <join> | <part> ) <LF>
    |  ( <message> | <message-answer> | <action> ) <LF>
    |  ( <action-answer> | <illegal> ) <LF>

    <nick> ::= "nick" <nickname>

    <nick-answer> ::= ( "ok" <nickname> | "no" ( "taken" | "bad" ) )

    <rename> ::= "rename" <nickname> <nickname>

    <names> ::= "names"

    <names-answer> ::= <nickname>
    |   <nickname>,?<nickname>*,<nickname>

    <quit> ::= "quit"

    <join> ::= "+" <nickname>

    <part> ::= "-" <nickname>

    <message> ::= "msg" <unicode-string-450>

    <message-answer> ::= "msg" <nickname> <unicode-string-450>


    <action> ::= "action" <unicode-string-450>

    <action-answer> ::= "action" <nickname> <unicode-string-450>

    <illegal> ::= "illegal command"

    <nickname> ::= <unicode-string-40>
