type response 
@new external ofResponse: Js.Nullable.t<string> => response = "Response";

type request
@send external toJson: (request) => Js.Promise.t<Js.Json.t> = "json";

// @send external flatMap: (array<'a>, (. 'a) => array<'b>) => array<'b> = "flatMap";

type workFieldValueStr = string
type workFieldValueEntity = { id: string, name: string }

type workFieldValue = 
    | ValueNumber(int)
	| ValueStr(workFieldValueStr)
	| ValueArray(array<workFieldValueEntity>)

type workField = {
    flag: string,
    value: workFieldValue 
}

type doneWork = {
    fields: array<workField>
}

type wordRecord = { code: string, name: string, scope: string }

module BodyCodecs = {
    // 解析接收的 Json 包

    let workFieldValueStr = Jzon.string

    let workFieldValueEntity = Jzon.object2(
        ({ id, name }) => (id, name),
        ((id, name)) => { id, name }->Ok,
        Jzon.field("id", Jzon.string),
        Jzon.field("name", Jzon.string)
    )

    let workFieldValueArray = Jzon.array(workFieldValueEntity)

    // 自定义的解析对象
    // 针对一个 key 有多种 shape 进行定义
    let workFieldValue = Jzon.custom(
        (value) => {
           let jsonValue = switch value {
           | ValueNumber(i) => i->Jzon.encodeWith(Jzon.int)
           | ValueStr(str) => str->Jzon.encodeWith(workFieldValueStr)
           | ValueArray(array) => array->Jzon.encodeWith(workFieldValueArray) 
           }
           jsonValue
        },
        (jsonValue) => {
            switch jsonValue->Js.Json.classify {
            | Js.Json.JSONArray(_) => {
                jsonValue->Jzon.decodeWith(workFieldValueArray)->Belt.Result.map(it => ValueArray(it))
            } 
            | Js.Json.JSONString(_) => {
                jsonValue->Jzon.decodeWith(workFieldValueStr)->Belt.Result.map(it => ValueStr(it))
            } 
            | Js.Json.JSONNumber(_) => {
                jsonValue->Jzon.decodeWith(Jzon.int)->Belt.Result.map(it => ValueNumber(it))
            } 
            | _ => {
                ValueStr("")->Belt.Result.Ok
            }
            }
        }
    )

    let workField = Jzon.object2(
        ({ flag, value }) => (flag, value),
        ((flag, value))  => { flag, value }->Ok,
        Jzon.field("flag", Jzon.string),
        // 对于传递过来的对象 如果对应的 key 不存在 可以使用 Jzon.default 进行 fallback
        Jzon.field("value", workFieldValue)->Jzon.default(ValueStr("__unkonwn"))
    )

    let doneWork = Jzon.object1(
        ({ fields }) => fields,
        (fields) => { fields: fields }->Ok,
        Jzon.field("fields", Jzon.array(workField))
    )

    let body = Jzon.custom(
        // encoding
        tuple => {
            let (doneWorkArray, predicateArray) = tuple
            Js.Json.array([
                doneWorkArray->Jzon.encodeWith(Jzon.array(doneWork)),
                predicateArray->Jzon.encodeWith(Jzon.array(Jzon.string))
            ])
        },
        // decoding
        jsonValue => {
            switch jsonValue->Js.Json.classify {
            | Js.Json.JSONArray(array) => {
                let getDecodeResult = (codec, json) => switch json->Jzon.decodeWith(codec) {
                | Ok(ret) => ret 
                | Error(_) => []
                }

                switch array {
                | [doneWorkArray, predicateArray] => {
                    (
                        getDecodeResult(Jzon.array(doneWork), doneWorkArray),
                        getDecodeResult(Jzon.array(Jzon.string), predicateArray)
                    )->Ok
                }
                | _ => {
                    Error(#UnexpectedJsonValue([Field("body")], ""))
                }
                }
            }
            | _ => Error(#UnexpectedJsonValue([Field("body")], ""))
            }
        }
    )
}


let handleRequest = req => {
    open Promise
    open Js

    let dealDoneWork = doneWorks => {
        let getValue = (value) => {
            switch value {
            | ValueArray(a) => {
                switch a {
                | [entity] => entity.name
                | _ => "" 
                }
            }
            | ValueStr(c) => c 
            | ValueNumber(i) => i->String2.make
            }
        }

        doneWorks->Array2.map(
            (doneWork) => {
                let findValueByFlag = flagKey => {
                    doneWork.fields
                        ->Array2.find(({ flag }) => flag === flagKey )
                        ->Belt.Option.map(({ value }) => getValue(value))
                        ->Belt.Option.getWithDefault("")
                }
                // 如果 tuple 也能使用类似 map 的方法就好了
                let (code, name, scope) = (
                    "sourceField4"->findValueByFlag,
                    "771ac1a5-fca5-4af2-b744-27b16e989b18ANY-TRAIT-ID"->findValueByFlag,
                    "78e0707c875f40a790a1387c8e64e54c"->findValueByFlag
                )
                { code, name, scope }
            }
        )
    }

    req
    ->toJson
    ->thenResolve(
        body => {
            body->Jzon.decodeWith(BodyCodecs.body)
        }
    )
    ->thenResolve(
        (val) => {
            switch val {
            | Ok(body) => {
                let (doneWorks, _) = body;
                doneWorks
                ->dealDoneWork
                ->Json.stringifyAny
                ->Belt.Option.getWithDefault("test")
            }
            | Error(errType) => {
                Jzon.DecodingError.toString(errType)
            } 
            }
        }
    )
    ->thenResolve(
        (message) => {
            message->Nullable.return->ofResponse
        }
    )
}