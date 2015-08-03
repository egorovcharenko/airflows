pageSession = new ReactiveDict

Template.Register.rendered = ->
  pageSession.set 'errorMessage', ''
  pageSession.set 'verificationEmailSent', false
  Meteor.defer ->
    $('input[autofocus]').focus()
    return
  return

Template.Register.created = ->
  pageSession.set 'errorMessage', ''
  return

Template.Register.events
  'submit #register_form': (e, t) ->
    e.preventDefault()
    submit_button = $(t.find(':submit'))
    register_name = t.find('#register_name').value.trim()
    register_email = t.find('#register_email').value.trim()
    register_password = t.find('#register_password').value
    register_account_name = t.find('#register_account_name').value.trim()

    checkRegistrationForm(t)

    # check account
    if register_account_name == ''
      pageSession.set 'errorMessage', 'Пожалуйста, введите название аккаунта'
      t.find('#register_account_name').focus()
      return false

    # создать аккаунт
    data = {
      email: register_email
      password: register_password
      profile: { name: register_name},
      register_account_name: register_account_name
    }
    Meteor.call "createUserAndAccount", data, (error, result) ->
      if error
        Materialize.toast error.reason, 4000
      if result
        Materialize.toast "Аккаунт успешно создан", 4000
        Router.go 'login'

  'click .go-home': (e, t) ->
    Router.go '/'
    return

Template.Register.helpers
  errorMessage: ->
    pageSession.get 'errorMessage'
