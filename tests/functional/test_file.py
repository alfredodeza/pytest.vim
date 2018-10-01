import os
from os.path import dirname

class TestFileObjects(object):

    def test_runs_on_whole_file(self, vim, path):
        vim.raw_command("e %s" % path('test_functions.py'))
        vim.normal("/foo")
        result = vim.command("Pytest file")
        assert "py.test ==> Running tests for entire file" in result
        vim.normal("<cr>")
        vim.raw_command("Pytest session")
        vim.raw_command("wincmd p")
        result = vim.get_buffer()
        assert "1 failed, 1 passed" in result

    def test_no_tests(self, vim, path):
        vim.raw_command("e %s" % path('test_empty.py'))
        result = vim.command("Pytest file")
        assert "0 collected tests, no tests ran. See :Pytest session" in result


base_vimrc = """
syntax on                                  " always want syntax highlighting
filetype on                                " enables filetype detection
filetype plugin on                         " enables filetype specific plugins
filetype indent on                         " respect filetype indentation
set nocompatible
set rtp+=%s /Users/alfredo/vim/pytest.vim
""" %  dirname(dirname(dirname(__file__)))


class TestErrorsCustomPytestExecPath(object):

    def test_report_uses_custom_executable(self, vim_customized, path, tmpfile):
        pytest_executable = '%s/bin/py.test' % os.getenv('VIRTUAL_ENV')
        custom_executable = '%s/bin/pytest4' % os.getenv('VIRTUAL_ENV')
        if not os.path.exists(custom_executable):
            os.symlink(pytest_executable, custom_executable)
        vimrc = tmpfile(contents=base_vimrc+'let g:pytest_executable = "pytest4"')
        vim = vim_customized(vimrc)
        vim.raw_command("e %s" % path('test_functions.py'))
        result = vim.command("Pytest file")
        assert "pytest4 ==> Running tests for entire file" in result


class TestErrorsCustomPytestExecFile(object):

    def test_report_uses_custom_executable_path(self, vim_customized, path, tmpfile):
        pytest_executable = '%s/bin/py.test' % os.getenv('VIRTUAL_ENV')
        custom_executable = '%s/bin/pytest4' % os.getenv('VIRTUAL_ENV')
        if not os.path.exists(custom_executable):
            os.symlink(pytest_executable, custom_executable)
        vimrc = tmpfile(contents=base_vimrc+'let g:pytest_executable = "%s"' % custom_executable)
        vim = vim_customized(vimrc)
        vim.raw_command("e %s" % path('test_functions.py'))
        result = vim.command("Pytest file")
        assert "pytest4 ==> Running tests for entire file" in result

