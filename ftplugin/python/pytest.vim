" File:        pytest.vim
" Description: Runs the current test Class/Method/Function/File with
"              py.test
" Maintainer:  Alfredo Deza <alfredodeza AT gmail.com>
" License:     MIT
"============================================================================


if exists("g:loaded_pytest") || &cp
  finish
endif


" Global variables for registering next/previous error
let g:pytest_session_errors    = {}
let g:pytest_session_error     = 0
let g:pytest_last_session      = ""
let g:pytest_looponfail        = 0


function! s:PytestSyntax() abort
  let b:current_syntax = 'pytest'
  syn match PytestPlatform              '\v^(platform(.*))'
  syn match PytestTitleDecoration       "\v\={2,}"
  syn match PytestTitle                 "\v\s+(test session starts)\s+"
  syn match PytestCollecting            "\v(collecting\s+(.*))"
  syn match PytestPythonFile            "\v((.*.py\s+))"
  syn match PytestFooterFail            "\v\s+((.*)(failed|error) in(.*))\s+"
  syn match PytestFooter                "\v\s+((.*)passed in(.*))\s+"
  syn match PytestFailures              "\v\s+(FAILURES|ERRORS)\s+"
  syn match PytestErrors                "\v^E\s+(.*)"
  syn match PytestDelimiter             "\v_{3,}"
  syn match PytestFailedTest            "\v_{3,}\s+(.*)\s+_{3,}"

  hi def link PytestPythonFile          String
  hi def link PytestPlatform            String
  hi def link PytestCollecting          String
  hi def link PytestTitleDecoration     Comment
  hi def link PytestTitle               String
  hi def link PytestFooterFail          String
  hi def link PytestFooter              String
  hi def link PytestFailures            Number
  hi def link PytestErrors              Number
  hi def link PytestDelimiter           Comment
  hi def link PytestFailedTest          Comment
endfunction


function! s:PytestFailsSyntax() abort
  let b:current_syntax = 'pytestFails'
  syn match PytestQDelimiter            "\v\s+(\=\=\>\>)\s+"
  syn match PytestQLine                 "Line:"
  syn match PytestQPath                 "\v\s+(Path:)\s+"
  syn match PytestQEnds                 "\v\s+(Ends On:)\s+"

  hi def link PytestQDelimiter          Comment
  hi def link PytestQLine               String
  hi def link PytestQPath               String
  hi def link PytestQEnds               String
endfunction


function! s:LoopOnFail(type)

    augroup pytest_loop_autocmd
        au!
        if g:pytest_looponfail == 0
            return
        elseif a:type == 'method'
            autocmd! BufWritePost *.py call s:LoopProxy('method')
        elseif a:type == 'class'
            autocmd! BufWritePost *.py call s:LoopProxy('class')
        elseif a:type == 'function'
            autocmd! BufWritePost *.py call s:LoopProxy('function')
        elseif a:type == 'file'
            autocmd! BufWritePost *.py call s:LoopProxy('file')
        endif
    augroup END

endfunction


function! s:LoopProxy(type)
    " Very repetitive function, but allows specific function
    " calling when autocmd is executed
    if g:pytest_looponfail == 1
        if a:type == 'method'
            call s:ThisMethod(0, 'False')
        elseif a:type == 'class'
            call s:ThisClass(0, 'False')
        elseif a:type == 'function'
            call s:ThisFunction(0, 'False')
        elseif a:type == 'file'
            call s:ThisFile(0, 'False')
        endif

        " FIXME Removing this for now until I can find
        " a way of getting the bottom only on fails
        " Go to the very bottom window
        "call feedkeys("\<C-w>b", 'n')
    else
        au! pytest_loop_autocmd
    endif
endfunction


" Close the Pytest buffer if it is the last one open
function! s:CloseIfLastWindow()
  if winnr("$") == 1
    q
  endif
endfunction


function! s:GoToInlineError(direction)
    let orig_line = line('.')
    let last_line = line('$')

    " Move to the line we need
    let move_to = orig_line + a:direction

    if move_to > last_line
        let move_to = 1
        exe move_to
    elseif move_to <= 1
        let move_to = last_line
        exe move_to
    else
        exe move_to
    endif

    if move_to == 1
        let _num = move_to
    else
        let _num = move_to - 1
    endif

    "  Goes to the current open window that matches
    "  the error path and moves you there. Pretty awesome
    if (len(g:pytest_session_errors) > 0)
        let select_error = g:pytest_session_errors[_num]
        let line_number  = select_error['file_line']
        let error_path   = select_error['file_path']
        let exception    = select_error['exception']

        " Go to previous window
        exe 'wincmd p'
        let file_name    = expand("%:t")
        if error_path =~ file_name
            execute line_number
            execute 'normal! zz'
            exe 'wincmd p'
            let orig_line = _num+1
            exe orig_line
            let message = "Failed test: " . _num . "\t ==>> " . exception
            call s:Echo(message, 1)
            return
        else " we might have an error on another file
            let message = "Failed test on different buffer. Skipping..."
            call s:Echo(message, 1)
            exe 'wincmd p'
        endif

    else
        call s:Echo("Failed test list is empty")
    endif
endfunction

function! s:GoToError(direction)
    "   0 goes to first
    "   1 goes forward
    "  -1 goes backwards
    "   2 goes to last
    "   3 goes to the end of current error
    call s:ClearAll()
    let going = "First"
    if (len(g:pytest_session_errors) > 0)
        if (a:direction == -1)
            let going = "Previous"
            if (g:pytest_session_error == 0 || g:pytest_session_error == 1)
                let g:pytest_session_error = 1
            else
                let g:pytest_session_error = g:pytest_session_error - 1
            endif
        elseif (a:direction == 1)
            let going = "Next"
            if (g:pytest_session_error != len(g:pytest_session_errors))
                let g:pytest_session_error = g:pytest_session_error + 1
            endif
        elseif (a:direction == 0)
            let g:pytest_session_error = 1
        elseif (a:direction == 2)
            let going = "Last"
            let g:pytest_session_error = len(g:pytest_session_errors)
        elseif (a:direction == 3)
            if (g:pytest_session_error == 0 || g:pytest_session_error == 1)
                let g:pytest_session_error = 1
            endif
            let select_error = g:pytest_session_errors[g:pytest_session_error]
            let line_number = select_error['file_line']
            let error_path = select_error['file_path']
            let exception = select_error['exception']
            let file_name = expand("%:t")
            if error_path =~ file_name
                execute line_number
            else
                call s:OpenError(error_path)
                execute line_number
            endif
            let message = "End of Failed test: " . g:pytest_session_error . "\t ==>> " . exception
            call s:Echo(message, 1)
            return
        endif

        if (a:direction != 3)
            let select_error = g:pytest_session_errors[g:pytest_session_error]
            let line_number = select_error['line']
            let error_path = select_error['path']
            let exception = select_error['exception']
            let file_name = expand("%:t")
            if error_path =~ file_name
                execute line_number
            else
                call s:OpenError(error_path)
                execute line_number
            endif
            let message = going . " Failed test: " . g:pytest_session_error . "\t ==>> " . exception
            call s:Echo(message, 1)
            return
        endif
    else
        call s:Echo("Failed test list is empty")
    endif
endfunction


function! s:Echo(msg, ...)
    redraw!
    let x=&ruler | let y=&showcmd
    set noruler noshowcmd
    if (a:0 == 1)
        echo a:msg
    else
        echohl WarningMsg | echo a:msg | echohl None
    endif

    let &ruler=x | let &showcmd=y
endfun


" Always goes back to the first instance
" and returns that if found
function! s:FindPythonObject(obj)
    let orig_line   = line('.')
    let orig_col    = col('.')
    let orig_indent = indent(orig_line)

    if (a:obj == "class")
        let objregexp  = '\v^\s*(.*class)\s+(\w+)\s*'
    elseif (a:obj == "method")
        let objregexp = '\v^\s*(.*def)\s+(\w+)\s*\(\s*(self[^)]*)'
    else
        let objregexp = '\v^\s*(.*def)\s+(\w+)\s*\(\s*(.*self)@!'
    endif

    let flag = "Wb"

    while search(objregexp, flag) > 0
        "
        " Very naive, but if the indent is less than or equal to four
        " keep on going because we assume you are nesting.
        "
        if indent(line('.')) <= 4
            return 1
        endif
    endwhile

endfunction


function! s:NameOfCurrentClass()
    let save_cursor = getpos(".")
    normal! $<cr>
    let find_object = s:FindPythonObject('class')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *class \+\(\w\+\)')
        return match_result[1]
    endif
endfunction


function! s:NameOfCurrentMethod()
    let save_cursor = getpos(".")
    normal! $<cr>
    let find_object = s:FindPythonObject('method')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *def \+\(\w\+\)')
        return match_result[1]
    endif
endfunction


function! s:NameOfCurrentFunction()
    let save_cursor = getpos(".")
    normal! $<cr>
    let find_object = s:FindPythonObject('function')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *def \+\(\w\+\)')
        return match_result[1]
    endif
endfunction


function! s:CurrentPath()
    let cwd = expand("%:p")
    return cwd
endfunction


function! s:RunInSplitWindow(path)
    let cmd = "py.test --tb=short " . a:path
    if exists("g:ConqueTerm_Loaded")
        call conque_term#open(cmd, ['split', 'resize 20'], 0)
    else
        let command = join(map(split(cmd), 'expand(v:val)'))
        let winnr = bufwinnr('PytestVerbose.pytest')
        silent! execute  winnr < 0 ? 'botright new ' . 'PytestVerbose.pytest' : winnr . 'wincmd w'
        setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=pytest
        silent! execute 'silent %!'. command
        silent! execute 'resize ' . line('$')
        silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
        call s:PytestSyntax()
    endif
    autocmd! BufEnter LastSession.pytest call s:CloseIfLastWindow()
endfunction


function! s:OpenError(path)
	let winnr = bufwinnr('GoToError.pytest')
	silent! execute  winnr < 0 ? 'botright new ' . ' GoToError.pytest' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
    silent! execute ":e " . a:path
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    autocmd! BufEnter LastSession.pytest call s:CloseIfLastWindow()
endfunction


function! s:ShowError()
    call s:ClearAll()
    if (len(g:pytest_session_errors) == 0)
        call s:Echo("No Failed test error from a previous run")
        return
    endif
    if (g:pytest_session_error == 0)
        let error_n = 1
    else
        let error_n = g:pytest_session_error
    endif
    let error_dict = g:pytest_session_errors[error_n]
    if (error_dict['error'] == "")
        call s:Echo("No failed test error saved from last run.")
        return
    endif

	let winnr = bufwinnr('ShowError.pytest')
	silent! execute  winnr < 0 ? 'botright new ' . ' ShowError.pytest' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile number nowrap
    autocmd! BufEnter LastSession.pytest call s:CloseIfLastWindow()
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    let line_number = error_dict['file_line']
    let error = error_dict['error']
    let message = "Test Error: " . error
    call append(0, error)
    exe '0'
    exe '0|'
    silent! execute 'resize ' . line('$')
    exe 'wincmd p'
endfunction


function! s:ShowFails(...)
    call s:ClearAll()
    au BufLeave *.pytest echo "" | redraw
    if a:0 > 0
        let gain_focus = a:0
    else
        let gain_focus = 0
    endif
    if (len(g:pytest_session_errors) == 0)
        call s:Echo("No failed tests from a previous run")
        return
    endif
	let winnr = bufwinnr('Fails.pytest')
	silent! execute  winnr < 0 ? 'botright new ' . 'Fails.pytest' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=pytest
    let blank_line = repeat(" ",&columns - 1)
    exe "normal! i" . blank_line
    hi RedBar ctermfg=white ctermbg=red guibg=red
    match RedBar /\%1l/
    for err in keys(g:pytest_session_errors)
        let err_dict    = g:pytest_session_errors[err]
        let line_number = err_dict['line']
        let exception   = err_dict['exception']
        let path_error  = err_dict['path']
        let ends        = err_dict['file_path']
        if (path_error == ends)
            let message = printf('Line: %-*u ==>> %-*s ==>> %s', 6, line_number, 24, exception, path_error)
        else
            let message = printf('Line: %-*u ==>> %-*s ==>> %s', 6, line_number, 24, exception, ends)
        endif
        let error_number = err + 1
        call setline(error_number, message)
    endfor
	silent! execute 'resize ' . line('$')
    autocmd! BufEnter LastSession.pytest call s:CloseIfLastWindow()
    nnoremap <silent> <buffer> q       :call <sid>ClearAll(1)<CR>
    nnoremap <silent> <buffer> <Enter> :call <sid>ClearAll(1)<CR>
    nnoremap <script> <buffer> <C-n>   :call <sid>GoToInlineError(1)<CR>
    nnoremap <script> <buffer> <down>  :call <sid>GoToInlineError(1)<CR>
    nnoremap <script> <buffer> j       :call <sid>GoToInlineError(1)<CR>
    nnoremap <script> <buffer> <C-p>   :call <sid>GoToInlineError(-1)<CR>
    nnoremap <script> <buffer> <up>    :call <sid>GoToInlineError(-1)<CR>
    nnoremap <script> <buffer> k       :call <sid>GoToInlineError(-1)<CR>
    call s:PytestFailsSyntax()
    exe "normal! 0|h"
    if (! gain_focus)
        exe 'wincmd p'
    else
        call s:Echo("Hit Return or q to exit", 1)
    endif
endfunction


function! s:LastSession()
    call s:ClearAll()
    if (len(g:pytest_last_session) == 0)
        call s:Echo("There is currently no saved last session to display")
        return
    endif
	let winnr = bufwinnr('LastSession.pytest')
	silent! execute  winnr < 0 ? 'botright new ' . 'LastSession.pytest' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number filetype=pytest
    let session = split(g:pytest_last_session, '\n')
    call append(0, session)
	silent! execute 'resize ' . line('$')
    silent! execute 'normal! gg'
    autocmd! BufEnter LastSession.pytest call s:CloseIfLastWindow()
    nnoremap <silent> <buffer> q       :call <sid>ClearAll(1)<CR>
    nnoremap <silent> <buffer> <Enter> :call <sid>ClearAll(1)<CR>
    call s:PytestSyntax()
    exe 'wincmd p'
endfunction


function! s:ToggleFailWindow()
	let winnr = bufwinnr('Fails.pytest')
    if (winnr == -1)
        call s:ShowFails()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
        silent! execute 'wincmd p'
    endif
endfunction


function! s:ToggleLastSession()
	let winnr = bufwinnr('LastSession.pytest')
    if (winnr == -1)
        call s:LastSession()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
        silent! execute 'wincmd p'
    endif
endfunction


function! s:ToggleShowError()
	let winnr = bufwinnr('ShowError.pytest')
    if (winnr == -1)
        call s:ShowError()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
        silent! execute 'wincmd p'
    endif
endfunction


function! s:ClearAll(...)
    let current = winnr()
    let bufferL = [ 'Fails.pytest', 'LastSession.pytest', 'ShowError.pytest', 'PytestVerbose.pytest' ]
    for b in bufferL
        let _window = bufwinnr(b)
        if (_window != -1)
            silent! execute _window . 'wincmd w'
            silent! execute 'q'
        endif
    endfor
    execute current . 'wincmd w'
    " Remove any echoed messages
    if (a:0 == 1)
        " Try going back to our starting window
        " and remove any left messages
        call s:Echo('')
        silent! execute 'wincmd p'
    endif
endfunction


function! s:ResetAll()
    " Resets all global vars
    let g:pytest_session_errors    = {}
    let g:pytest_session_error     = 0
    let g:pytest_last_session      = ""
    let g:pytest_looponfail        = 0
endfunction!


function! s:RunPyTest(path)
    let g:pytest_last_session = ""
    let cmd = "py.test --tb=short " . a:path
    let out = system(cmd)

    " Pointers and default variables
    let g:pytest_session_errors = {}
    let g:pytest_session_error  = 0
    let g:pytest_last_session   = out

    for w in split(out, '\n')
        if w =~ '\v\s+(FAILURES)\s+'
            call s:ParseFailures(out)
            return
        elseif w =~ '\v\s+(ERRORS)\s+'
            call s:ParseErrors(out)
            return
        elseif w =~ '\v^(.*)\s*ERROR:\s+'
            call s:RedBar()
            echo "py.test had an Error, see :Pytest session for more information"
            return
        elseif w =~ '\v^(.*)\s*INTERNALERROR'
            call s:RedBar()
            echo "py.test had an InternalError, see :Pytest session for more information"
            return
        endif
    endfor
    call s:GreenBar()

    " If looponfail is set we no longer need it
    " So clear the autocomand and set the global var to 0
    let g:pytest_looponfail = 0
    call s:LoopOnFail(0)
endfunction


function! s:ParseFailures(stdout)
    " Pointers and default variables
    let failed = 0
    let errors = {}
    let error = {}
    let error_number = 0
    let pytest_error = ""
    let current_file = expand("%:t")
    let file_regex =  '\v(^' . current_file . '|/' . current_file . ')'
    let error['line'] = ""
    let error['path'] = ""
    let error['exception'] = ""
    " Loop through the output and build the error dict
    for w in split(a:stdout, '\n')
        if ((error.line != "") && (error.path != "") && (error.exception != ""))
            try
                let end_file_path = error['file_path']
            catch /^Vim\%((\a\+)\)\=:E/
                let error.file_path = error.path
                let error.file_line = error.line
            endtry
            let error_number = error_number + 1
            let errors[error_number] = error
            let error = {}
            let error['line'] = ""
            let error['path'] = ""
            let error['exception'] = ""
        endif

        if w =~ '\v\s+(FAILURES)\s+'
            let failed = 1
        elseif w =~ '\v^(.*)\.py:(\d+):'
            if w =~ file_regex
                let match_result = matchlist(w, '\v:(\d+):')
                let error.line = match_result[1]
                let file_path = matchlist(w, '\v(.*.py):')
                let error.path = file_path[1]
            elseif w !~ file_regex
                let match_result = matchlist(w, '\v:(\d+):')
                let error.file_line = match_result[1]
                let file_path = matchlist(w, '\v(.*.py):')
                let error.file_path = file_path[1]
            endif
        elseif w =~  '\v^E\s+(.*)\s+'
            let split_error = split(w, "E ")
            let actual_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g")
            let match_error = matchlist(actual_error, '\v(\w+):\s+(.*)')
            if (len(match_error))
                let error.exception = match_error[1]
                let error.error = match_error[2]
            else
                let error.exception = "UnmatchedException"
                let error.error = actual_error
            endif
        elseif w =~ '\v^(.*)\s*ERROR:\s+'
            let pytest_error = w
        endif
    endfor

    " Display the result Bars
    if (failed == 1)
        let g:pytest_session_errors = errors
        call s:ShowFails(1)
    elseif (failed == 0 && pytest_error == "")
        call s:GreenBar()
    elseif (pytest_error != "")
        call s:RedBar()
        echo "py.test " . pytest_error
    endif
endfunction


function! s:ParseErrors(stdout)
    " Pointers and default variables
    let failed = 0
    let errors = {}
    let error = {}
    " Loop through the output and build the error dict

    for w in split(a:stdout, '\n')
        if w =~ '\v\s+(ERRORS)\s+'
            let failed = 1
        elseif w =~ '\v^E\s+(File)'
            let match_line_no = matchlist(w, '\v\s+(line)\s+(\d+)')
            let error['line'] = match_line_no[2]
            let error['file_line'] = match_line_no[2]
            let split_file = split(w, "E ")
            let match_file = matchlist(split_file[0], '\v"(.*.py)"')
            let error['file_path'] = match_file[1]
            let error['path'] = match_file[1]
        elseif w =~ '\v^(.*)\.py:(\d+)'
            let match_result = matchlist(w, '\v:(\d+)')
            let error.line = match_result[1]
            let file_path = matchlist(w, '\v(.*.py):')
            let error.path = file_path[1]
        endif
        if w =~ '\v^E\s+(\w+):\s+'
            let split_error = split(w, "E ")
            let match_error = matchlist(split_error[0], '\v(\w+):')
            let error['exception'] = match_error[1]
            let flat_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g")
            let error.error = flat_error
        endif
    endfor
    try
        let end_file_path = error['file_path']
    catch /^Vim\%((\a\+)\)\=:E/
        let error.file_path = error.path
        let error.file_line = error.line
    endtry

    " FIXME
    " Now try to really make sure we have some stuff to pass
    " who knows if we are getting more of these :/ quick fix for now
    let error['exception'] = get(error, 'exception', 'UnmatchedException')
    let error['error']     = get(error, 'error', 'py.test had an error, please see :Pytest session for more information')
    let errors[1] = error

    " Display the result Bars
    if (failed == 1)
        let g:pytest_session_errors = errors
        call s:ShowFails(1)
    elseif (failed == 0)
        call s:GreenBar()
    endif
endfunction


function! s:RedBar()
    redraw
    hi RedBar ctermfg=white ctermbg=red guibg=red
    echohl RedBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:GreenBar()
    redraw
    hi GreenBar ctermfg=white ctermbg=40 guibg=green
    echohl GreenBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:ThisMethod(verbose, ...)
    let save_cursor = getpos('.')
    call s:ClearAll()
    let m_name  = s:NameOfCurrentMethod()
    let c_name  = s:NameOfCurrentClass()
    let abspath = s:CurrentPath()
    if (strlen(m_name) == 1)
        call setpos('.', save_cursor)
        call s:Echo("Unable to find a matching method for testing")
        return
    elseif (strlen(c_name) == 1)
        call setpos('.', save_cursor)
        call s:Echo("Unable to find a matching class for testing")
        return
    endif

    let path =  abspath . "::" . c_name . "::" . m_name
    let message = "py.test ==> Running test for method " . m_name
    call s:Echo(message, 1)

    if ((a:1 == '--pdb') || (a:1 == '-s'))
        call s:Pdb(path, a:1)
        return
    endif
    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
       call s:RunPyTest(path)
    endif
endfunction


function! s:ThisFunction(verbose, ...)
    let save_cursor = getpos('.')
    call s:ClearAll()
    let c_name      = s:NameOfCurrentFunction()
    let abspath     = s:CurrentPath()
    if (strlen(c_name) == 1)
        call setpos('.', save_cursor)
        call s:Echo("Unable to find a matching function for testing")
        return
    endif
    let message  = "py.test ==> Running tests for function " . c_name
    call s:Echo(message, 1)

    let path = abspath . "::" . c_name

    if ((a:1 == '--pdb') || (a:1 == '-s'))
        call s:Pdb(path, a:1)
        return
    endif

    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisClass(verbose, ...)
    let save_cursor = getpos('.')
    call s:ClearAll()
    let c_name      = s:NameOfCurrentClass()
    let abspath     = s:CurrentPath()
    if (strlen(c_name) == 1)
        call setpos('.', save_cursor)
        call s:Echo("Unable to find a matching class for testing")
        return
    endif
    let message  = "py.test ==> Running tests for class " . c_name
    call s:Echo(message, 1)

    let path = abspath . "::" . c_name

    if ((a:1 == '--pdb') || (a:1 == '-s'))
        call s:Pdb(path, a:1)
        return
    endif

    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisFile(verbose, ...)
    call s:ClearAll()
    call s:Echo("py.test ==> Running tests for entire file ", 1)
    let abspath     = s:CurrentPath()

    if ((a:1 == '--pdb') || (a:1 == '-s'))
        call s:Pdb(abspath, a:1)
        return
    endif

    if (a:verbose == 1)
        call s:RunInSplitWindow(abspath)
    else
        call s:RunPyTest(abspath)
    endif
endfunction


function! s:Pdb(path, ...)
    let pdb_command = "py.test " . a:1 . " " . a:path
    if exists("g:ConqueTerm_Loaded")
        call conque_term#open(pdb_command, ['split', 'resize 20'], 0)
    else
        exe ":!" . pdb_command
    endif
endfunction


function! s:Version()
    call s:Echo("pytest.vim version 1.1.2dev", 1)
endfunction


function! s:Completion(ArgLead, CmdLine, CursorPos)
    let result_order = "first\nlast\nnext\nprevious\n"
    let test_objects = "class\nmethod\nfile\n"
    let optional     = "verbose\nlooponfail\nclear\n"
    let reports      = "fails\nerror\nsession\nend\n"
    let pyversion    = "version\n"
    let pdb          = "--pdb\n-s\n"
    return test_objects . result_order . reports . optional . pyversion . pdb
endfunction


function! s:Proxy(action, ...)
    " Some defaults
    let verbose = 0
    let pdb     = 'False'
    let looponfail = 0

    if (a:0 > 0)
        if (a:1 == 'verbose')
            let verbose = 1
        elseif (a:1 == '--pdb')
            let pdb = '--pdb'
        elseif (a:1 == '-s')
            let pdb = '-s'
        elseif (a:1 == 'looponfail')
            let g:pytest_looponfail = 1
            let looponfail = 1
        endif
    endif
    if (a:action == "class")
        if looponfail == 1
            call s:LoopOnFail(a:action)
            call s:ThisClass(verbose, pdb)
        else
            call s:ThisClass(verbose, pdb)
        endif
    elseif (a:action == "method")
        if looponfail == 1
            call s:LoopOnFail(a:action)
            call s:ThisMethod(verbose, pdb)
        else
            call s:ThisMethod(verbose, pdb)
        endif
    elseif (a:action == "function")
        if looponfail == 1
            call s:LoopOnFail(a:action)
            call s:ThisFunction(verbose, pdb)
        else
            call s:ThisFunction(verbose, pdb)
        endif
    elseif (a:action == "file")
        if looponfail == 1
            call s:LoopOnFail(a:action)
            call s:ThisFile(verbose, pdb)
        else
            call s:ThisFile(verbose, pdb)
        endif
    elseif (a:action == "fails")
        call s:ToggleFailWindow()
    elseif (a:action == "next")
        call s:GoToError(1)
    elseif (a:action == "previous")
        call s:GoToError(-1)
    elseif (a:action == "first")
        call s:GoToError(0)
    elseif (a:action == "last")
        call s:GoToError(2)
    elseif (a:action == "end")
        call s:GoToError(3)
    elseif (a:action == "session")
        call s:ToggleLastSession()
    elseif (a:action == "error")
        call s:ToggleShowError()
    elseif (a:action == "clear")
        call s:ClearAll()
        call s:ResetAll()
    elseif (a:action == "version")
        call s:Version()
    else
        call s:Echo("Not a valid Pytest option ==> " . a:action)
    endif
endfunction


command! -nargs=+ -complete=custom,s:Completion Pytest call s:Proxy(<f-args>)

