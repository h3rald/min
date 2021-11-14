-----
content-type: "page"
title: "fs Module"
-----
{@ _defs_.md || 0 @}

{#op||absolute-path||{{sl}}||{{s}}||
Returns the absolute path to {{sl}}. #}

{#op||absolute-path?||{{sl}}||{{b}}||
Returns {{t}} if {{sl}} is an absolute path. #}

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

{#op||expand-filename||{{sl}}||{{s}}||
Returns the absolute path to the file name {{sl}}. #}

{#op||expand-symlink||{{sl}}||{{s}}||
Returns the absolute path to the symlink {{sl}} (an error is raised if {{sl}} is not a symlink). #}

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

{#op||join-path||{{q}}||{{s}}||
Joins the strings contained in {{q}} with `/`.#}

{#op||normalized-path||{{sl}}||{{s}}||
Returns the normalized path to {{sl}}. #}

{#op||mtime||{{sl}}||{{flt}}||
Returns a timestamp corresponding to the time that file/directory {{sl}} was last modified.#}

{#op||relative-path||{{sl1}} {{sl2}}||{{s}}||
Returns the path of {{sl1}} relative to {{sl2}}. #}

{#op||symlink?||{{sl}}||{{b}}||
Returns {{t}} if the specified path {{sl}} exists and is a symbolic link. #}

{#op||unix-path||{{sl}}||{{s}}||
Converts all backslashes in {{sl}} to slashes. #}

{#op||windows-path||{{sl}}||{{s}}||
Converts all slashes in {{sl}} to backslashes. #}
