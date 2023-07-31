" Vim syntax file
" Language: min
" Maintainer: Fabio Cevasco
" Last Change: $date
" Version: $version

if exists("b:current_syntax")
  finish
endif

setl iskeyword=@,36-39,+,-,*,.,/,:,~,!,48-57,60-65,94-95,192-255 
setl iskeyword+=^

syntax keyword          minDefaultSymbol $symbols
syntax match            minDefaultSymbol ;||;

syntax keyword          minCommentTodo        TODO FIXME XXX TBD contained
syntax match            minComment            /;.*$$/ contains=minCommentTodo
syntax region           minComment            start=;#|; end=;|#; contains=minCommentTodo

syntax match            minDefaultSigil       ;\<[/:@'~!?$$%&=<>#^*#+]; contained
syntax match            minQuote              ;\<['];
syntax match            minBinding            ;@;

syntax match            minNumber             ;[-+]\=\d\+\(\.\d*\)\=;
syntax keyword          minBoolean            true false
syntax region           minString             start=+"+ skip=+\\\\\|\\$$"+  end=+"+  

syntax region           minSigilSymbol        start=;\<[/:@'~!?$$%&=<>^*#+]; end=;\>; contains=minDefaultSigil  
syntax region           minQuotedSymbol       start=;\<[']; end=;\>; contains=minQuote
syntax region           minBoundSymbol        start=;@; end=;\>; contains=minBinding
syntax match            minSymbol             ;[a-zA-Z._][a-zA-Z0-9/!?+*._-]*;

syntax match            minParen              ;(\|)\|{\|}[\|]; 

syntax match            minSharpBang          /\%^#!.*/


" Highlighting
hi default link         minComment            Comment
hi default link         minCommentTodo        Todo
hi default link         minString             String
hi default link         minSigilSymbol        String
hi default link         minNumber             Number
hi default link         minBoolean            Boolean
hi default link         minDefaultSymbol      Statement
hi default link         minQuote              Delimiter
hi default link         minBinding            Delimiter
hi default link         minDefaultSigil       Delimiter
hi default link         minSymbol             Identifier
hi default link         minQuotedSymbol       Special
hi default link         minBoundSymbol        Special
hi default link         minParen              Special
hi default link         minSharpBang          Preproc

let b:current_syntax = "min"
