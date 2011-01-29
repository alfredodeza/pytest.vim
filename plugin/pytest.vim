" File:        pytest.vim
" Description: Runs the current test Class/Method/Function with
"              py.test 
" Maintainer:  Alfredo Deza <alfredodeza AT gmail.com>
" License:     MIT
"============================================================================

if exists("g:loaded_pytest") || &cp 
  finish
endif

function! Echo(msg)
  if (! exists('g:chapa_messages') || exists('g:chapa_messages') && g:chapa_messages)
    let x=&ruler | let y=&showcmd
    set noruler noshowcmd
    redraw
    echo a:msg
    let &ruler=x | let &showcmd=y
  endif
endfun


" Always goes back to the first instance
" and returns that if found
function! s:FindPythonObject(obj)
    let orig_line = line('.')
    let orig_col = col('.')

    if (a:obj == "class")
        let objregexp  = '\v^\s*(.*class)\s+(\w+)\s*\(\s*'
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

command! -complete=shellcmd -nargs=+ Shell call s:ExecuteInShell(<q-args>)


function! s:RunPyTest(path)
    let cmd = "py.test " . a:path
    let out = system(cmd)
    
    let failed = 0
    let error_list = []
    let single_error = []
    for w in split(out, '\n')
        if (len(single_error) == 2)
            call add(error_list, single_error)
            let single_error = []
        endif    
        if w =~ 'FAILURES'
            let failed = 1
        elseif w =~ '\v^\s*(.*)py:(\d+):'
            if w =~ @%
                let match_result = matchlist(w, '\v:(\d+):')
                call insert(single_error, match_result[1])
            endif
        elseif w =~  '\v^E\s+'
            call add(single_error, w)
        endif
    endfor
    
    if (failed == 1)
        call s:RedBar()
        for error in error_list
            let file = error[0]
            let split_error = split(error[1], "E ")
            let actual_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g") 
            echo "Line:  " . file . "\t==>> " .actual_error
        endfor
    else
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
    hi GreenBar ctermfg=white ctermbg=green guibg=green
    echohl GreenBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! s:ThisMethod(verbose)
    let m_name  = s:NameOfCurrentMethod()
    let c_name  = s:NameOfCurrentClass()
    let abspath = s:CurrentPath()
    echo "Running test for method " . m_name 
    let path =  abspath . "::" . c_name . "::" . m_name 
    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisClass(verbose)
    let c_name      = s:NameOfCurrentClass()
    let abspath     = s:CurrentPath()
    echo "Running tests for class " . c_name 

    let path = abspath . "::" . c_name
    if (a:verbose == 1)
        call s:RunInSplitWindow(path)
    else
        call s:RunPyTest(path)
    endif
endfunction


function! s:ThisFile(verbose)
    echo "Running tests for entire file "
    let abspath     = s:CurrentPath()
    if (a:verbose == 1)
        call s:RunInSplitWindow(abspath)
    else
        call s:RunPyTest(abspath)
    endif
endfunction
    

function! s:Completion(ArgLead, CmdLine, CursorPos)
    return "class\nmethod\nfile\nverbose\n" 
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
    else
        call s:ThisFile(verbose)
    endif
endfunction

command! -nargs=+ -complete=custom,s:Completion Pytest call s:Proxy(<f-args>)

