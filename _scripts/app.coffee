document.gignal =
  views: {}


class Post extends Backbone.Model

  idAttribute: 'objectId'
  re_links: /((http|https)\:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,3}(\/\S*)?)/g

  defaults:
    text: ''
    username: ''

  getData: =>
    text = @get 'text'
    text = text.replace @re_links, '<a href="$1" target="_blank">link</a>'
    text = null if text.indexOf(' ') is -1
    username = @get 'username'
    username = null if username.indexOf(' ') isnt -1
    direct = @get 'link'
    # todo: backbone this
    shareFB = 'javascript:getUrl("http://www.facebook.com/sharer.php?u=' + encodeURIComponent(direct) + '");'
    shareTT = 'javascript:getUrl("http://twitter.com/share?text=' + encodeURIComponent(direct) + '&url=' + encodeURIComponent(text) + '");'
    keyFB = '128990610442'
    postFB = 'javascript:getUrl("https://www.facebook.com/dialog/feed?app_id=' + keyFB + '&display=popup&link=' + encodeURIComponent(direct) + '&picture=' + encodeURIComponent(@get('large_photo')) + '&redirect_uri=' + encodeURIComponent('http://www.gignal.com/') + '");'
    # set date for humaneDate
    @set 'created', new Date(@get('created_on') * 1000)
    # prepare data
    data =
      message: text
      username: username
      name: @get 'name'
      since: humaneDate @get 'created'
      link: direct
      service: @get 'service'
      user_image: @get 'user_image'
      photo: if @get('large_photo') isnt '' then @get('large_photo') else false
      direct: direct
      shareFB: shareFB
      shareTT: shareTT
      postFB: postFB
      Twitter: @get 'original_id' if @get('service') is 'twitter'
      Facebook: @get 'original_id' if @get('service') is 'facebook'
      Instagram: @get 'original_id' if @get('service') is 'instagram'
    return data


class Stream extends Backbone.Collection

  model: Post

  url: ->
    eventid = document.gignal.eventid
    return '//d2yrqknqjcrf8n.cloudfront.net/feed/' + eventid + '?callback=?'
    # if document.location.protocol is 'http:'
    #   return 'http://api.gignal.com/feed/' + eventid + '?callback=?'
    # else
    #   return '//gignal.parseapp.com/feed/' + eventid + '?callback=?'

  calling: false
  parameters:
    limit: 30
    offset: 0
    sinceTime: 0

  initialize: ->
    @on 'add', @inset
    @update()
    # @setIntervalUpdate()
    @updateTimes()

  inset: (model) =>
    view = new document.gignal.views.UniBox
      model: model
    document.gignal.widget.$el.isotope 'insert', view.render().$el

  parse: (response) ->
    return response.stream

  comparator: (item) ->
    return - item.get 'created_on'

  isScrolledIntoView: (elem) ->
    docViewTop = $(window).scrollTop()
    docViewBottom = docViewTop + $(window).height()
    elemTop = $(elem).offset().top
    elemBottom = elemTop + $(elem).height()
    return ((elemBottom <= docViewBottom) && (elemTop >= docViewTop))

  update: (@append) =>
    return if @calling
    return if not @append and not @isScrolledIntoView '#gignal-stream header'
    @calling = true
    if not @append
      sinceTime = _.max(@pluck('saved_on'))
      if not _.isFinite sinceTime
        sinceTime = null
      offset = 0
    else
      sinceTime = _.min(@pluck('saved_on'))
      offset = @parameters.offset += @parameters.limit
    @fetch
      remove: false
      timeout: 15000
      jsonpCallback: 'callme'
      data:
        limit: @parameters.limit
        offset: offset if offset
        sinceTime: sinceTime if _.isFinite sinceTime
      success: =>
        @calling = false
      error: =>
        @calling = false


  setIntervalUpdate: ->
    sleep = 10000
    # floor by 5sec then add 5sec
    now = +new Date()
    start = (sleep * (Math.floor(now / sleep))) + sleep - now
    setTimeout ->
      sleep = 10000
      setInterval document.gignal.stream.update, sleep
    , start

  updateTimes: ->
    sleep = 30000
    setInterval ->
      $('.gignal-outerbox').each ->
        $(this).find('.since').html(humaneDate($(this).data('created')))
    , sleep
