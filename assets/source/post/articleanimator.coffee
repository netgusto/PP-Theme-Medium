define ['jquery'], ($) ->
    'use strict'

    class ArticleAnimator

        constructor: (articleSelector) ->

            # Taming the mouse scroll
            @canScroll = yes
            $(window).on('mousewheel', (e) =>
                if(!@canScroll)
                    e.preventDefault()
            )

            # Taming the history
            $(window).on('popstate', (e) =>

                console.log('LAAAAAAA', e.state)
                #if(!history.state)
                #    console.log('NOOOO')
                #    return

                console.log(history.state)
                ###
                self.currentPostIndex = history.state.index;
                self.$current.replaceWith( history.state.current );
                self.$next.replaceWith( history.state.next );

                self.refreshCurrentAndNextSelection();
                self.createPost({ type: 'next' });
                self.bindGotoNextClick();
                ###
            )

            @articleSelector = articleSelector
            @currentArticleSelector = @articleSelector + '.current'
            @followingArticleSelector = @articleSelector + '.following'

            @currentArticle = $(@currentArticleSelector)
            @followingArticle = $(@followingArticleSelector)

            @articleTemplate = @createTemplateFromArticle(@currentArticle)

            @followingTemplate = @createTemplateFromArticle(@followingArticle)

            eventname = if Modernizr.touch then 'touchstart' else 'click'
            $('html').on(eventname, @followingArticleSelector + ' .big-image', (e) =>
                
                # Everything starts here
                e.preventDefault()
                @animatePage()
            )

            # We set the first step of the history
            @pushCurrentState()

        pushCurrentState: () =>
            # We push the current step of the history
            currentArticleSlug = @getCurrentArticleSlug()
            pagestate = { slug: currentArticleSlug }
            history.pushState(pagestate, "", @getPostUrlFromSlug(currentArticleSlug))

        getCurrentArticleSlug: () =>
            return @currentArticle.attr('data:slug')

        getPostUrlFromSlug: (slug) =>
            return window.posturl.replace(/\=slug\=/, slug)

        fetchPostThenExecuteCallback: (slug, cbk) =>
            jsonposturl = window.jsonposturl.replace(/\=slug\=/, slug)
            $.ajax(jsonposturl, {
                type: 'GET',
                success: cbk
            })

        animatePage: () =>
            
            @canScroll = no

            translationValue = @followingArticle.get(0).getBoundingClientRect().top
            @currentArticle.addClass('fade-up-out')
            @followingArticle.removeClass('content-hidden following')
                .addClass('easing-upward')
                .css({ "transform": "translate3d(0, -" + translationValue + "px, 0)" })

            timeoutFunc = () =>
                @scrollTop()
                
                @followingArticle.removeClass('easing-upward')
                @currentArticle.remove()

                @followingArticle.css({ "transform": "" })
                @followingArticle.addClass('current')
                @currentArticle = @followingArticle

                # We have to create the new following article
                @followingArticle = @followingTemplate.clone()

                @canScroll = yes

                @pushCurrentState()

                # 1. We fetch the new following-article
                followingslug = @currentArticle.attr('data:followingslug')
                if(followingslug && followingslug != 'null')
                    
                    @fetchPostThenExecuteCallback(followingslug, (post) =>
                        @injectDataInArticle(@followingArticle, {
                            image: post.image,
                            title: post.title,
                            intro: post.intro,
                            content: post.content,
                            time: post.date_human,
                            author: post.author,
                            slug: post.slug,
                            followingslug: post.previous_slug
                        });
                        @followingArticle.insertAfter(@currentArticle)
                    );
            
            window.setTimeout(timeoutFunc, 500)

        scrollTop: () =>
            $(document.body).add($(window.html)).scrollTop(0)

        injectDataInArticle: (article, data) =>
            bgimage = if data.image then 'url(' + data.image + ')' else ''

            article.attr('data:slug', data.slug)
            article.attr('data:followingslug', data.followingslug)

            article.find('.big-image').css({ backgroundImage: bgimage })
            article.find('h1.title').html(data.title || '')
            article.find('h2.description').html(data.intro || '')
            article.find('.content .text').html(data.content || '')
            article.find('h3.byline time').html(data.time || '')
            article.find('h3.byline .author').html(data.author || '')
            article.find('h3.byline .about').html(data.about || '')

            article

        createTemplateFromArticle: (article) =>
            template = article.clone()
            @injectDataInArticle(template, {})

        createArticleFromTemplate: (data) =>
            article = @articleTemplate.clone()
            @injectDataInArticle(article, data)

        elementToTemplate: (element) =>
            $(element).get(0).outerHTML