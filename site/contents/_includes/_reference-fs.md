{@ _defs_.md || 0 @}

{#op||atime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was last accessed.#}

{#op||ctime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was created.#}

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
> > `'min fstats`
> > 
> > produces:
> > 
> >      (
> >        ("name" (min))
> >        ("device" 16777220)
> >        ("file" 50112479)
> >        ("type" "file")
> >        ("size" 617068)
> >        ("permissions" 755)
> >        ("nlinks" 1)
> >        ("ctime" 1496583112.0)
> >        ("atime" 1496584370.0)
> >        ("mtime" 1496583112.0)
> >      )#}

{#op||ftype||{{sl}}||{{s}}||
Returns the type of file/directory {{sl}} (`"file"` or `"dir"`).#}

{#op||hidden?||{{sl}}||{{b}}||
Returns {{t}} if file/directory {{sl}} is hidden, {{f}} otherwise.#}

{#op||mtime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was last modified.#}

