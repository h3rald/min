" Vim syntax file
" Language: min
" Maintainer: Fabio Cevasco
" Last Change: 22 May 2026
" Version: 0.47.0

if exists("b:current_syntax")
  finish
endif

setl iskeyword=@,36-39,+,-,*,.,/,:,~,!,48-57,60-65,94-95,192-255 
setl iskeyword+=^

syntax keyword          minDefaultSymbol != $ % && ' * + - -> -inf / : :: < <= =% =-= == ==> => > >< >= >> ? @ ^ all? and any? append apply apply-interpolate args avg base base? bind bitand bitclear bitflip bitnot bitor bitparity bitset bitxor boolean boolean? capitalize case chr compiled? concat constructor crypto decode-url define define-sigil defined-sigil? defined-symbol? delete-sigil delete-symbol dequote dev dev? dict dictionary? difference div drop encode-url escape eval even? exit expect expect-all expect-any expect-empty-stack filter find first flatten float float? foreach format-error from-bin from-dec from-hex from-json from-oct from-semver from-yaml fs get get-env get-raw gets global harvest help http if import in? indent indexof inf infix-dequote insert integer integer? interpolate intersection io join lambda lambda-bind last length line-info linrec load load-symbol loglevel loglevel? lowercase map map-reduce match? math med mod nan net not null? number? odd? one? operator opts or ord parent-scope parse parse-url partition pred prefix prefix-dequote prepend print product prompt publish put-env puts quit quotation? quote quote-map quotecmd quoted-symbol? quotesym raise random randomize range raw-args reduce reject remove remove-symbol repeat replace replace-apply require rest return reverse save-symbol saved-symbols scope scope-sigils scope-symbols seal-sigil seal-symbol sealed-sigil? sealed-symbol? search search-all semver-inc-major semver-inc-minor semver-inc-patch semver? set set-sym shl shorten shr sigil sigil-help sigils size slice sort source split stack store string string? stringlike? strip substr succ suffix sum symbol symbol-help symbols symmetric-difference sys take tap time times titleize to-bin to-dec to-hex to-json to-oct to-semver to-yaml tokenize try type type? typealias typealias:xml-node typeclass union unless unseal-sigil unseal-symbol uppercase version when while with xml xor ~
syntax match            minDefaultSymbol ;||;

syntax keyword          minCommentTodo        TODO FIXME XXX TBD contained
syntax match            minComment            /;.*$/ contains=minCommentTodo
syntax region           minComment            start=;#|; end=;|#; contains=minCommentTodo

syntax match            minDefaultSigil       ;\<[/:@'~!?$%&=<>#^*#+]; contained
syntax match            minQuote              ;\<['];
syntax match            minBinding            ;@;

syntax match            minNumber             ;[-+]\=\d\+\(\.\d*\)\=;
syntax keyword          minBoolean            true false
syntax region           minString             start=+"+ skip=+\\\\\|\\$"+  end=+"+  

syntax region           minSigilSymbol        start=;\<[/:@'~!?$%&=<>^*#+]; end=;\>; contains=minDefaultSigil  
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
