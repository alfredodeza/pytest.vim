import os
from os.path import dirname


class TestFunctionObjects(object):

    def test_invalid_signature_is_an_error(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/def foo")
        result = vim.command("Pytest function")
        vim.normal("<cr>")
        vim.raw_command('wincmd p')
        session = vim.get_buffer()
        assert "No valid test names found. No tests ran." in result
        assert "See :Pytest session" in result

    def test_no_session(self, vim, path):
        vim.raw_command("e %s" % path('test_empty.py'))
        vim.command("Pytest function")
        result = vim.command("Pytest session")
        assert result == "There is currently no saved last session to display"

    def test_empty(self, vim, path):
        vim.normal(":e ../paths/test_empty.py")
        result = vim.command("Pytest function")
        assert result == "Unable to find a matching function for testing"

    def test_session_pass(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/test_foo")
        vim.raw_command("Pytest function")
        vim.normal("<cr>")
        vim.raw_command("Pytest session")
        vim.raw_command("wincmd p")
        result = vim.get_buffer()
        assert "test session starts" in result
        assert "platform " in result
        assert "rootdir: /" in result
        assert "collected 1 item" in result
        assert "1 passed in" in result

    def test_method_on_function_does_not_work(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/test_foo")
        result = vim.command("Pytest method")
        assert "Unable to find a matching method for testing" ==  result

    def test_class_on_function_does_not_work(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/test_foo")
        result = vim.command("Pytest class")
        assert "Unable to find a matching class for testing" ==  result

    def test_cursor_does_not_change_position(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/test_foo")
        # move down to where the assert happens
        vim.normal('jfT')
        before_position = vim.evaluate("getpos('.')")
        result = vim.command("Pytest function")
        after_position = vim.evaluate("getpos('.')")
        assert before_position == after_position


base_vimrc = """
syntax on                                  " always want syntax highlighting
filetype on                                " enables filetype detection
filetype plugin on                         " enables filetype specific plugins
filetype indent on                         " respect filetype indentation
set nocompatible
set rtp+=%s /Users/alfredo/vim/pytest.vim
""" %  dirname(dirname(dirname(__file__)))


class TestRunningCustomPytestExecPath(object):

    def test_session_custom_executable(self, vim_customized, path, tmpfile, custom_executable):
        vimrc = tmpfile(contents=base_vimrc+'let g:pytest_executable = "pytest4"')
        pytest_executable = '%s/bin/py.test' % os.getenv('VIRTUAL_ENV')
        custom_executable = '%s/bin/pytest4' % os.getenv('VIRTUAL_ENV')
        if not os.path.exists(custom_executable):
            os.symlink(pytest_executable, custom_executable)
        vimrc = tmpfile(contents=base_vimrc+'let g:pytest_executable = "pytest4"')
        vim = vim_customized(vimrc)
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/test_foo")
        result = vim.command("Pytest function")
        assert "pytest4 ==> Running tests for function test_foo" in result
