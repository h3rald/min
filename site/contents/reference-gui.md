-----
content-type: "page"
title: "gui Module"
-----
{@ _defs_.md || 0 @}

{#op||audio||{{none}}||{{audio}}||
...
#}

{#op||clear||{{window}}||{{none}}||
...
#}

{#op||close||{{window}}||{{none}}||
...
#}

{#op||draw||{{window}} {{q}} {{i}}||{{none}}||
...
#}

{#op||height||{{window}}||{{i}}||
...
#}

{#op||keys||{{window}}||{{i}}||
...
#}

{#op||loop||{{window}} {{q}}||{{none}}||
...
#}

{#op||modkey||{{window}}||{{i}}||
...
#}

{#op||mouse||{{window}}||{{i}}||
...
#}

{#op||pixel||{{window}} {{q}}||{{none}}||
...
#}

{#op||play||{{audio}} {{q}}||{{none}}||
...
#}

{#op||samples||{{audio}}||{{i}}||
...
#}

{#op||sleep||{{window}}||{{i}}||
...
#}

{#op||stop||{{audio}}||{{none}}||
...
#}

{#op||time||{{window}}||{{i}}||
...
#}

{#op||width||{{window}}||{{i}}||
...
#}

{#op||window||{{d}}||{{window}}||
Creates a new window by specifying a dictionary containing the following keys:

* title
* width
* height
* fps (default: 60) #}
