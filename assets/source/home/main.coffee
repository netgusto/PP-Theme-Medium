define [
    'jquery',
    'menu/classie',
    'menu/mlpushmenu'
], ($, classie) ->
    'use strict'

    window.classie = classie

    new mlPushMenu( document.getElementById( 'mp-menu' ), document.getElementById( 'trigger' ) )