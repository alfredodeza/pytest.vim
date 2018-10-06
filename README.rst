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

Installation
============
This plugin is a *file type plugin*, which means that it is only enabled when
the matching file type (Python in this case) is being edited. To ensure the
plugin works correctly, the following setting must be enabled (usually in
``.vimrc``)::

    filetype on

Without any install frameworks, all is needed is to drop the ``pytest.vim``
file in one of the Vim runtime paths, in the subdirectory ``ftplugin/python/``

If using ``vim-pathogen`` the whole repository can be placed in
``.vim/bundle``. Otherwise please follow the guidelines of the package manager
of choice.


Usage
=====

This plugin provides a single command::

    Pytest

All arguments are able to be tab-completed. To ensure the plugin will be
loaded, these settings *must* be enabled::

    :set filetype on
    :set filetype plugin on


Python Objects
--------------
For running tests the plugin provides 4 arguments with an optional one.
These arguments are::

    class
    method
    function
    file
    project


As you may expect, those will focus on the tests for the current class, method,
function, the file or project.

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

If you are working on a project, this plugin provides a way to run tests from
anywhere within the project tree like this::

    " Tests are in /path/to/project/tests/
    " Working on   /path/to/project/module/file.py
    :Pytest project

This would run all of the project tests (in /path/to/project/tests/) related
to the active project. This works with a directory called "tests" or a file
called "tests.py". It should be noted that this plugin searches upward through
the directory tree, taking the first entry it finds. For example::

    " Working on /home/project/file.py
    /home/tests/          " This set of tests will not be run
    /home/project/tests/  " This set of tests will be run

It is easy to check which set of tests will be run (the project test working
directory)::

    :Pytest projecttestwd

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

Again the above command shows ``class`` but you can use this with all the objects
supported (``class``, ``method``, ``function`` and ``file``).

Shell Support
-------------
This plugin provides a way to have a better shell experience when running
``verbose`` or ``pdb`` flags by using native Vim (only available with Vim 8 and
newer).

`looponfail`
------------
This is an *extra* option that will allow you to loop (run again) on fail.
If the test fails, then this option will make Vim run the same test again as
soon as the file is written.

Once the test passes, it will no longer re-run the tests again. This option is
available for ``class``, ``method``, ``function`` and ``file``.
You would call it like::

    :Pytest method looponfail

`clear`
-------
If for some reason you need to reset and clear all global variables that affect
the plugin you can do so by running the following command::

    :Pytest clear

This is specifically useful when ``looponfail`` has been enabled and you want to
stop its automatic behavior. Remember that ``looponfail`` will run every time you
write the buffer and will keep doing so unless your test passes.

Fast Next/Previous Error
------------------------
Now when the Failed Error list is open and it as focus (cursor is currently in
that window) you can move to the next or previous failed test line by using the
arrow keys, ``j``/``k``  or ``Ctrl-n`` / ``Ctrl-p``

Whenever you hit the bottom or the top of the list, you can loop around it!

If you hit an error that displays not the previous window (e.g. your test file)
then a message will state that it is skipping.


``neovim`` support
------------------
There is full support for ``neovim``. Tests will never block and will be
completely asynchronous. When the test run ends the familiar green (or red) bar
will be displayed.

Some changes where made as well to support interactive terminal sessions (when
using ``-s`` and ``--pdb`` for example) to make use of the terminal support
from ``neovim``.

**warning**: When calling a test, the user needs to wait until that test ends
before calling another test, otherwise, the plugin will kill the first in order
to call the last one.

Configuration
-------------

Custom executable
^^^^^^^^^^^^^^^^^
By default, the plugin uses ``py.test`` as the executable to run tests. Some
Linux distros mangle the name to provide both Python 3 and Python 2 variants
which forces one to pick a different name for the executable.

This can be customized with either the filename of the executable or the path
to the executable needed. For example, for a ``py.test-3`` name, it could be
set in this way::

    let g:pytest_executable = "py.test-3"

Test directory
^^^^^^^^^^^^^^
By default the project test directory is ``tests`` (i.e. test files are assumed
to be in ``/path/to/project/test``). The global variable ``pytest_test_dir`` may
be used to change this, for example::

    let g:pytest_test_dir = 'test_suite'

configures the test directory to be ``/path/to/project/test_suite``

Test file
^^^^^^^^^
By default the test file is ``tests.py``.The global variable
``pytest_test_file`` may be used to change this, for example::

    let g:pytest_test_file = 'test_myproj.py'

configures the test file to be ``/path/to/project/tests/test_myproj.py``
(assuming the default value for the project test directory)

License
-------

MIT
Copyright (c) 2011-2015 Alfredo Deza <alfredo [at] deza [dot] pe>

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

