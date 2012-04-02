pytest.vim
==========
**follow @alfredodeza for updates**

A simple way of running your tests (with py.test) from within VIM.

Talking with Holger Krekel (original author of py.test and vim user) we thought
it would be neat to be able to call it from vim and get some immediate results.

This is especially useful when you are tweaking and do not want to be moving
around between the terminal and your vim session.

* Screencast: http://vimeo.com/19774046

Showing a Session
-----------------

.. image:: https://github.com/alfredodeza/pytest.vim/raw/master/extras/session.png


Fail tests and Errors
---------------------

.. image:: https://github.com/alfredodeza/pytest.vim/raw/master/extras/fails.png


Usage
=====

This plugin provides a single command::

    Pytest

All arguments are able to be tab-completed.

Python Objects
--------------
For running tests the plugin provides 4 arguments with an optional one. 
These arguments are::

    class
    method
    function
    file


As you may expect, those will focus on the tests for the current class, method,
function or the whole file.

If you are in a class and want to run all the tests for that class, you would
call this plugin like::

    :Pytest class

Whenever a command is triggered a small message displays informing you that
the plugin is running a certain action. In the above call, you would see 
something like this::

    Running tests for class TestMyClass

If you would like to see the complete py.test output you can add an optional `verbose`
flag to any of the commands for Pytest. For the previous command, it would
look like::

    :Pytest class verbose

This would open a split scratch buffer that you can fully interact with. You
can close this buffer with ':wq' or you can hit 'q' at any moment in that buffer
to close it.

When tests are successful a green bar appears. If you have any number of fails
you get a red bar with a line-by-line list of line numbers and errors.

I strongly encourage a mapping for the above actions. For example, if you
wanted leader (the leader key is '\' by default) mappings you would 
probably do them like this::

    " Pytest
    nmap <silent><Leader>f <Esc>:Pytest file<CR>
    nmap <silent><Leader>c <Esc>:Pytest class<CR>
    nmap <silent><Leader>m <Esc>:Pytest method<CR>


Errors and Fails
----------------
This plugin also provides a way to jump to the actual error. Since errors can
be living in a file other than your test (e.g. a syntax error in your source
that triggers an assertion errro in the current file) you can also jump to that
file. The list of jumping-to-error arguments are::

    first
    last
    next 
    previous
    end


Pytest **DOES NOT JUMP AUTOMATICALLY** to errors. You have to call the action. When
you call a jump, a split buffer is opened with a file (if it is not the same as
the one you are currently editing) and places you in the same line number were
the error was reported.

If an error starts in the current file but ends on a different one, you can
call that ``end of error`` by calling ``:Pytest end``.

Output
------
Finally, you can also display in a split scratch buffer either the last list
of failed tests (with line numbers, errors and paths) or the last ``py.test``
session (similar to what you would see in a terminal). The arguments that 
you would need to provide for such actions are::

    session
    fails

``session`` is the buffer with a similar output to the terminal (but with
syntax highlighting) and ``fails`` has the list of last fails with the
exceptions.

If you are looking for the actual error, we have stripped it from the normal
reporting but you can call it at any time with::

    :Pytest error


The reason behind this is that as soon as you hit any key, the quick display
goes away. With a split buffer you are in control and you can quit that window
when you decide -  while you work on fixing errors.

The commands that open the last session and the last fails are toggable: they
will close the scratch buffer if it is open or will open it if its closed.

PDB
---
If you have ever needed to get into a `pdb` session and debug your code, you 
already know that it is a horrible experience to be jumping between Vim and
the terminal. **pytest.vim** now includes a way of calling it with 2 options
that will let you drop to a shell (inside Vim!) and control your pdb session.

**py.test pdb on fail**

Use this option when you need to use the built-in pdb support from py.test 
(e.g. drop to pdb when a test fails).

::

    :Pytest class --pdb

The above command shows `class` but you can use this with all the objects
supported (`class`, `method` , `function` and `file`).


**py.test no capture**

If you are placing `import pdb; pdb.set_trace()` somewhere in your code and 
you want to drop to pdb when that code gets executed, then you need to pass
in the no-capture flag::

    :Pytest class -s

Again the above command shows `class` but you can use this with all the objects
supported (`class`, `method`, `function` and `file`).

Shell Support
-------------
This plugin provides a way to have a better shell experience when running
`verbose` or `pdb` flags by using the `Conque.vim` plugin. If you have this
most excellent piece of Vim plugin (see: http://www.vim.org/scripts/script.php?script_id=2771)
then `pytest.vim` will use that instead of Vim's own dumb shell environment.

`looponfail` 
---------------
This is an *extra* option that will allow you to loop (run again) on fail.
If the test fails, then this option will make Vim run the same test again as 
soon as the file is written.

Once the test passes, it will no longer re-run the tests again. This option is
available for `class`, `method`, `function` and `file`.
You would call it like::

    :Pytest method looponfail

`clear`
-------
If for some reason you need to reset and clear all global variables that affect
the plugin you can do so by running the following command::

    :Pytest clear

This is specifically useful when `looponfail` has been enabled and you want to
stop its automatic behavior. Remember that `looponfail` will run every time you 
write the buffer and will keep doing so unless your test passes.

Fast Next/Previous Error
------------------------
Now when the Failed Error list is open and it as focus (cursor is currently in
that window) you can move to the next or previous failed test line by using the
arrow keys, `j`/`k`  or `Ctrl-n` / `Ctrl-p`

Whenever you hit the bottom or the top of the list, you can loop around it!

If you hit an error that displays not the previous window (e.g. your test file)
then a message will state that it is skipping.


Development Release
===================
If you are checking out this plugin from the Git repository instead of an
official release from vim.org then you need to know that some
things/implementations are considered *alpha* (they WILL break!). I usually
list them here, so please take note before using them.

The current development version does not have any un-released features.


License
-------

MIT
Copyright (c) 2011 Alfredo Deza <alfredodeza [at] gmail [dot] com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

