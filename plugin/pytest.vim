" File:        pytest.vim
" Description: Runs the current test Class/Method/Function with
"              py.test 
" Maintainer:  Alfredo Deza <alfredodeza AT gmail.com>
" License:     MIT
"============================================================================

if exists("g:loaded_pytest") || &cp 
  finish
endif


" Global variables for registering next/previous error
let g:session_errors = {}
let g:session_error = 0


function! s:GoToError(direction)
    " direction == 0 goes to first
    " direction ==  1 goes forward
    " direction == -1 goes backwards
    " directtion == 2 goes to last
    if (len(g:session_errors) > 0)
        if (a:direction == -1)
            if (g:session_error == 0 || g:session_error == 1)
                let g:session_error = 1
            else
                let g:session_error = g:session_error - 1
            endif
        elseif (a:direction == 1)
            if (g:session_error != len(g:session_errors))
                let g:session_error = g:session_error + 1
            endif
        elseif (a:direction == 0)
            let g:session_error = 1
        elseif (a:direction == 2)
            let g:session_error = len(g:session_errors)
        endif

        let select_error = g:session_errors[g:session_error]
        let line_number = select_error['line']
        let error_path = select_error['path']
        let file_name = expand("%:t")
        if error_path =~ file_name
            execute line_number
        else
            call OpenError(error_path)
            execute line_number
        endif
        let message = "Failed test: " . g:session_error . "\t at line ==>> " . line_number
        call s:Echo(message, 1)
    else
        call s:Echo("Failed test list is empty.")
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
    let orig_line = line('.')
    let orig_col = col('.')

    if (a:obj == "class")
        let objregexp  = '\v^\s*(.*class)\s+(\w+)\s*'
    elseif (a:obj == "method")
        let objregexp = '\v^\s*(.*def)\s+(\w+)\s*\(\s*(self[^)]*)'
    else
        let objregexp = '\v^\s*(.*def)\s+(\w+)\s*\(\s*(.*self)@!'
    endif

    let flag = "Wb"
    let result = search(objregexp, flag)

    if result 
        return result
    endif

endfunction


function! s:NameOfCurrentClass()
    let save_cursor = getpos(".")
    normal $<cr>
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
    normal $<cr>
    let find_object = s:FindPythonObject('method')
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
	let command = join(map(split(cmd), 'expand(v:val)'))
	let winnr = bufwinnr('^' . command . '$')
	silent! execute  winnr < 0 ? 'botright new ' . fnameescape(command) : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
	silent! execute 'silent %!'. command
	silent! execute 'resize ' . line('$')
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
endfunction


function! OpenError(path)
	let winnr = bufwinnr('Pytest_GoToError')
	silent! execute  winnr < 0 ? 'botright new ' . ' Pytest_GoToError' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
    silent! execute ":e " . a:path
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
endfunction

function! s:ShowFails()
	let winnr = bufwinnr('Pytest_Fails')
	silent! execute  winnr < 0 ? 'botright new ' . 'Pytest_Fails' : winnr . 'wincmd w'
	setlocal buftype=nowrite bufhidden=wipe nobuflisted noswapfile nowrap number
    let blank_line = repeat(" ",&columns - 1)
    exe "normal i" . blank_line 
    hi RedBar ctermfg=white ctermbg=red guibg=red
    match RedBar /\%1l/
    if (len(g:session_errors) == 0)
        call setline(2, "There are currently no errors for a previous run.")
    else
        for err in keys(g:session_errors)
            let err_dict = g:session_errors[err]
            let line_number = err_dict['line']
            let actual_error = err_dict['error']
            let path_error = err_dict['path']
            let message = "Line: " . line_number . "\t==>> " . actual_error . "\t\tPath: " . path_error
            let error_number = err + 1
            call setline(error_number, message)    
        endfor
    endif
	silent! execute 'resize ' . line('$')
    silent! execute 'nnoremap <silent> <buffer> q :q! <CR>'
    exe "normal 0|"
    exe "normal G"
    exe 'wincmd w'
endfunction


function! s:ToggleFailWindow()
	let winnr = bufwinnr('Pytest_Fails')
    if (winnr == -1)
        call s:ShowFails()
    else
        silent! execute winnr . 'wincmd w'
        silent! execute 'q'
    endif
endfunction


function! s:RunPyTest(path)
    let cmd = "py.test --tb=short " . a:path
    let out = system(cmd)
    
    " Pointers and default variables
    let failed = 0
    let errors = {}
    let error = {}
    let error_number = 0
    let pytest_error = ""
    let g:session_errors = {}
    let g:session_error = 0

    " Loop through the output and build the error dict
    for w in split(out, '\n')
        if (len(error) == 3)
            let error_number = error_number + 1
            let errors[error_number] = error
            let error = {}
        endif

        if w =~ 'FAILURES'
            let failed = 1
        elseif w =~ '\v^\s*(.*)py:(\d+):'
            let match_result = matchlist(w, '\v:(\d+):')
            let error.line = match_result[1]
            let file_path = matchlist(w, '\v(.*.py):')
            let error.path = file_path[1]
        elseif w =~  '\v^E\s+'
            let split_error = split(w, "E ")
            let actual_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g") 
            let error.error = actual_error

        elseif w =~ '\v^ERROR:\s+'
            let pytest_error = w
        endif
    endfor
    
    " Display the result Bars
    if (failed == 1)
        call s:RedBar()
        for err in keys(errors)
            let err_dict = errors[err]
            let line_number = err_dict['line']
            let actual_error = err_dict['error']
            let path_error = err_dict['path']
            echo "Line: " . line_number . "\t==>> " . actual_error . "\t\tPath: " . path_error
            let g:session_errors = errors
        endfor
    elseif (failed == 0 && pytest_error == "")
        call s:GreenBar()
    elseif (pytest_error != "")
        call s:RedBar()
        echo "py.test " . pytest_error
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
    hi GreenBar ctermfg=white ctermbg=green guibg=green
    echohl GreenBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:ThisMethod(verbose)
    let m_name  = s:NameOfCurrentMethod()
    let c_name  = s:NameOfCurrentClass()
    let abspath = s:CurrentPath()
    if (strlen(m_name) == 1)
        call s:Echo("Unable to find a matching method for testing.")
        return
    elseif (strlen(c_name) == 1)
        call s:Echo("Unable to find a matching class for testing.")
        return
    endif

    let path =  abspath . "::" . c_name . "::" . m_name 
    let message = "py.test ==> Running test for method " . m_name 
    call s:Echo(message, 1)

    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisClass(verbose)
    let c_name      = s:NameOfCurrentClass()
    let abspath     = s:CurrentPath()
    if (strlen(c_name) == 1)
        call s:Echo("Unable to find a matching class for testing.")
        return
    endif
    let message  = "py.test ==> Running tests for class " . c_name 
    call s:Echo(message, 1)

    let path = abspath . "::" . c_name
    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisFile(verbose)
    call s:Echo("py.test ==> Running tests for entire file ", 1)
    let abspath     = s:CurrentPath()
    if (a:verbose == 1)
        call s:RunInSplitWindow(abspath)
    else
        call s:RunPyTest(abspath)
    endif
endfunction
    

function! s:Completion(ArgLead, CmdLine, CursorPos)
    return "class\nmethod\nfile\nverbose\nnext\nprevious\nfirst\nlast\n" 
endfunction


function! s:Proxy(action, ...)
    if (a:0 == 1)
        let verbose = 1
    else
        let verbose = 0
    endif
    if (a:action == "class")
        call s:ThisClass(verbose)
    elseif (a:action == "method")
        call s:ThisMethod(verbose)
    elseif (a:action == "file")
        call s:ThisFile(verbose)
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
    endif
endfunction


command! -nargs=+ -complete=custom,s:Completion Pytest call s:Proxy(<f-args>)

