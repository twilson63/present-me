using 'dirty'

get '/:owner': ->
  db = dirty("#{@owner}.db")
  db.on('load', =>
    @presentations = []
    db.forEach( (key, val) =>
      @presentations.push({ key: key, title: val.title })
    )
    render 'index'
  )

get '/:owner/new': ->
  render 'new'

view new: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> 'New Presentation'
    div 'data-role': 'content', ->
      form method: 'post', action: "/#{@owner}", ->
        div 'data-role': 'fieldcontain', ->
          label for: 'title', -> 'Title'
          input type: 'text', name: 'title', id: 'title'
        input type: 'submit', value: 'Create Presentation'

post '/:owner': ->
  db = dirty("#{@owner}.db")
  key = @title.split(' ').join('-').toLowerCase()
  db.on('load', => 
    db.set(key, { title: @title })
    redirect "/#{@owner}"
  )

view index: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> "#{@owner} Presentations"
    div 'data-role': 'content', ->
      ul 'data-role': 'listview', ->
        li -> a href: "/#{@owner}/new", -> 'Add New Presentation'
        for presentation in @presentations
          li -> a href: "/#{@owner}/#{presentation.key}", -> presentation.title


get '/:owner/:slug': ->
  db = dirty("#{@owner}.db")
  db.on('load', =>
    @presentation = db.get(@slug)
    @index = 0
    render 'show'
  )

view show: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> @presentation.title
    div 'data-role': 'content', ->
      ul 'data-role': 'listview', ->
        li -> a href: "/#{@owner}/#{@slug}/slides/new", -> 'Add New Slide'
        if @presentation.slides
          for slide in @presentation.slides
            li -> a href: "/#{@owner}/#{@slug}/slides/#{@index++}/edit", -> slide.title

  
get '/:owner/:slug/edit': ->
  db = dirty("#{@owner}.db")
  @slide = db.get(@slug)
  render 'edit'

view edit: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> 'Edit Presentation'
    div 'data-role': 'content', ->
      form method: 'put', action: "/#{@owner}/#{@slug}", ->
        div 'data-role': 'fieldcontain', ->
          label for: 'title', -> 'Title'
          input type: 'text', name: 'title', id: 'title'
        input type: 'submit', value: 'Update Presentation'


get '/:owner/:slug/play': ->
  db = dirty("#{@owner}.db")
  db.on 'load', =>
    @presentation = db.get(@slug)
    render 'play'

view play: ->
  div 'data-role': 'page', ->
    div 'data-role': 'content', ->
      h1 -> @presentation.title
  for slide in @presentation.slides
    div 'data-role': 'page', ->
      div 'data-role': 'content', -> slide.body

get '/:owner/:slug/slides/new': ->
  render 'new_slide'
  
view new_slide: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> 'New Slide'
    div 'data-role': 'content', ->
      form method: 'post', action: "/#{@owner}/#{@slug}/slides", ->
        div 'data-role': 'fieldcontain', ->
          label for: 'title', -> 'Title'
          input type: 'text', name: 'title', id: 'title'
        div 'data-role': 'fieldcontain', ->
          label for: 'body', -> 'Body'
          textarea name: 'body', id: 'body'
    
        input type: 'submit', value: 'Create Slide'

post '/:owner/:slug/slides': ->
  db = dirty("#{@owner}.db")
  db.on('load', =>
    @presentation = db.get(@slug)
    @presentation.slides = [] unless @presentation.slides
    @presentation.slides.push({ title: @title, body: @body }) 
    db.set(@slug, @presentation)
    redirect "/#{@owner}/#{@slug}"
  )

get '/:owner/:slug/slides/:id/edit': ->
  db = dirty("#{@owner}.db")
  db.on 'load', =>
    @presentation = db.get(@slug)
    @slide = @presentation.slides[@id]    
    render 'edit_slide'

view edit_slide: ->
  div 'data-role': 'page', ->
    div 'data-role': 'header', ->
      h1 -> 'Edit Slide'
    div 'data-role': 'content', ->
      form method: 'put', action: "/#{@owner}/#{@slug}/slides/#{@id}", ->
        div 'data-role': 'fieldcontain', ->
          label for: 'title', -> 'Title'
          input type: 'text', name: 'title', id: 'title', value: @slide.title
        div 'data-role': 'fieldcontain', ->
          label for: 'body', -> 'Body'
          textarea name: 'body', id: 'body', -> @slide.body

        input type: 'submit', value: 'Update Slide'
      form method: 'delete', action: "/#{@owner}/#{@slug}/slides/#{@id}", ->
        input type: 'submit', value: 'Delete Slide'

put '/:owner/:slug/slides/:id': ->
  db = dirty("#{@owner}.db")
  db.on('load', =>
    @presentation = db.get(@slug)
    @presentation.slides[@id] = { title: @title, body: @body }
    
    db.set(@slug, @presentation)
    redirect "/#{@owner}/#{@slug}"
  )
  
del '/:owner/:slug/slides/:id': ->
  db = dirty("#{@owner}.db")
  db.on('load', =>
    @presentation = db.get(@slug)
    @presentation.slides.slice(@id, 1)
    db.set(@slug, @presentation)
    redirect "/#{@owner}/#{@slug}"
  )
  

client app: ->
  $(document).ready ->
    # socket = new io.Socket('localhost', { port: 5678 })
    # socket.connect()
    # #socket.send('some data')
    # socket.on('slide_change', (data) ->
    #     alert('slide change')
    # )

    $('div[data-role="page"]').bind('swipeleft', -> 
      console.log 'swipe left'
      next_slide = $(this).next()
      $.mobile.changePage(next_slide, 'flip', false, false)
      #socket.send 'slide_change', { slide: 'foobar' }
    ).bind('swiperight', ->
      console.log 'swipe right'
      next_slide = $(this).prev()
      $.mobile.changePage(next_slide, 'flip', true, false)

    ).bind('pagebeforeshow', -> 
      console.log 'show page'
      content = $(this).children('div[data-role="content"]')
      content.children('h1').css('text-align','center')

    )

  

    
layout ->
  doctype 5
  html ->
    head ->
      title -> 'Present ME!'
      link rel: 'stylesheet', href: 'http://code.jquery.com/mobile/1.0a2/jquery.mobile-1.0a2.min.css'
      link rel: 'stylesheet', href: '/app.css'
      script src: 'http://code.jquery.com/jquery-1.4.4.min.js'
      script src: 'http://code.jquery.com/mobile/1.0a2/jquery.mobile-1.0a2.min.js'
      #script src: 'http://cdn.socket.io/stable/socket.io.js'
      script src: '/app.js'

    body -> @content
