" Vim global plugin for translating text with the Yandex.Translate service 
" Last Change:	2017 Jan 25
" Maintainer:	Alexey Demin <demin.alexey@inbox.ru>
" License:	MIT

" Load guards {{{1
if exists("g:loaded_yaTranslator")
	finish
endif
let g:loaded_yaTranslator = "0.7" " the value is the plugin's version
let g:debug_yaTranslator = 0 " do or don't print debug messages

" Public Interface {{{1

" External translation context structure.
let s:yaTranslator = {
\	'url': '', 
\	'key': '' ,
\}

" Add a key sequence to translate from one language to another. 
function s:yaTranslator.add(key_sequence, from_language, to_language) 
	" Print Debug Message {{{
	call <SID>PrintDebugMessage(
\		"Add \"" . a:key_sequence . "\" key sequence for translating " .
\	      	" from \"" . a:from_language .  "\"" . 
\	      	" to \"" . a:to_language . "\"")
	" }}}

	let translation_context = <SID>BuildTranslationContext(self, a:from_language, a:to_language)

	" Generate an internal translation function.
	" The format is: Translate<FROM_LANGUAGE>2<TO_LANGUAGE>
	" For example: TranslateEN2RU
	let translation_function_name =  "Translate" . toupper(a:from_language) . "2" . toupper (a:to_language) 
	let translation_function  = "function! s:" . translation_function_name . "(type)\n"
	let translation_function .= "  call <SID>PrintNewTranslationDebugMessage()\n"
	let translation_function .= "  call <SID>Translate(a:type, " . string(translation_context) . ", 1)\n"
	let translation_function .= "endfunction"
	exe translation_function

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Generate translation function: " . "\n" . translation_function)
	" }}}

	" Create a mapping for normal mode.
	if maparg(a:key_sequence, 'n') !=# ""
		exe ':nunmap ' . a:key_sequence 
	endif
	let nmap = 'nnoremap <unique> ' . a:key_sequence . 
\		' :set opfunc=<SID>' . translation_function_name . '<cr>g@'

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Create operator-pending mode mapping: \n" . nmap)
	" }}}

	exe nmap
	
	" Create a mapping for visual mode.
	if maparg(a:key_sequence, 'v') !=# ""
		exe ':vunmap ' . a:key_sequence
	endif
	let vmap = 'vnoremap <unique> ' . a:key_sequence . 
\		' :<c-u>call <SID>' . translation_function_name . '(visualmode())<cr>'

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Create visual mode mapping: \n" . vmap)
	" }}}

	exe vmap
endfunction

" Translate text from one language to another.
function s:yaTranslator.translate(from_language, to_language, text)
	" Print Debug Message {{{
	call <SID>PrintNewTranslationDebugMessage()
	call <SID>PrintDebugMessage(
\		"Translate text: \n***\n" . a:text . "\n***\n" .
\		"from \"" . a:from_language .  "\" " . 
\		"to \"" . a:to_language . "\"")
	" }}}

	let translation_context = <SID>BuildTranslationContext(self, a:from_language, a:to_language)
	return <SID>TranslateText(a:text, translation_context)
endfunction

" Construct yaTranslator instance.
function! yaTranslator#New()
	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Create yaTranslator instance")
	" }}}
	return deepcopy(s:yaTranslator)
endfunction

" Implementation {{{1

" Print debug message
function! s:PrintDebugMessage(message)
	if g:debug_yaTranslator
		echo "--- DEBUG MESSAGE --------------------------------------------------------------"
		echo a:message
		echo "-------------------------------------------------------------------------------"
		echo "\n"
	endif
endfunction

" Print "NEW TRANSLATION" debug message
function! s:PrintNewTranslationDebugMessage()
	let message  = "\n"
	let message .= "\t****************************************************************\n"
	let message .= "\t*\t\t\t\t\t\t\t       *\n" 
	let message .= "\t*\t\t\tNEW TRANSLATION\t\t\t       *\n"
	let message .= "\t*\t\t\t\t\t\t\t       *\n" 
	let message .= "\t****************************************************************\n"
	let message .= "\n"

	call <SID>PrintDebugMessage(message)
endfunction

" Build translation context structure used internally.
function! s:BuildTranslationContext(yaTranslator, from_language, to_language)
	let translation_context = {}
	let translation_context.url = a:yaTranslator.url
	let translation_context.key = a:yaTranslator.key
	let translation_context.from_language = a:from_language
	let translation_context.to_language = a:to_language

	return translation_context
endfunction

" String string (remove leading and trailing whitespace characters).
function! s:StripString(string)
	return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

" Encode UTF-8 string into URL encoding format.
" Ruby support is required (see :help if_ruby.txt).
function! s:UrlEncode(string)
ruby << EOF
	require 'URI'
	encoded_string = URI.encode(VIM::evaluate("a:string"))
	VIM::command('let encoded_string = "' + encoded_string + '"')
EOF

	" Print Debug Message {{{
	call <SID>PrintDebugMessage(
\		"Convert the UTF-8 string: " . a:string . "\n" .
\		"To the URL encoded UTF-8 string: " . encoded_string)
	" }}}

	return encoded_string
endfunction

" Extract text from the current buffer based on active mode and do tranlstaion.
function! s:Translate(type, translation_context, handle_result)
	let saved_unnamed_register = @@ 

	" Extract text
	if a:type ==? 'v' " visual mode
		norm! `<v`>y
	elseif a:type ==# 'char' || a:type ==# 'line' " operator-pending mode
		norm! `[v`]y
	else
		return
	endif

	let text = @@

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Extracted text in mode \"" . a:type . "\":\n" . text)
	" }}}

	let @@ = saved_unnamed_register

	call <SID>HandleTranslationResult(<SID>TranslateText(text, a:translation_context))
endfunction

" Translate text with translation context.
function! s:TranslateText(text, translation_context)
	let text = split(a:text, '\n')

	" The Yandex.Translate service do stipping by itself but
	" in order to reduce request size leading and trailing
	" whitespaces are removed for each line of text.
	call map(text, '<SID>StripString(v:val)')

	" Print Debug Message {{{
	call <SID>PrintDebugMessage(
\		"Translate text: " . string(text) . "\n" .
\		"With translation context: " . string(a:translation_context))
	" }}}

	let translation_result = <SID>DoTranslation(text, a:translation_context)

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("Translation result: " . string(translation_result))
	" }}}

	return translation_result
endfunction

" Do translation 
function! s:DoTranslation(text, translation_context)
	" Build the Yandex.Translate service URL.
	let p_key = "key=" . a:translation_context.key
	let p_lang = "lang=" . a:translation_context.from_language . "-" . a:translation_context.to_language
	let p_format = "format=plain"
	let url = a:translation_context.url . "?" . p_key . "&" . p_lang . "&" . p_format

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("The Yandex.Translate service URL: " . url)
	" }}}

	" Build the text parameters to be used by CURL utility for the POST request.
	let p_text = a:text
	call map(p_text, '" -d " . "text=\"" . <SID>UrlEncode(v:val) . "\"" ')

	" Build the CURL command.
	let curl = "curl -s -k " 
	let curl = curl . join(p_text) . " " . shellescape(url)

	" Print Debug Message {{{
	call <SID>PrintDebugMessage("The CURL command line: " . curl)
	" }}}

	" Call CURL and decode the result.
	return js_decode(system(curl))
endfunction

" Handle the translation result.
function! s:HandleTranslationResult(translation_result)
	if a:translation_result['code'] == 200 " translation succeeded
		let text = a:translation_result['text'] " copy translated text
		call add(text, "")
	else " translation failed
		let text = []
		let code = a:translation_result['code'] 
		let message = a:translation_result['message'] " copy error message
		call add(text, "Translation Error [" . code . "]: " . message)
	endif
	" Terms of Use for the Yandex.Translate service requires to add a note
	" containing information about the service itself.
	call add(text, "----------------------------------------------------------")
	call add(text, "Powered by Yandex.Translate (http://translate.yandex.ru/).")

	" Save the window ID where the cursor currently is
	let last_window_id = win_getid()

	" Open the preview window with the translated text 
	" (or the text of error message, in case of the error).
	pclose " first close the preview windows if any
	new " create new window
	setlocal bt=nofile " mark as temporary buffer
	setlocal modifiable " allow to modify 
	setlocal noreadonly " disable readonly
	setlocal previewwindow " mark the window as the preview window
	call append(0, text) " append text from the beggining of the buffer
	delete " delete last empty line
	call cursor(1, 1) " move cursor to the first line and first column
	setlocal readonly " mark as readonly
	setlocal nomodifiable " disable modification 
	setlocal nobuflisted " move to unlised

	" Adjust the preview window height if possible
	if &lines > len(text)
		exe "resize " . len(text)
	endif

	" Move back to the window where the translation initiated from
	call win_gotoid(last_window_id)
endfunction

" vim: ts=8 fdm=marker

