let s:yaTranslator = {
\	'url': '', 
\	'key': '' ,
\}

function s:yaTranslator.add(key_sequence, from_language, to_language) 
	let translation_context = <SID>BuildTranslationContext(self, a:from_language, a:to_language, v:null)
	let translation_function_name =  "Translate" . toupper(a:from_language) . "2" . toupper (a:to_language) 
	let translation_function  = "function! s:" . translation_function_name . "(type)\n"
	let translation_function .= "  call <SID>Translate(a:type, " . string(translation_context) . ")\n"
	let translation_function .= "endfunction"
	exe translation_function

	if maparg(a:key_sequence, 'n') !=# ""
		exe ':nunmap ' . a:key_sequence 
	endif
	exe 'nnoremap ' . a:key_sequence . ' :set opfunc=<SID>' . translation_function_name . '<cr>g@'
	if maparg(a:key_sequence, 'v') !=# ""
		exe ':vunmap ' . a:key_sequence
	endif
	exe 'vnoremap ' . a:key_sequence . ' :<c-u>call <SID>' . translation_function_name . '(visualmode())<cr>'
endfunction

function s:yaTranslator.translate(from_language, to_language, text)
	let translation_context = <SID>BuildTranslationContext(self, a:from_language, a:to_language, a:text)
	call <SID>Translate('c', translation_context)
endfunction

function! yaTranslator#New()
	return deepcopy(s:yaTranslator)
endfunction

function! s:BuildTranslationContext(yaTranslator, from_language, to_language, text)
	let translation_context = {}
	let translation_context.url = a:yaTranslator.url
	let translation_context.key = a:yaTranslator.key
	let translation_context.from_language = a:from_language
	let translation_context.to_language = a:to_language
	let translation_context.text = a:text

	return translation_context
endfunction

function! s:StripString(string)
	return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:UrlEncode(string)
ruby << EOF
	require 'URI'
	encoded_string = URI.encode(VIM::evaluate("a:string"))
	VIM::command('let encoded_string = "' + encoded_string + '"')
EOF
	return encoded_string
endfunction

function! s:Translate(type, translation_context)
	let saved_unnamed_register = @@

	if a:type ==? 'v'
		norm! `<v`>y
	elseif a:type ==# 'char'
		norm! `[v`]y
	else
		return
	endif

	let text = <SID>StripString(@@)
	let text = split(text, '\n')
	let @@ = saved_unnamed_register

	call <SID>HandleTranslationResult(<SID>DoTranslation(text, a:translation_context))
endfunction

function! s:DoTranslation(text, translation_context)
	let p_key = "key=" . a:translation_context.key
	let p_lang = "lang=" . a:translation_context.from_language . "-" . a:translation_context.to_language
	let p_format = "format=plain"
	let url = a:translation_context.url . "?" . p_key . "&" . p_lang . "&" . p_format
	let p_text = a:text

	call map(p_text, '" -d " . "text=\"" . <SID>UrlEncode(v:val) . "\"" ')

	let curl = "curl -s -k " 
	let curl = curl . join(p_text) . " " . shellescape(url)

	echo curl

	return js_decode(system(curl))
endfunction

function! s:HandleTranslationResult(translation_result)
	echo a:translation_result

	let text = a:translation_result['text']

	call add(text, "")
	call add(text, "----------------------------------------------------------")
	call add(text, "Powered by Yandex.Translate (http://translate.yandex.ru/).")

	let last_window_id = win_getid()

	pclose
	new
	setlocal modifiable
	setlocal noreadonly
	setlocal previewwindow
	call append(0, text)
	delete
	call cursor(1, 1)
	set bt=nofile
	setlocal readonly
	setlocal nomodifiable
	setlocal nobuflisted

	if &lines > len(text)
		exe "resize " . len(text)
	endif

	call win_gotoid(last_window_id)

endfunction

let yaTranslator = yaTranslator#New()
let yaTranslator.url = "https://translate.yandex.net/api/v1.5/tr.json/translate"
let yaTranslator.key = "trnsl.1.1.20170124T124018Z.1181d766be5f1460.fcda7fd114d2a31600131da21eda3535c21e2f00"
call yaTranslator.add('<leader>t', 'en', 'ru')
call yaTranslator.add('<leader>T', 'ru', 'en')

