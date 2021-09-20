type workFieldValueStr = string
type workFieldValueInt = int
type workFieldValueEntity = { id: string, name: string }

type workFieldValue = 
    | ValueNumber(workFieldValueInt)
	| ValueStr(workFieldValueStr)
	| ValueArray(array<workFieldValueEntity>)

type workField = {
    flag: string,
    value: workFieldValue 
}

type doneWork = {
    fields: array<workField>
}

type predicateWork = {
    content: string,
    created: string
}


type workRecord = { code: string, name: string, scope: string }

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

    let predicateWork = Jzon.object2(
        ({ content, created }) => (content, created),
        ((content, created)) => { content, created }->Ok,
        Jzon.field("content", Jzon.string),
        Jzon.field("created", Jzon.string)
    )

    let body = Jzon.custom(
        // encoding
        tuple => {
            let (doneWorkArray, predicateArray) = tuple
            Js.Json.array([
                doneWorkArray->Jzon.encodeWith(Jzon.array(doneWork)),
                predicateArray->Jzon.encodeWith(Jzon.array(predicateWork))
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
                        getDecodeResult(Jzon.array(predicateWork), predicateArray)
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

    module DateUtil = {
        let timeZone = 8.0

        let transToCst = date => {
            let offset = date->Date.getTimezoneOffset
            Date.fromFloat(
                (Date.getTime(date) +. offset *. 60.0 *. 1000.0 +. timeZone *. 3600.0 *. 1000.0)
            )
        }

        let date = Date.make()

        let today = date->transToCst

        let todayIsMonday = today->Date.getDay === 1.0

        let isToday = date => {
            let predicateDateStr = date->transToCst->Date.toDateString
            predicateDateStr === today->Date.toDateString
        }

    }

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

        module WorkRecordComp = unpack(
            Belt.Id.comparableU(
                ~cmp=(.left: workRecord, right: workRecord) => Pervasives.compare(left.code, right.code)
            )
        )

        doneWorks
        ->Array2.map(
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
        ->Belt.Set.fromArray(~id=module(WorkRecordComp))
        ->Belt.Set.toArray
        ->Array2.mapi(
            ({ code, name, scope }, idx) => `${(idx + 1)->Int.toString}: #${code} ${name} ${scope}`
        )
        ->Array2.joinWith("\n")
    }

    let dealPredicateWork = predicateWorks => {
        let targetContentRe = %re("/^猜测你今天可能要进行工作的卡片[:：]\\n\\n/")
        predicateWorks
        ->Array2.find(
            ({ content, created }) => {
                content->Re.test_(targetContentRe, _) && created->Date.fromString->DateUtil.isToday
            }
        )
        ->Belt.Option.map(
            ({ content }) => content->String2.replaceByRe(targetContentRe, "")
        )
        ->Belt.Option.getWithDefault("")
    }

    req
    ->Request.toJson
    ->thenResolve(Jzon.decodeWith(_, BodyCodecs.body))
    ->thenResolve(
        (val) => {
            switch val {
            | Ok(body) => {
                let (doneWorks, predicateWorks) = body;
                // 这里竟然有中文转换的问题 不能直接使用双引号
                let start = if DateUtil.todayIsMonday {
                    `上周/周末`
                } else {
                    %raw(`"昨天"`)
                }
                `${start}\n${doneWorks->dealDoneWork}\n今天:\n${predicateWorks->dealPredicateWork}\n求助:\n暂无`
            }
            | Error(errType) => {
                Jzon.DecodingError.toString(errType)
            } 
            }
        }
    )
    ->thenResolve(
        (body) => {
            let origin = req.headers->Request.getHeader("Origin")->Belt.Option.getWithDefault("*")
            let headers = Dict.fromArray([("Access-Control-Allow-Origin", origin)])
            Response.make(~body, ~init={ headers, status: Some(200), statusText: Some("ok") }, ())
        }
    )
}