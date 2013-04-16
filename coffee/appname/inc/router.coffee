###
 *
 * Router - URLハッシュを基に各処理へルーティングする
 *
 *   r = new Router()
 *   r.connect(
 *       '/user/([0-9]+)',
 *       (m) ->
 *           user_id = m[0]
 *           return true
 *   m = r.match( 'http://example.com/#!/user/1234' )
 *   m.run()
 *
###
class @Router
    constructor: (params = {}) ->
        @_rules = []
        for k, v of params.connect ? {}
            @connect k, v

    connect: (hash, action) ->
        @_rules.push
            hash: hash
            action: ( action ? -> )
        return @

    match: (url_hash) ->
        url_hash = url_hash.replace( new RegExp('^.*#!?'), '' )  # # or #! を含む以前を削除

        r = @_rules
        for v, i in r
            h = v.hash
            a = v.action
            re_h = new RegExp( ('^' + h + '$').replace(/^\^+/, '^').replace(/\$+$/, '$') )
            m = url_hash.match(re_h)

            if m != null
                # 通常のキャプチャ
                ret =
                    hash:    h
                    action:  a
                    matched: m
                    run:     (o) ->
                        m.shift()
                        return a.apply(o, [m])
                ret = (o) ->
                    m.shift()
                    return a.apply(o, [m])
                break

        if !ret?
            ret = (o) =>
                return @_cannot_route.apply(o, [url_hash])
        return ret

    _cannot_route: (h) ->
        throw new Error('cannot route: ' + h)
