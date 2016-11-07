" Vim syntax file
" Language: MiNiM
" Maintainer: Fabio Cevasco
" Last Change: 15 September 2016
" Version: 1.0.0

if exists("b:current_syntax")
  finish
endif

setl iskeyword+=?,$,+,#,*,/,%,=,>,<,&,-,',.,:,~,!
setl iskeyword+=^
setl iskeyword+=@

syntax keyword          minimDefaultSymbol ! != $ & ' * + # - % ^ -> . .. / : < <= == => =~ > >= @ ROOT aes and append ask at atime b bind bool bool? bury1 bury2 bury3 c call call! capitalize case cd chmod choose clear-stack column-print concat confirm cons cp cpu crypto ctime datetime ddel decode decrypt define delete dget dictionary? dig1 dig2 dig3 dip dir? dirname div dprint dprint! dset dump-stack dup dupd encode encrypt env? eval even? exit fappend file? filename filter first float float? foreach fperms fread from-json format-error fs fsize fstats ftype fwrite gets get-stack getenv hardlink hidden? ifte import indent inspect int int? interpolate interval io join k keys length linrec load load-symbol logic loglevel lowercase ls ls-r map match md5 mkdir mod module mtime mv newline not now num number? odd? os password pop popd pred print print! prompt publish puts puts! putenv q quotation? quote quote-bind quote-define raise regex remove-symbol repeat replace rest rm rmdir run save-symbol scope scope? seal search set-stack sha1 sha224 sha256 sha384 sha512 sigils sip sleep sort source split startup stored-symbols str string string? strip succ swap swapd swons symbols symlink symlink? sys system take tformat time timeinfo times timestamp titleize to-json try unquote uppercase unzip values version which while with xor zip contains


syntax match            minimDefaultSigil     ;\<[:@'~!$%&$=<>^*#]; contained
syntax match            minimSpecialSymbols   ;[:@'~!$%&$=<>^*#]; contained
syntax match            minimQuote            ;\<['];
syntax match            minimBinding          ;@;

syntax keyword          minimCommentTodo      TODO FIXME XXX TBD contained
syntax match            minimComment          /;.*$/ contains=minimCommentTodo

syntax match            minimNumber           ;[-+]\=\d\+\(\.\d*\)\=;
syntax keyword          minimBoolean          true false
syntax region           minimString           start=+"+ skip=+\\\\\|\\$"+  end=+"+  

syntax region           minimSigilSymbol      start=;\<[:@'~!$%&$=<>^*]; end=;\>; contains=minimDefaultSigil  
syntax region           minimQuotedSymbol     start=;\<[']; end=;\>; contains=minimQuote
syntax region           minimBoundSymbol      start=;@; end=;\>; contains=minimBinding
syntax match            minimSymbol           ;[a-zA-Z0-9+._-][a-zA-Z0-9/!?+*._-]*;

syntax match            minimParen            ;(\|); 



" Highlighting
hi default link         minimComment          Comment
hi default link         minimCommentTodo      Todo
hi default link         minimString           String
hi default link         minimSigilSymbol      String
hi default link         minimNumber           Number
hi default link         minimBoolean          Boolean
hi default link         minimDefaultSymbol    Statement
hi default link         minimQuote            Delimiter
hi default link         minimBinding          Delimiter
hi default link         minimDefaultSigil     Delimiter
hi default link         minimSymbol           Identifier
hi default link         minimQuotedSymbol     Special
hi default link         minimBoundSymbol      Special
hi default link         minimParen            Special

let b:current_syntax = "minim"
