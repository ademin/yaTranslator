
                    _______                  _       _               
                   |__   __|                | |     | |              
           _   _  __ _| |_ __ __ _ _ __  ___| | __ _| |_ ___  _ __   
          | | | |/ _` | | '__/ _` | '_ \/ __| |/ _` | __/ _ \| '__| 
          | |_| | (_| | | | | (_| | | | \__ \ | (_| | || (_) | |     
           \__, |\__,_|_|_|  \__,_|_| |_|___/_|\__,_|\__\___/|_|     
            __/ |                                                    
           |___/                                                     
		   
		          Translation inside VIM
		   
		   Functionality for translating text with 
			 the Yandex.Translate service
		      https://tech.yandex.com/translate/

# Introduction

The VIM is a great tool for editing text. Even more, it can become more
valuable and attractive tool with the ability of translation text on the fly.
Just imagine that it whould allow you to select text, use several key presses
and get the text translated to another language shown in a separate window.
This is what the yaTranslator plugin created for. It helps translate text
inside VIM with the power of the Yandex.Translate service.

# 2. System Requirements                       

The yaTranslater plugin requires:
	* VIM with built-in ruby support (see |+ruby|)
	* CURL utility installed in the host system

## 2.1 Ruby                                         

To find out wether your VIM has it build-in or not use the following command: >

	:version 

Or just type the next command into the VIM's command-line: 

	:ruby print "yaTranslator"

The result must be: 

	yaTranslator

You might need to configure rubydll to point to library path.
For example, on Mac OS in might look like this: 

  set rubydll=/usr/local/lib/libruby.dylib

To learn more about rubydll option please visit VIM's documentation: 

  :help rubydll


## 2.1 Curl                                          

To find out wether your system has Curl utility or not use the next 
VIM command: >

	:!curl --version

## 3. Configuration                              

The yaTranslator plugin's configuration interface is implemented with the 
object-oriented concept in mide. First, the instance of the yaTranslator
object must be created:

	let yaTranslator = yaTranslator#New()

Then, the value of the Yandex.Translate service API key must be specified
(please refer to "https://tech.yandex.com/translate/" to know how to obtain
a free API key)

	let yaTranslator.key = "API key here"

The url of the Yandex.Translate service is set to
"https://translate.yandex.net/api/v1.5/tr.json/translate". But it is allowed
to configure url to something different through the "url" field of the
yaTranslator object. For ex:

	let yaTranslator.url = "the URL other then the default one"

Now the yaTranslator object is configured and ready to be used.

## 4. Usage                                            

So far, the yaTranslator object has been created and configured (see
|yaTranslatorConfiguration|). Now it is time to add translation support.
Let's configure the translation from English language to Russian one.  The
yaTranslator object has method add with three parameters: 

	* key sequence to be used to initiate translation; 
	* language code to translate the text from
	* language code to translate the text to

(To find out the full list of supported languages and their codes refer to
"https://tech.yandex.com/translate/doc/dg/concepts/api-overview-docpage/")

	call yaTranslator.add('<leader>t', 'en', 'ru')

Now the translation support is added and ready to be used.  For example, to
translate a word of English text type the next key sequence (it is assumed
that the leader key is '\') when in normal mode:

	\taw

The preview window with the text translated to Russian language must be shown.

The same way the text selected in visual mode can be translated. Just select
some English text with visual selection and then type '\t'. And again the
preview window with the text translated to Russian language is shown.

The yaTranslator object has another useful method called "translate".  The
primary purpose of this method is to be used inside user's VimScript.  It has
three parameters:

	* language code to translate the text from
	* language code to translate the text to
	* the text to be translated

The result of the method is a VimScript dictionary object. For example, to
translate the text "Hello World!" and echo the result the next code might be
used:

	echo string(yaTranslator.translate("en", "ru", "Hello World!")) 

In case of success the response should look like somethig shown below:

	{'lang': 'en-ru', 'code': 200, 'text': ['Всем Привет!']} 

To find out the structure of the response refer to JSON response described in
"https://tech.yandex.com/translate/doc/dg/reference/translate-docpage/".

## 5. Example                                          

Add the following code to your VIMRC file for support of translation from
English language to Russian language and wise versa.

	" Create and configure yaTranslator instance
	let yaTranslator = yaTranslator#New()
	let yaTranslator.key = "API key here"

	" Add translation support for translation 
	call yaTranslator.add('<leader>t', 'en', 'ru')
	call yaTranslator.add('<leader>T', 'ru', 'en')

Reload VIMRC file (or restart VIM). Now, the "<leader>t" can be used for
translation of visually selected text (visual mode selection) or text selected
with operators (such as: w, b, aw, ap, etc.) from English to Russian and use
"<leader>T" to do translation from Russian to English.
