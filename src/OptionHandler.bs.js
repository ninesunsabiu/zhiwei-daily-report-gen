// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_dict from '../node_modules/rescript/lib/es6/js_dict.js'
import * as Caml_option from '../node_modules/rescript/lib/es6/caml_option.js'

var corsHeaders = [
  ['Access-Control-Allow-Origin', '*'],
  ['Access-Control-Allow-Methods', 'POST,OPTIONS'],
  ['Access-Control-Max-Age', '86400'],
  ['Access-Control-Allow-Headers', 'Content-Type'],
]

function handleRequest(request) {
  var headers = request.headers
  var requestCorsHeader_0 = Caml_option.nullable_to_opt(headers.get('Origin'))
  var requestCorsHeader_1 = Caml_option.nullable_to_opt(
    headers.get('Access-Control-Request-Headers'),
  )
  var requestCorsHeader_2 = Caml_option.nullable_to_opt(
    headers.get('Access-Control-Request-Method'),
  )
  var origin = requestCorsHeader_0
  var newHeaders
  if (origin !== undefined) {
    var requestHeader = requestCorsHeader_1
    if (requestHeader !== undefined) {
      if (requestCorsHeader_2 !== undefined) {
        var headerDict = Js_dict.fromArray(corsHeaders)
        ;[
          ['Access-Control-Allow-Origin', origin],
          ['Access-Control-Allow-Headers', requestHeader],
        ].forEach(function (param) {
          headerDict[param[0]] = param[1]
        })
        newHeaders = headerDict
      } else {
        newHeaders = Js_dict.fromArray([['Allow', 'POST, OPTIONS']])
      }
    } else {
      newHeaders = Js_dict.fromArray([['Allow', 'POST, OPTIONS']])
    }
  } else {
    newHeaders = Js_dict.fromArray([['Allow', 'POST, OPTIONS']])
  }
  var __x_status = 200
  var __x_statusText = 'ok'
  var __x = {
    headers: newHeaders,
    status: __x_status,
    statusText: __x_statusText,
  }
  return Promise.resolve(new Response(undefined, __x))
}

export { corsHeaders, handleRequest }
/* No side effect */