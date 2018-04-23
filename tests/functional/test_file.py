
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
