verifyEmail = false

initialDataLoad = (collectionName, collection) ->
  if collection.find().count() == 0
    console.log 'Importing ' + collectionName + ' to db'
    data = JSON.parse(Assets.getText('flows/' + collectionName + '.json'))
    data.forEach (item, index, array) ->
      collection.insert item
      return
  return

Accounts.config sendVerificationEmail: verifyEmail

Meteor.startup ->
  Mandrill.config
    username: "egor.ovcharenko@gmail.com",  # the email address you log into Mandrill with. Only used to set MAIL_URL.
    key: "TubDT9uXZABrems38xp7ew"  # get your Mandrill key from https://mandrillapp.com/settings/index
    port: 587

  # read environment variables from Meteor.settings
  if Meteor.settings and Meteor.settings.env and _.isObject(Meteor.settings.env)
    for variableName of Meteor.settings.env
      process.env[variableName] = Meteor.settings.env[variableName]
  # import data only when collection is empty
  initialDataLoad 'accounts', @AccountsColl
  initialDataLoad 'tasks', @Tasks
  initialDataLoad 'entities', @Entities
  initialDataLoad 'flows', @Flows
  initialDataLoad 'roles', @Roles
  testEmail = "egor@gmail.com"
  testUser = Meteor.users.findOne({'profile.email': testEmail})
  if not testUser
    Accounts.createUser {
      email: testEmail
      password: "qweasd"
      profile: { name: "Егор Овчаренко", accountId: "allshellac" }
    }
  demoUser = Meteor.users.findOne({'profile.accountId': "demoAccount"})
  if not demoUser
    Accounts.createUser {
      email: "demo@example.com"
      password: "qweasd"
      profile: { name: "Demo User", accountId: "demoAccount" }
    }
  #
  # Setup OAuth login service configuration (read from Meteor.settings)
  #
  # Your settings file should look like this:
  #
  # {
  #     "oauth": {
  #         "google": {
  #             "clientId": "yourClientId",
  #             "secret": "yourSecret"
  #         },
  #         "github": {
  #             "clientId": "yourClientId",
  #             "secret": "yourSecret"
  #         }
  #     }
  # }
  #
  if Accounts and Accounts.loginServiceConfiguration and Meteor.settings and Meteor.settings.oauth and _.isObject(Meteor.settings.oauth)
    # google
    if Meteor.settings.oauth.google and _.isObject(Meteor.settings.oauth.google)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'google'
      settingsObject = Meteor.settings.oauth.google
      settingsObject.service = 'google'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
    # github
    if Meteor.settings.oauth.github and _.isObject(Meteor.settings.oauth.github)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'github'
      settingsObject = Meteor.settings.oauth.github
      settingsObject.service = 'github'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
    # linkedin
    if Meteor.settings.oauth.linkedin and _.isObject(Meteor.settings.oauth.linkedin)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'linkedin'
      settingsObject = Meteor.settings.oauth.linkedin
      settingsObject.service = 'linkedin'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
    # facebook
    if Meteor.settings.oauth.facebook and _.isObject(Meteor.settings.oauth.facebook)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'facebook'
      settingsObject = Meteor.settings.oauth.facebook
      settingsObject.service = 'facebook'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
    # twitter
    if Meteor.settings.oauth.twitter and _.isObject(Meteor.settings.oauth.twitter)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'twitter'
      settingsObject = Meteor.settings.oauth.twitter
      settingsObject.service = 'twitter'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
    # meteor
    if Meteor.settings.oauth.meteor and _.isObject(Meteor.settings.oauth.meteor)
      # remove old configuration
      Accounts.loginServiceConfiguration.remove service: 'meteor-developer'
      settingsObject = Meteor.settings.oauth.meteor
      settingsObject.service = 'meteor-developer'
      # add new configuration
      Accounts.loginServiceConfiguration.insert settingsObject
  return
Meteor.methods
  'createUserAccount': (options) ->
    if !Users.isAdmin(Meteor.userId())
      throw new (Meteor.Error)(403, 'Access denied.')
    userOptions = {}
    if options.username
      userOptions.username = options.username
    if options.email
      userOptions.email = options.email
    if options.password
      userOptions.password = options.password
    if options.profile
      userOptions.profile = options.profile
    if options.profile and options.profile.email
      userOptions.email = options.profile.email
    Accounts.createUser userOptions
    return
  'updateUserAccount': (userId, options) ->
    # only admin or users own profile
    if !(Users.isAdmin(Meteor.userId()) or userId == Meteor.userId())
      throw new (Meteor.Error)(403, 'Access denied.')
    # non-admin user can change only profile
    if !Users.isAdmin(Meteor.userId())
      keys = Object.keys(options)
      if keys.length != 1 or !options.profile
        throw new (Meteor.Error)(403, 'Access denied.')
    userOptions = {}
    if options.username
      userOptions.username = options.username
    if options.email
      userOptions.email = options.email
    if options.password
      userOptions.password = options.password
    if options.profile
      userOptions.profile = options.profile
    if options.profile and options.profile.email
      userOptions.email = options.profile.email
    if options.roles
      userOptions.roles = options.roles
    if userOptions.email
      email = userOptions.email
      delete userOptions.email
      userOptions.emails = [ { address: email } ]
    password = ''
    if userOptions.password
      password = userOptions.password
      delete userOptions.password
    if userOptions
      Users.update userId, $set: userOptions
    if password
      Accounts.setPassword userId, password
    return
  'sendMail': (options) ->
    @unblock()
    Email.send options
    return

Accounts.onCreateUser (options, user) ->
  user.roles = [ 'executer' ]
  if options.profile
    user.profile = options.profile
  user

Accounts.validateLoginAttempt (info) ->
  # reject users with role "blocked"
  if info.user and Users.isInRole(info.user._id, 'blocked')
    throw new (Meteor.Error)(403, 'Your account is blocked.')
  if verifyEmail and info.user and info.user.emails and info.user.emails.length and !info.user.emails[0].verified
    throw new (Meteor.Error)(499, 'E-mail not verified.')
  true

Users.before.insert (userId, doc) ->
  if doc.emails and doc.emails[0] and doc.emails[0].address
    doc.profile = doc.profile or {}
    doc.profile.email = doc.emails[0].address
  else
    # oauth
    if doc.services
      # google e-mail
      if doc.services.google and doc.services.google.email
        doc.profile = doc.profile or {}
        doc.profile.email = doc.services.google.email
      else
        # github e-mail
        if doc.services.github and doc.services.github.accessToken
          github = new GitHub(
            version: '3.0.0'
            timeout: 5000)
          github.authenticate
            type: 'oauth'
            token: doc.services.github.accessToken
          try
            result = github.user.getEmails({})
            email = _.findWhere(result, primary: true)
            if !email and result.length and _.isString(result[0])
              email = email: result[0]
            if email
              doc.profile = doc.profile or {}
              doc.profile.email = email.email
          catch e
            console.log e
        else
          # linkedin email
          if doc.services.linkedin and doc.services.linkedin.emailAddress
            doc.profile = doc.profile or {}
            doc.profile.name = doc.services.linkedin.firstName + ' ' + doc.services.linkedin.lastName
            doc.profile.email = doc.services.linkedin.emailAddress
          else
            if doc.services.facebook and doc.services.facebook.email
              doc.profile = doc.profile or {}
              doc.profile.email = doc.services.facebook.email
            else
              if doc.services.twitter and doc.services.twitter.email
                doc.profile = doc.profile or {}
                doc.profile.email = doc.services.twitter.email
              else
                if doc.services['meteor-developer'] and doc.services['meteor-developer'].emails and doc.services['meteor-developer'].emails.length
                  doc.profile = doc.profile or {}
                  doc.profile.email = doc.services['meteor-developer'].emails[0].address
  return

Users.before.update (userId, doc, fieldNames, modifier, options) ->
  if modifier.$set and modifier.$set.emails and modifier.$set.emails.length and modifier.$set.emails[0].address
    modifier.$set.profile.email = modifier.$set.emails[0].address
  return

Accounts.onLogin (info) ->

Accounts.urls.resetPassword = (token) ->
  Meteor.absoluteUrl 'reset_password/' + token

Accounts.urls.verifyEmail = (token) ->
  Meteor.absoluteUrl 'verify_email/' + token
