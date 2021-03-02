-----
content-type: "page"
title: "Welcome to the min programming language"
-----
<div class="pure-g">
  <section class="pitch pure-u-1 pure-u-md-2-3">
    <em>min</em> is a functional, concatenative programming language 
    with a minimalist syntax, a small but practical standard library, and an advanced 
    REPL. All packed in a single file.
  </section>
  <section class="centered pure-u-1 pure-u-md-1-3">
    <a class="pure-button pure-button-primary" href="/get-started/"><i class="ti-download"></i> download min v{{$version}}</a><br />
    <small>
      <a href="https://github.com/h3rald/min">Repository</a> | 
      <a href="https://github.com/h3rald/min/issues">Issues</a> | 
      <a href="https://github.com/h3rald/min/discussions">Discussions</a> |
      <a href="https://h3rald.com/min/Min_DeveloperGuide.htm">Guide</a>
    </small>
  </section>
</div>
<div class="pure-g">
  <section class="pure-u-1 pure-u-md-1-2">
    <h2>Features</h2>
    <ul>
      <li>Entirely written in <a href="https://nim-lang.org">Nim</a>. It can be easily embedded in other Nim programs.</li>
      <li>Follows the <strong>functional</strong> and <strong>concatenative</strong> programming paradigms.</li>
      <li>Provides a wide range of <strong>combinators</strong> for advanced stack manipulation and dequoting.</li>
      <li>Provides a <strong>minimal set of data types</strong>: integer, floats, strings, booleans, dictionaries, and quotations (lists).</li>
      <li><strong>Homoiconic</strong>, code can be accessed as data.</li>
      <li>Includes an <strong>advanced REPL</strong> with auto-completion and history management.</li>
      <li>Provides a lightweight <strong>module system</strong>.</li>
      <li>Provides <strong>sigils</strong> as syntactic sugar to access environment variables, quoting, defining and binding data, etc.</li>
      <li>Includes a small but useful <strong>standard library</strong> for practical tasks.</li>
      <li>Self-contained, statically compiled into single file.</li>
    </ul>
  </section>
  <section class="pure-u-1 pure-u-md-1-2">
    <h2>Examples</h2>
    <p>The following example shows how to find recursively all files in the current folder that were modified in the last hour:</p>
    <pre>
      <code>
. ls-r 
(mtime now 3600 - >) 
filter</code>
    </pre>
    <p>The following example shows how to calculate the factorial of 5 using the <code>linrec</code> combinator:</p>
    <pre>
      <code>
5 
(dup 0 ==) (1 +) 
(dup 1 -) (*) linrec</code>
    </pre>
  </section>
</div>