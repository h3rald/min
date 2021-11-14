-----
content-type: "page"
title: "fs Module"
-----
{@ _defs_.md || 0 @}

{#op||atime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was last accessed.#}

{#op||ctime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was created.#}

{#op||dirname||{{sl}}||{{s}}||
Returns the path of the directory containing path {{sl}}.#}

{#op||dir?||{{sl}}||{{b}}||
Returns {{t}} if the specified path {{sl}} exists and is a directory. #}

{#op||exists?||{{sl}}||{{b}}||
Returns {{t}} if the specified file or directory {{sl}} exists. #}

{#op||file?||{{sl}}||{{b}}||
Returns {{t}} if the specified path {{sl}} exists and is a file. #}

{#op||filename||{{sl}}||{{s}}||
Returns the file name of path {{sl}}.#}

{#op||fperms||{{sl}}||{{i}}||
Returns the Unix permissions (expressed as a three-digit number) of file/directory {{sl}}.#}

{#op||fsize||{{sl}}||{{i}}||
Returns the size in bytes of file/directory {{sl}}.#}

{#op||fstats||{{sl}}||{{d}}||
> Returns a dictionary {{d}} containing information on file/directory {{sl}}.
> > %sidebar%
> > Example
> > 
> > Assuming that `min` is a file, the following:
> > 
> > `"min" fstats`
> > 
> > produces:
> > 
> >      {
> >        "min" :name
> >        16777220 :device
> >        50112479 :file
> >        "file" :type
> >        617068 :size
> >        755 :permissions
> >        1 :nlinks
> >        1496583112.0 :ctime
> >        1496584370.0 :atime
> >        1496583112.0 :mtime
> >      }#}

{#op||ftype||{{sl}}||{{s}}||
Returns the type of file/directory {{sl}} (`"file"` or `"dir"`).#}

{#op||hidden?||{{sl}}||{{b}}||
Returns {{t}} if file/directory {{sl}} is hidden, {{f}} otherwise.#}

{#op||mtime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was last modified.#}

{#op||symlink?||{{sl}}||{{b}}||
Returns {{t}} if the specified path {{sl}} exists and is a symbolic link. #}
