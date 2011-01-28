pytest.vim
----------
A simple way of running your tests (with py.test) from within VIM.

Talking with Holger Krekel (original author of py.test and vim user) we thought
it would be neat to be able to call it from vim and get some immediate results.

This is especially useful when you are tweaking and do not want to be moving
around between the terminal and your vim session.

Screenshots:

Failing Tests
.. image:: http://www.flickr.com/photos/aldegaz/5395135575

Passing Tests
.. image:: http://www.flickr.com/photos/aldegaz/5395135539

Usage
-----

This plugin provides a single command::

    Pytest

It can take a few arguments that are able to be tab-completed. These arguments
are::

    class
    method
    file

As you may expect, those will focus on the tests for the current class, method
or the whole file.

If you are in a class and want to run all the tests for that class, you would
call this plugin like::

    :Pytest class

Whenever a command is triggered a small message displays informing you that
the plugin is running a certain action. In the above call, you would see 
something like this::

    Running tests for class TestMyClass

When tests are successful a green bar appears. If you have any number of fails
you get a red bar with a line-by-line list of line numbers and errors.

I strongly encourage a mapping for the above actions. For example, if you
wanted leader mappings you would probably do them like this::

    " Pytest
    nmap <silent><Leader>f <Esc>:Pytest file<CR>
    nmap <silent><Leader>c <Esc>:Pytest class<CR>
    nmap <silent><Leader>m <Esc>:Pytest method<CR>

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

