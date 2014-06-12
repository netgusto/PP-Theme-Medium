define [
    'jquery',
    'post/articleanimator',
    'menu/classie',
    'menu/mlpushmenu'
], ($, articleanimator, classie) ->
    'use strict'

    new articleanimator('article.page')
    window.classie = classie

    new mlPushMenu( document.getElementById( 'mp-menu' ), document.getElementById( 'trigger' ) )

    $('html').on('mozza:html5urlchange', (e, data) ->

        # update google analytics if present on page
        if(window.ga && typeof window.ga == 'function')
            # parse URL and get path
            a = $('<a>', { href: data.url } )[0]
            window.ga('send', 'pageview', a.pathname);
    )