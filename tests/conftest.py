import subprocess
import pytest
import re
import os
import time
import logging

logger = logging.getLogger(__name__)


def run(command, **kw):
    """
    Fire and forget, do not capture anything
    """
    command_msg = "Running command: %s" % ' '.join(command)
    logger.info(command_msg)

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE,
        close_fds=True,
        **kw
    )
    return process


def call(command, **kw):
    """
    Similar to ``subprocess.Popen`` with the following changes:

    * returns stdout, stderr, and exit code (vs. just the exit code)
    * logs the full contents of stderr and stdout (separately) to the file log

    By default, no terminal output is given, not even the command that is going
    to run.

    Useful when system calls are needed to act on output, and that same output
    shouldn't get displayed on the terminal.

    :param terminal_verbose: Log command output to terminal, defaults to False, and
                             it is forcefully set to True if a return code is non-zero
    """
    terminal_verbose = kw.pop('terminal_verbose', False)
    command_msg = "Running command: %s" % ' '.join(command)
    logger.info(command_msg)

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE,
        close_fds=True,
        **kw
    )
    stdout_stream = process.stdout.read()
    stderr_stream = process.stderr.read()
    returncode = process.wait()
    if not isinstance(stdout_stream, str):
        stdout_stream = stdout_stream.decode('utf-8')
    if not isinstance(stderr_stream, str):
        stderr_stream = stderr_stream.decode('utf-8')

    if returncode != 0:
        # set to true so that we can log the stderr/stdout that callers would
        # do anyway
        terminal_verbose = True

    # the following can get a messed up order in the log if the system call
    # returns output with both stderr and stdout intermingled. This separates
    # that.
    for line in stdout_stream.splitlines():
        logger.info('stdout', line, terminal_verbose)
    for line in stderr_stream.splitlines():
        logger.info('stderr', line, terminal_verbose)
    return stdout_stream, stderr_stream, returncode


class Vim(object):

    def __init__(self, servername='PYTEST_VIM'):
        self.servername = servername.upper()

    def normal(self, val='', remap=True):
        self.feedkeys('<esc>' + val, remap, addUndoEntry=True)
        return
        self.raw_command(val)

    def insert(self, val):
        self.normal("i" + val)

    def getline(self, number='.'):
        return self.evaluate("getline(%s)" % number)

    def line(self):
        return int(self.evaluate("line('.')"))

    def col(self):
        return int(self.evaluate("col('.')"))

    @property
    def is_running(self):
        out, err, code = call(['gvim', '--serverlist'])
        for line in out.split('\n'):
            logger.info(line)
            if self.servername in line:
                return True
        return False

    def mode(self):
        return self.evaluate('mode(1)').strip('\r\n')

    # XXX
    #def startVanilla(self):
    #    self.start(VimDriver.EmptyVimRc)

    def start(self, vimrc=None):
        if self.is_running:
            return

        command = ['gvim', '--servername', self.servername]

        if vimrc:
            self.vimrc = vimrc
            command.extend(['-u', vimrc])

        run(command)

        tries = 0
        interval = 0.2
        while not self.is_running:
            if tries == 10:
                raise RuntimeError('Unable to start Vim after 10 tries')
            time.sleep(interval)
            tries += 1
        logger.info('vim is now running!')

    def stop(self):
        # Have to use raw because otherwise it will get errors when it tries to
        # parse result from the closed vim
        self.raw_command('qall!')

    # Similar to _rawType except a bit more flexible since you can choose whether to remap or not
    def feedkeys(self, keys, remap=True, addUndoEntry=False):

        if addUndoEntry:
            self._addUndoEntry()

        # This seems to be equivalent when remap == False
        #self._rawType(keys)

        rawText = r'call feedkeys("%s", "%s")' % (self._escapeFeedKeys(keys), 'm' if remap else 'n')
        self.raw_command(rawText)

    def undo(self):
        self.command('undo')

    def redo(self):
        self.command('redo')

    def command(self, cmd):
        self.normal()

        varName = "vimdriver_temp"
        self.raw_command("redir => %s" % varName)
        self.raw_command("silent %s" % cmd)
        self.raw_command("redir end")

        result = self.evaluate(varName).lstrip('\r\n')

        if re.match('^E\d+:', result):
            raise Exception("Error while executing command '%s': %s" % (cmd, result))

        return result.strip('\n')

    def evaluate(self, expr):
        out, err, code = call(['gvim', '--servername', self.servername, '--remote-expr', expr])

        if re.match('^E\d+:', out):
            raise RuntimeError("Error while running evaluate with '%s': %s" % (expr, out))

        return out.strip('\n')

    def getreg(self, reg):
        return self.evaluate("getreg('%s')" % reg)

    def clearBuffer(self):
        self.normal(r'gg"_dG', remap = False)

    def get_buffer(self):
        self.normal("ggVGy")
        return self.getreg('"0')

    def _escapeRawType(self, keys):
        return keys
    # XXX
    #    return StringUtil.escape(keys, r'\\|"')

    def _escapeRawCommand(self, val):
        return re.sub(r'\<\b(\w+)\b\>', r'\<\1_<bs>>', val)

    def _escapeFeedKeys(self, val):
        val = val.replace('"', '\\"')
        return val

    def _addUndoEntry(self):
        self.raw_command("set undolevels=%s" % self.evaluate("&ul"))

    # Executes the given key
    # eg: rawCommand(r'echo "hi"')
    def raw_command(self, keys):
        mode = self.mode
        prefix = ''
        suffix = ''

        if mode == 'n':
            prefix = ':'
        elif mode == 'i':
            prefix = '<c-o>:'
        elif mode == 'v' or mode == 'V':
            prefix = ':<c-w>'
            suffix = 'gv'
        else:
            prefix = '<esc>:'

        self._rawType("%s%s<cr>%s" % (prefix, self._escapeRawCommand(keys), suffix))

    # Just forwards the given keys directly to vim
    # Useful if you don't want to exit visual/insert mode
    def _rawType(self, keys):
        cmd = ['gvim', '--servername', self.servername,  '--remote-send',  self._escapeRawType(keys)]
        call(cmd)


@pytest.fixture(scope="function")
def path():
    dir_path = os.path.dirname(os.path.realpath(__file__))
    def get_path(fixture_name):
        return os.path.join(dir_path, 'fixtures/%s' % fixture_name)
    return get_path


@pytest.fixture()
def custom_executable(tmpfile):
    def apply(name=None):
        name = name or 'pytest4'
        pytest_executable = '%s/bin/py.test' % os.getenv('VIRTUAL_ENV')
        custom_executable = '%s/bin/%s' % (os.getenv('VIRTUAL_ENV'), name)
        if not os.path.exists(custom_executable):
            os.symlink(pytest_executable, custom_executable)
        return custom_executable

    def fin():
        os.remove(custom_executable)

@pytest.fixture
def tmpfile(tmpdir):
    """
    Create a temporary file, optionally filling it with contents, returns an
    absolute path to the file when called
    """
    def generate_file(name='vimrc', contents='', directory=None):
        directory = directory or str(tmpdir)
        path = os.path.join(directory, name)
        with open(path, 'w') as fp:
            fp.write(contents)
        return path
    return generate_file


@pytest.fixture(scope="class")
def vim(request):
    server = Vim(servername='pytest_vim_class')
    server.start()
    server.raw_command('let g:pytest_use_async=0')

    def fin():
        logger.info('stopping vim server')
        server.stop()
    request.addfinalizer(fin)
    return server  # provide the fixture value


@pytest.fixture(scope="class")
def vim_customized(request):
    server = Vim(servername='pytest_vim_class')
    def apply(vimrc_path):
        server.start(vimrc_path)
        server.raw_command('let g:pytest_use_async=0')
        return server  # provide the fixture value

    def fin():
        logger.info('stopping vim server')
        server.stop()
    request.addfinalizer(fin)

    return apply
