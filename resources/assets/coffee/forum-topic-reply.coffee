###
# Copyright 2015 ppy Pty. Ltd.
#
# This file is part of osu!web. osu!web is distributed with the hope of
# attracting more community contributions to the core ecosystem of osu!.
#
# osu!web is free software: you can redistribute it and/or modify
# it under the terms of the Affero GNU General Public License version 3
# as published by the Free Software Foundation.
#
# osu!web is distributed WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with osu!web.  If not, see <http://www.gnu.org/licenses/>.
###
class @ForumTopicReply
  container: document.getElementsByClassName('js-forum-topic-reply--container')
  box: document.getElementsByClassName('js-forum-topic-reply')
  input: document.getElementsByClassName('js-forum-topic-reply--input')
  closeButton: document.getElementsByClassName('js-forum-topic-reply--close')
  marker: -> document.querySelector('.js-sticky-footer[data-sticky-footer-target="forum-topic-reply"]')
  $input: -> $('.js-forum-topic-reply--input')

  constructor: (forum, stickyFooter) ->
    @forum = forum
    @stickyFooter = stickyFooter

    $(document).on 'ajax:success', '.js-forum-topic-reply', @posted

    $(document).on 'click', '.js-forum-topic-reply--close', @deactivate
    $(document).on 'click', '.js-forum-topic-reply--new', @activate
    $(document).on 'ajax:success', '.js-forum-topic-reply--quote', @activateWithReply

    $(document).on 'focus', '.js-forum-topic-reply--input', @activate
    $(document).on 'input change', '.js-forum-topic-reply--input', _.debounce(@inputChange, 500)

    $.subscribe 'stickyFooter', @stickOrUnstick

    $(document).on 'ready page:load', @initialise
    @initialise()


  initialise: =>
    return unless @available()

    @deleteState 'sticking'
    @input[0].value = @getState 'text'
    @activate() if @getState('active') == '1'


  available: => @box.length


  deleteState: (key, value) =>
    localStorage.removeItem "forum-topic-reply--#{document.location.pathname}--#{key}"


  getState: (key, value) =>
    localStorage.getItem("forum-topic-reply--#{document.location.pathname}--#{key}", value)


  setState: (key, value) =>
    localStorage.setItem("forum-topic-reply--#{document.location.pathname}--#{key}", value)


  activate: (e) =>
    e.preventDefault() if e

    @setState 'active', '1'

    @stickyFooter.markerEnable @marker()
    $.publish 'stickyFooter:check'


  activateWithReply: (e, data) =>
    data += '\n'

    $input = @$input()

    currentInput = $input.val()
    data = "#{currentInput}\n\n#{data}" if currentInput

    $input.val(data)
    @inputChange()
    $input[0].selectionStart = data.length

    @activate(e)


  deactivate: (e) =>
    e.preventDefault() if e

    @stickyFooter.markerDisable @marker()
    @setState 'active', '0'
    $.publish 'stickyFooter:check'


  inputChange: =>
    @setState 'text', @input[0].value


  posted: (_e, data) =>
    @deactivate()
    @$input().val ''
    @setState 'text', ''

    if @forum.lastPostLoaded()
      @forum.setTotalPosts(@forum.totalPosts() + 1)
      @forum.endPost().insertAdjacentHTML 'afterend', data
      osu.pageChange()

      @forum.endPost().scrollIntoView()
    else
      osu.navigate $(data).find('.js-post-url').attr('href')


  stick: =>
    return if @getState('sticking') == '1'

    @setState 'sticking', '1'

    bottom = document.getElementsByClassName('js-sticky-footer--fixed-bar')[0].offsetHeight

    @box[0].style.position = 'fixed'
    @box[0].style.bottom = "#{bottom}px"
    @closeButton[0].classList.remove 'hidden'
    @$input().focus()


  unstick: (e) =>
    return unless @getState('sticking') == '1'

    @deleteState 'sticking'

    @box[0].style.position = ''
    @box[0].style.bottom = ''
    @closeButton[0].classList.add 'hidden'


  stickOrUnstick: (_e, target) =>
    if target == 'forum-topic-reply'
      @stick()
    else
      @unstick()
