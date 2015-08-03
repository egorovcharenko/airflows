pageSession = new ReactiveDict

Template.RegisterInvite.rendered = ->
  pageSession.set 'errorMessage', ''
  pageSession.set 'verificationEmailSent', false
  Meteor.defer ->
    $('input[autofocus]').focus()
    return
  return

Template.RegisterInvite.created = ->
  pageSession.set 'errorMessage', ''
  return

@checkRegistrationForm = (t) ->
   # check name
   if register_name == ''
     pageSession.set 'errorMessage', 'Пожалуйста, введите ваше имя'
     t.find('#register_name').focus()
     return false
   # check email
   if !isValidEmail(register_email)
     pageSession.set 'errorMessage', 'Пожалуйста, введите корректный email'
     t.find('#register_email').focus()
     return false
   # check password
   min_password_len = 6
   if !isValidPassword(register_password, min_password_len)
     pageSession.set 'errorMessage', 'Your password must be at least ' + min_password_len + ' characters long.'
     t.find('#register_password').focus()
     return false

Template.RegisterInvite.events
  'submit #register_form': (e, t) ->
    e.preventDefault()
    submit_button = $(t.find(':submit'))
    register_name = t.find('#register_name').value.trim()
    register_email = t.find('#register_email').value.trim()
    register_password = t.find('#register_password').value

    checkRegistrationForm(t)

    # создать аккаунт
    data = {
      email: register_email
      password: register_password
      profile: { name: register_name},
      inviteToken: this.token
    }
    Meteor.call "createUserWithInvitation", data, (error, result) ->
      if error
        Materialize.toast error.reason, 4000
      if result
        Materialize.toast "Аккаунт успешно создан", 4000
        Router.go 'login'

  'click .go-home': (e, t) ->
    Router.go '/'
    return

Template.RegisterInvite.helpers
  errorMessage: ->
    pageSession.get 'errorMessage'
