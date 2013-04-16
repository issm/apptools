class @Amon2
    @uri_for: (path) ->
        uri = URL_BASE.replace(/\/$/, '') + path
        return uri

class @MyApp

class MyApp.Util
    @ajax_params: (params) ->
        ret =
            url:  Amon2.uri_for( params.url )
            type: params.type ? 'get'
            dataType: 'json'
            data: params.data
            success: params.success
            error: params.error
        return ret
