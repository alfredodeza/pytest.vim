

class TestErrors(object):

    def test_reports_import_error(self, vim, path):
        vim.raw_command("e %s" % path('test_import_error.py'))
        result = vim.command("Pytest file")
        assert "py.test ==> Running tests for entire file" in result
        result = vim.get_buffer().split('\n')[-1]
        assert "Line: 1 " in result
        assert "==>> ImportError " in result
        assert " No module named DoesNotExistModule" in result
        assert "test_import_error.py" in result

    def test_reports_syntax_error(self, vim, path):
        vim.raw_command("e %s" % path('test_syntax_error.py'))
        result = vim.command("Pytest file")
        assert "py.test ==> Running tests for entire file" in result
        result = vim.get_buffer().split('\n')[-1]
        assert "Line: 1 " in result
        assert "==>> SyntaxError " in result
        assert " invalid syntax ==>> " in result
        assert "/test_syntax_error.py" in result
