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

                if(!history.state)
                    return

                if(!window.posts[history.state.slug])
                    # post is not in cache; this happens when the user reloads the page, and then uses the back function of it's history
                    @fetchPostThenExecuteCallback(history.state.slug, (post) =>

                        # We keep the post in the cache (for cache, and also history management)
                        window.posts[post.slug] = post;

                        # We replace the current article
                        @injectPostInArticle(@currentArticle, post);

                        # We notify the world about the post change
                        @notifyTheWorldAboutHtml5PostChange(post)
                    );
                else
                    @injectPostInArticle(@currentArticle, window.posts[history.state.slug]);
                    
                    # We notify the world about the post change
                    @notifyTheWorldAboutHtml5PostChange(window.posts[history.state.slug])

                if(history.state.followingslug)
                    if(!window.posts[history.state.followingslug])
                        # post is not in cache; this happens when the user reloads the page, and then uses the back function of it's history
                        @fetchPostThenExecuteCallback(history.state.followingslug, (post) =>

                            # We keep the post in the cache (for cache, and also history management)
                            window.posts[post.slug] = post;

                            # We replace the current article
                            if(!@followingArticle.get(0).parentNode)
                                @followingArticle.insertAfter(@currentArticle)

                            @injectPostInArticle(@followingArticle, post);
                        );
                    else
                        if(!@followingArticle.get(0).parentNode)
                            @followingArticle.insertAfter(@currentArticle)

                        @injectPostInArticle(@followingArticle, window.posts[history.state.followingslug]);
                else
                    @followingArticle.remove()
            )

            @articleSelector = articleSelector
            @currentArticleSelector = @articleSelector + '.current'
            @followingArticleSelector = @articleSelector + '.following'

            @currentArticle = $(@currentArticleSelector)
            @followingArticle = $(@followingArticleSelector)

            @articleTemplate = @createTemplateFromArticle(@currentArticle)

            @followingTemplate = @createTemplateFromArticle(@followingArticle)

            #eventname = if Modernizr.touch then 'touch' else 'click'
            eventname = 'click'
            $('html').on(eventname, @followingArticleSelector + ' .big-image', (e) =>
                
                # Everything starts here
                e.preventDefault()
                @followingArticle.removeClass('next-hidden')
                @animatePage((post) =>
                    @notifyTheWorldAboutHtml5PostChange(post)
                )
            )

            # We set the first step of the history
            @pushCurrentState(true)

        notifyTheWorldAboutHtml5PostChange: (post) =>

            console.log('notifyTheWorldAboutHtml5PostChange', post)

            # We inform the world about the post change
            $('html').trigger('mozza:html5postchange', {
                post: post
            })

            $('html').trigger('mozza:html5urlchange', {
                url: post.url
            })

        getSlugFromArticleElement: (article) =>
            return article.attr('data:slug')

        getFollowingSlugFromArticleElement: (article) =>
            return article.attr('data:followingslug')

        pushCurrentState: (replace = false) =>
            # We push the current step of the history
            currentArticleSlug = @getSlugFromArticleElement(@currentArticle)
            followingArticleSlug = @getFollowingSlugFromArticleElement(@currentArticle)
            pagestate = {
                slug: currentArticleSlug,
                followingslug: followingArticleSlug
            }

            if(replace)
                history.replaceState(pagestate, "", @getPostUrlFromSlug(currentArticleSlug))
            else
                history.pushState(pagestate, "", @getPostUrlFromSlug(currentArticleSlug))

        getPostUrlFromSlug: (slug) =>
            return window.posturl.replace(/\=slug\=/, slug)

        fetchPostThenExecuteCallback: (slug, cbk) =>
            jsonposturl = window.jsonposturl.replace(/\=slug\=/, slug)
            $.ajax(jsonposturl, {
                type: 'GET',
                success: cbk
            })

        animatePage: (cbk) =>
            
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

                cbk(window.posts[@getSlugFromArticleElement(@currentArticle)])

                # We have to create the new following article
                @followingArticle = @followingTemplate.clone()

                @canScroll = yes

                # 1. We fetch the new following-article
                followingslug = @currentArticle.attr('data:followingslug')
                if(followingslug && followingslug != 'null')

                    doWhenPostAvailable = (post) =>
                        @injectPostInArticle(@followingArticle, post);
                        @followingArticle.insertAfter(@currentArticle)

                        @pushCurrentState()

                    if(window.posts[followingslug])
                        # post is cached; we use it as is
                        doWhenPostAvailable(window.posts[followingslug])
                    else
                        # post is not cached; we fetch it, and then cache it
                        @fetchPostThenExecuteCallback(followingslug, (post) =>

                            # We keep the post in the cache (for cache, and also history management)
                            window.posts[post.slug] = post;

                            doWhenPostAvailable(post)
                        );
                else
                    @pushCurrentState()
            
            window.setTimeout(timeoutFunc, 500)

        scrollTop: () =>
            $(document.body).add($(window.html)).add($('.scroller')).scrollTop(0)

        injectPostInArticle: (article, post) =>
            bgimage = if post.image then 'url(' + post.image + ')' else ''

            article.attr('data:slug', post.slug)
            article.attr('data:followingslug', post.previous_slug)

            article.find('.big-image').css({ backgroundImage: bgimage })
            article.find('h1.title').html(post.title || '')
            article.find('h2.description').html(post.intro || '')
            article.find('.content .text').html(post.content || '')
            article.find('h3.byline time').html(post.date_human || '')
            article.find('h3.byline .author').html(post.author || '')
            article.find('h3.byline .about').html(post.about || '')

            article

        createTemplateFromArticle: (article) =>
            template = article.clone()
            template.removeClass('next-hidden')
            @injectPostInArticle(template, {})

        elementToTemplate: (element) =>
            $(element).get(0).outerHTML