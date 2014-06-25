define [
    'jquery',
    'highlightjs',
    'post/articleanimator',
    'menu/classie',
    'menu/mlpushmenu'
], ($, highlightjs, articleanimator, classie) ->
    'use strict'

    hljs.configure({ tabReplace: '    '})
    hljs.initHighlighting()

    new articleanimator('article.page')
    window.classie = classie

    new mlPushMenu( document.getElementById( 'mp-menu' ), document.getElementById( 'trigger' ) )

    $('html').on('pulpy:html5urlchange', (e, data) ->

        $('pre code').each((i, e) ->
            hljs.highlightBlock(e)
        )

        # update google analytics if present on page
        if(window.ga && typeof window.ga == 'function')
            # parse URL and get path
            a = $('<a>', { href: data.url } )[0]
            window.ga('send', 'pageview', a.pathname);
    )