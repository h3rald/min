" Vim syntax file
" Language: min
" Maintainer: Fabio Cevasco
" Last Change: 25 March 2017
" Version: 0.5.0

if exists("b:current_syntax")
  finish
endif

setl iskeyword=@,36-39,+,-,/,*,.,:,~,!,48-57,60-65,94-95,192-255 
setl iskeyword+=^

syntax keyword          minDefaultSymbol ! != $ & ' * + # - % ^ -> . .. / : < <= == => =~ > >= @ ROOT aes and append ask at atime b bind bool bool? bury1 bury2 bury3 c call call! capitalize case cd chmod choose clear-stack column-print concat confirm cons cp cpu crypto ctime datetime ddel debug decode decrypt define delete dget dictionary? dig1 dig2 dig3 dip dir? dirname div dprint dprint! dset dump-stack dup dupd encode encrypt env? error eval even? exit fappend fatal file? filename filter first float float? foreach fperms fread from-json format-error fs fsize fstats ftype fwrite gets get-stack getenv hardlink hidden? i id ift ifte import indent info inspect int int? interpolate interval io join k keys length linrec load load-symbol logic loglevel loglevel? lowercase ls ls-r map match md5 mkdir mod module mtime mv newline not notice now num number? odd? os password pop popd pred print print! prompt publish puts puts! putenv q quotation? quote quote-bind quote-define raise regex remove-symbol repeat replace rest rm rmdir run save-symbol scope scope? seal search set-stack sha1 sha224 sha256 sha384 sha512 sigils sip sleep sort source split startup stored-symbols str string string? strip succ swap swapd swons symbols symlink symlink? sys system take tformat time timeinfo times timestamp titleize to-json try unquote uppercase unzip values version warn which while with xor zip contains


syntax match            minDefaultSigil       ;\<[:@'~!$%&$=<>#^*#+/]; contained
syntax match            minSpecialSymbols     ;[:@'~!$%&$=<>#^*#+/]; contained
syntax match            minQuote              ;\<['];
syntax match            minQuotedBinding      ;#;
syntax match            minBinding            ;@;

syntax keyword          minCommentTodo        TODO FIXME XXX TBD contained
syntax match            minComment            /;.*$/ contains=minCommentTodo

syntax match            minNumber             ;[-+]\=\d\+\(\.\d*\)\=;
syntax keyword          minBoolean            true false
syntax region           minString             start=+"+ skip=+\\\\\|\\$"+  end=+"+  

syntax region           minSigilSymbol        start=;\<[:@'~!$%&$=<>^*#+/]; end=;\>; contains=minDefaultSigil  
syntax region           minQuotedSymbol       start=;\<[']; end=;\>; contains=minQuote
syntax region           minBoundSymbol        start=;@; end=;\>; contains=minBinding
syntax region           minQuotedBoundSymbol  start=;#; end=;\>; contains=minQuotedBinding
syntax match            minSymbol             ;[a-zA-Z0-9+._-][a-zA-Z0-9/!?+*._-]*;

syntax match            minParen              ;(\|); 



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
hi default link         minQuotedBinding      Delimiter
hi default link         minDefaultSigil       Delimiter
hi default link         minSymbol             Identifier
hi default link         minQuotedSymbol       Special
hi default link         minBoundSymbol        Special
hi default link         minQuotedBoundSymbol  Special
hi default link         minParen              Special

let b:current_syntax = "min"
