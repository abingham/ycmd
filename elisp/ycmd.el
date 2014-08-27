(require 'hmac-def)
(require 'hmac-md5)
(require 'json)
(require 'request)

;; POST /completions HTTP/1.1
;; Accept: application/json
;; Accept-Encoding: gzip, deflate
;; Content-Length: 1022
;; Host: 127.0.0.1:62030
;; User-Agent: HTTPie/0.8.0
;; X-Ycm-Hmac: NmFmOGMwMmRkNmJhNmNhNzdlZTA2YzQxNzc0NjdkNDAxMmZkNGU1OTNmNTU5ZWIzNTNjMDJlMTZlYTcxNTI2Nw==
;; content-type: application/json

;; {
;;     "column_num": 7, 
;;     "file_data": {
;;         "/Users/sixtynorth/projects/ycmd/examples/samples/some_cpp.cpp": {
;;             "contents": "// Copyright (C) 2014  Google Inc.\n//\n// Licensed under the Apache License, Version 2.0 (the \"License\");\n// you may not use this file except in compliance with the License.\n// You may obtain a copy of the License at\n//\n//     http://www.apache.org/licenses/LICENSE-2.0\n//\n// Unless required by applicable law or agreed to in writing, software\n// distributed under the License is distributed on an \"AS IS\" BASIS,\n// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n// See the License for the specific language governing permissions and\n// limitations under the License.\n\nstruct Foo {\n  int x;\n  int y  // There's a missing semicolon here\n  char c;\n};\n\nint main()\n{\n  Foo foo;\n  // The location after the dot is line 28, col 7\n  foo.\n}\n\n\n", 
;;             "filetypes": [
;;                 "cpp"
;;             ]
;;         }
;;     }, 
;;     "filepath": "/Users/sixtynorth/projects/ycmd/examples/samples/some_cpp.cpp", 
;;     "line_num": 25
;; }

(setq data '(("column_num" . 16)
	     ("file_data" .
	      (("/Users/sixtynorth/sandbox/clang_rename/foo.cpp" .
		(("contents" . "#include \"foo.hpp\"

void Foo::foo() {
    int x = fno
    int y = x + 1;
}
")
		 ("filetypes" . ("cpp"))))))
	     ("filepath" . "/Users/sixtynorth/sandbox/clang_rename/foo.cpp")
	     ("line_num" . 4))
      )

                                        ; Create 16-bytes of secret
                                        ; encrypt msg. with sha256 and take hex of encryption
                                        ; b64encode the encrypted data

(let* ((secret "1234123412341234")
       (hmac (my-hmac "asdf" secret))
       (hex-hmac (encode-hex-string hmac))
       (encoded-hex-hmac (base64-encode-string hex-hmac)))
  ; THIS DOES IT!!!
  (message encoded-hex-hmac))

(setq hmac-secret "lX9yb3Jmj0MQD7oD7SrYMg==")

(json-encode data)

(define-hmac-function my-hmac
  (lambda (x) (secure-hash 'sha256 x nil nil 1))
  64 64)

(let* ((options (json-read-file "/Users/sixtynorth/projects/ycmd/options.json.BAK"))
       (hmac-secret  (base64-decode-string (cdr (assoc 'hmac_secret options)))))
  (message (format "%s" options))
  (message hmac-secret))

; BINGO!
(let* ((options (json-read-file "/Users/sixtynorth/projects/ycmd/options.json.BAK"))
       (hmac-secret (base64-decode-string (cdr (assoc 'hmac_secret options))))
       (content (json-encode data))
       (hmac (my-hmac content hmac-secret))
       (hex-hmac (encode-hex-string hmac))
       (encoded-hex-hmac (base64-encode-string hex-hmac 't)))
  (message encoded-hex-hmac)
  (request
   "http://127.0.0.1:64358/completions"
   :headers `(("Content-Type" . "application/json")
              ("X-Ycm-Hmac" . ,encoded-hex-hmac))
   :sync t
   :parser 'json-read
   :data content
   :type "POST")
  )
