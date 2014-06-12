define [
    'jquery',
    'post/articleanimator',
    'post/hoverbar',
    'menu/classie',
    'menu/mlpushmenu'
], ($, articleanimator, hoverbar, classie) ->
    'use strict'

    new articleanimator('article.page')
    #new hoverbar('.hoverbar')
    window.classie = classie

    new mlPushMenu( document.getElementById( 'mp-menu' ), document.getElementById( 'trigger' ) )