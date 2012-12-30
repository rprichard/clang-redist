#!/usr/bin/env python
# This script requires at least Python 2.6, but also runs on Python3.
#
# (It uses os.path.relpath, which is new in 2.6.  The script would otherwise be
# fairly easy to port to an older Python.)

from __future__ import absolute_import, print_function, unicode_literals
import os
import sys
import subprocess
import re

USAGE = """usage: %prog [options] -- SOURCES...

Updates RPATH entries in the source paths.

A source path may be either a directory or an ELF file.  If it is a directory,
all of the ELF files in it are updated.

Options like --discard and --use-origin are "actions".  For each path component
in an RPATH setting, the first matching action on the command-line is applied.
If no action matches a path component, the path is accepted.  To reject all
unhandled components, add --reject / to the end of the command-line.

This script requires readelf and chrpath to be in the PATH.

Converting an RPATH component to use $ORIGIN may make it larger.  The new RPATH
setting must be no longer than the original component.  (This is also a
limitation of chrpath.)

Options:
  --help             show this help message and exit
  --use-origin PATH  Convert an RPATH path pointing at/inside PATH to a path
                     relative to $ORIGIN.
  --discard PATH     Discard an RPATH path pointing at/inside PATH.
  --accept PATH      Accept an RPATH path pointing at/inside PATH.
  --reject PATH      Abort on an RPATH path pointing at/inside PATH."""

def main():
    (options, args) = parseCommandLine()
    for fixDir in args:
        fixDir = os.path.abspath(fixDir)
        fixFilesProc = subprocess.Popen(["find", fixDir, "-type", "f"],
            stdout=subprocess.PIPE)
        fixFiles = fixFilesProc.communicate()[0].decode()
        assert fixFilesProc.returncode == 0
        for fixFile in fixFiles.splitlines():
            if isElfFile(fixFile):
                fixElfFile(options.actions, fixFile)

def parseCommandLine():
    # This code does not use optparse because optparse has abbreviated long
    # option names, and there is no way to turn them off.  (Newer versions of
    # Python have argparse, which has the same behavior.)
    class Options: pass
    options = Options()
    options.actions = []
    positionalArgs = []
    args = sys.argv[1:]
    while len(args) > 0:
        arg = args.pop(0)
        if arg == "--use-origin" and len(args) > 0:
            options.actions.append(
                UseOriginAction(os.path.abspath(args.pop(0))))
        elif arg == "--discard" and len(args) > 0:
            options.actions.append(
                DiscardAction(os.path.abspath(args.pop(0))))
        elif arg == "--accept" and len(args) > 0:
            options.actions.append(
                AcceptAction(os.path.abspath(args.pop(0))))
        elif arg == "--reject" and len(args) > 0:
            options.actions.append(
                RejectAction(os.path.abspath(args.pop(0))))
        elif arg == "--":
            positionalArgs.extend(args)
            args = []
        elif arg in ["-h", "-help", "--help"]:
            print(USAGE.replace("%prog", sys.argv[0]))
            sys.exit(0)
        elif arg.startswith("-"):
            print("Error: Unrecognized argument " + arg)
            print(USAGE.replace("%prog", sys.argv[0]))
            sys.exit(1)
        else:
            positionalArgs.append(arg)
    return (options, positionalArgs)

def isChildPath(parent, possibleChild):
    """Both paths should be normalized using os.path.abspath."""
    return (parent == "/" or
            parent == possibleChild or
            possibleChild.startswith(parent + "/"))

def isElfFile(path):
    if os.path.islink(path) or not os.path.isfile(path):
        return False
    with open(path, "rb") as f:
        return f.read(4) == b"\x7fELF"

def fixElfFile(actions, path):
    origRpath = getRpath(path)
    if origRpath is None:
        return
    components = origRpath.split(":")
    newComponents = []
    components = [fixRpathComponent(actions, path, c) for c in components]
    components = [c for c in components if c is not None]
    newRpath = ":".join(components)
    if newRpath != origRpath:
        print("%s: old RPATH=%s" % (path, origRpath))
        print("%s: new RPATH=%s" % (path, newRpath))
        options = ["chrpath"]
        options += ["-d"] if len(newRpath) == 0 else ["-r", newRpath]
        options += [path]
        p = subprocess.Popen(options, stdout=subprocess.PIPE)
        p.communicate()
        if p.returncode != 0:
            sys.exit("Error: chrpath failed")

def getRpath(path):
    p = subprocess.Popen(["readelf", "-d", path], stdout=subprocess.PIPE)
    out = p.communicate()[0].decode()
    if p.returncode != 0:
        sys.exit("Error: readelf -d %s failed" % path)
    matches = list(re.finditer(
            r".*\(RPATH\)\s*Library rpath: \[(.*)\]$", out, re.MULTILINE))
    if len(matches) == 0:
        return None
    elif len(matches) == 1:
        return matches[0].group(1)
    else:
        sys.exit("Error: Multiple RPATH settings in '%s'." % path)

def fixRpathComponent(actions, elfPath, rpath):
    """actions is a list of *Action objects.  elfPath is the absolute path to
    the ELF file being fixed up.  rpath is an RPATH component to fix up.
    """
    absPath = expandRpathPath(rpath, elfPath)
    newRpath = rpath
    for action in actions:
        if action.matchesFilter(absPath):
            return action.filter(newRpath, absPath, elfPath)
    return newRpath

def expandRpathPath(rpath, elfPath):
    originPath = os.path.dirname(elfPath)
    if rpath.startswith("$ORIGIN"):
        assert(rpath == "$ORIGIN" or rpath.startswith("$ORIGIN/"))
        return os.path.abspath(rpath.replace("$ORIGIN", originPath))
    else:
        if not os.path.isabs(rpath):
            sys.exit("Error: ELF file '%s' has relative RPATH component '%s'" %
                     (elfPath, rpath))
        # rpath is already absolute, but call abspath to normalize it.
        return os.path.abspath(rpath)

class Action(object):
    def __init__(self, path):
        self._path = path
    def matchesFilter(self, absPath):
        return isChildPath(self._path, absPath)

class DiscardAction(Action):
    def __init__(self, path):
        super(DiscardAction, self).__init__(path)
    def filter(self, curRpath, curAbsPath, elfPath):
        return None

class AcceptAction(Action):
    def __init__(self, path):
        super(AcceptAction, self).__init__(path)
    def filter(self, curRpath, curAbsPath, elfPath):
        return curRpath

class RejectAction(Action):
    def __init__(self, path):
        super(RejectAction, self).__init__(path)
    def filter(self, curRpath, curAbsPath, elfPath):
        sys.exit("Error: ELF file '%s' has RPATH component '%s' inside "
                 "reject path '%s'." % (elfPath, curRpath, self._path))

class UseOriginAction(Action):
    def __init__(self, path):
        super(UseOriginAction, self).__init__(path)
    def filter(self, curRpath, curAbsPath, elfPath):
        originDir = os.path.dirname(elfPath)
        relPath = os.path.relpath(curAbsPath, originDir)
        if relPath == ".":
            return "$ORIGIN"
        else:
            return "$ORIGIN/" + relPath

if __name__ == "__main__":
    main()
