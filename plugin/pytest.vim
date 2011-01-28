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
function! FindPythonObject(obj)
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


function! NameOfCurrentClass()
    let save_cursor = getpos(".")
    normal $<cr>
    let find_object = FindPythonObject('class')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *class \+\(\w\+\)')
        return match_result[1]
    endif
endfunction


function! NameOfCurrentMethod()
    let save_cursor = getpos(".")
    normal $<cr>
    let find_object = FindPythonObject('method')
    if (find_object)
        let line = getline('.')
        call setpos('.', save_cursor)
        let match_result = matchlist(line, ' *def \+\(\w\+\)')
        return match_result[1]
    endif
endfunction


function! CurrentPath()
    let cwd = expand("%:p")
    return cwd
endfunction


function! RunPyTest(path)
    let cmd = "py.test --tb=short " . a:path
    let out = system(cmd)
    
    let failed = 0
    let error_list = []
    let single_error = []
    for w in split(out, '\n')
        if w =~ 'FAILURES'
            let failed = 1
        elseif w =~ '\v^\s*\w+.py:'
            call add(single_error, w)
        elseif w =~  '\v^\s*E\s+'
            call add(single_error, w)
        endif
        if (len(single_error) == 2)
            call add(error_list, single_error)
            let single_error = []
        endif    
    endfor
    if (failed == 1)
        call RedBar()
        call RedBar()
        for error in error_list
            let file = error[0]
            let split_error = split(error[1], "E ")
            let actual_error = substitute(split_error[0],"^\\s\\+\\|\\s\\+$","","g") 
            echo file . " ==>> " .actual_error
        endfor
    else
        call GreenBar()
    endif
    "echo out
endfunction


function! RedBar()
    redraw
    hi RedBar ctermfg=white ctermbg=red guibg=red
    echohl RedBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! GreenBar()
    redraw
    hi GreenBar ctermfg=white ctermbg=green guibg=green
    echohl GreenBar
    echon repeat(" ",&columns - 1)
    echohl
endfunction


function! PyTestThisMethod()
    let m_name  = NameOfCurrentMethod()
    let c_name  = NameOfCurrentClass()
    let abspath = CurrentPath()
    echo "Running test for method " . m_name . "\n"
    let path =  abspath . "::" . c_name . "::" . m_name 
    call RunPyTest(path)
endfunction


function! PyTestThisClass()
    let c_name      = NameOfCurrentClass()
    let abspath     = CurrentPath()
    echo "Running tests for class " . c_name . "\n"

    let path = abspath . "::" . c_name
    call RunPyTest(path)
endfunction

function! PyTestThisFile()
    echo "Running tests for entire file \n"
    let abspath     = CurrentPath()
    call RunPyTest(abspath)
endfunction
    
"nnoremap <Plug>PyTestThisMethod   :<C-U>call ThisMethod() <CR>
"nnoremap <Plug>PyTestThisClass    :<C-U>call ThisClass()  <CR>
"nnoremap <Plug>PyTestThisFile     :<C-U>call ThisFile()   <CR>
