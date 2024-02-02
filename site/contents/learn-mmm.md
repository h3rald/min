-----
content-type: "page"
title: "Learn: Module Management"
-----
{@ _defs_.md || 0 @}

The min executable includes a minimal but practical package manager that can be used to initialize, install, uninstall, update, list and search _managed min modules_ stored in remote git repositories.

The min commands that make up this module management functionality is often referred to as _mmm_, for _min module management_.

## How mmm works

mmm borrows most of its design from Nim's [Nimble](https://github.com/nim-lang/nimble), but it is mcuh simpler. Here are the basics:

- mmm is not a standalone program, it is built-in into the min executable
- mmm has a central registry (a [single JSON file](https://min-lang.org/mmm.json) really, and distributed storage (managed modules are hosted in remote github repositorues).
- managed modules can be installed both locally to a specific folder (another managed module) or globally, in the `$HOME/mmm` folder.
- each managed module relies on an `mmm.json` for its metadata, including dependencies on other managed modules.
- the version (git branch or tag) of a managed module must be always specified when installing or specifying a dependency. There is no concept of semantic versioning support, and that's deliberate: it makes things simpler and leas error prone.

### The registry

The registry of mmm is a single JSON file accessible here:

<https://min-lang.org/mmm.json>

The registry contains the metadata of all public managed modules and it is queried when running every mmm command (see below).

### Module lookup

When requiring a module in your min file using the {{#link-operator||global||require}} symbol, min will attempt to lookup the module (for example **module1**) checking the following files (in order):

- module1.min
- mmm/module1/*/index.min
- $HOME/mmm/module1/*/index.min

## Commands

The following sections explain how to use the mmm-related commands that are built-in into tbe min executable.

### min init

Initializes a new managed min module in tbe current directory by creating a sample `mmm.json` file in the current folder.

### min install [name version | name@version] [-g]

Install the specified managed module by specifying its name and version. By default, the module is installed in the `mmm/<name>/<version>` folder; if `-g` is specified, it is installed in `$HOME/mmm/<name>/<version>`.

If no version is specified, the version will be set to the HEAD branch of the git repository of the module.

If no name and no version are specified, all the managed modules (and their dependencies) specified as dependencies for the current managed module will be installed.

If the installation of one dependency fails, the installation of the module will be rolled back.

### min uninstall [name version | name@version] [-g]

Uninstall the module specified by name and version either locally or globally (if `-g` is specified).

If no version is specified, the version will be set to the HEAD branch of the git repository of the module.

If no version is specified, all version of the module will be uninstalled (if the module is installed globally).

If no name and no version are specified, all dependencies of the current managed module (and their dependencies) will be uninstalled.

### min update [name version | name@version] [-g]

Update the module specified by name and version either locally or globally (if `-g` is specified).

If no version is specified, the version will be set to the HEAD branch of the git repository of the module.

If no name and no version are specified, all dependencies of the current managed module (and their dependencies) will be updated.

### min list

List all the installed dependencies of the current module, and their dependencies, recursively.

### min search [arg1 arg2 ... argN]

Search for a managed module matching the specified arguments. if no argument is specified, the metadata of all public managed modules will be printed.

## Creating a managed min module

Creating a managed min module is easy. As a minimum, you need to create three files:

- an `index.min` file containing your code
- a license file
- an `mmm.json` file containing the module metadata

See [min-highlight](https://git.sr.ht/~h3rald/min-highlight) as an example.

### Metadata

The `mmm.json` file of a managed min module must contain at least the following metadata:

- **name**
- **description**
- **private** set to **true** for private modules, or, if public:
  - **method** set to **git**
  - **url** set to the URL of the git repository containing the module
- **license**
- **deps** set to an object with the keys corresponding to module names and the values to their respective versions

### Publishing

If you want to publish your module, just create a PR on the [min git repository](https://github.com/h3rald/min) and modify [this file](https://github.com/h3rald/min/blob/master/site/assets/mmm.json) by adding the metadata for your module.

