{ IcecastServer } = require './icecast-server'

_ = require 'underscore'
_.str = require 'underscore.string'

lame = require 'lame'
Spotify = require 'spotify-web'
irc = require 'irc'

config = require '../config.json'

{ spotify, target } = config

icecastServer = new IcecastServer target

Spotify.login spotify.user, spotify.password, (err, spotify) ->
	return console.error err.stack if err?

	console.log "Logged in to Spotify..."

	ircClient =
		new irc.Client 'irc.esper.net', 'Jukeyboxie',
			channels: [ '#kellyirc' ]

	ircClient.on 'message', (nick, channel, text) ->
		if (match = /!play (spotify:track:[\w\d]+)/.exec text)?
			[full, uri] = match

			spotify.get uri, (err, track) ->
				return console.error err.stack if err?

				metadata =
					title: track.name
					artist: track.artist.map((a) -> a.name)
					album: track.album.name

				ircClient.say channel, "Now playing: #{metadata.title} by #{_.str.toSentence metadata.artist}"
				console.log "Playing", metadata

				lameDecoder = new lame.Decoder

				lameDecoder.on 'format', (inFormat) ->
					icecastServer.stream metadata, inFormat, lameDecoder

				track.play().pipe lameDecoder

		else if (match = /!icecast-url/.exec text)?
			ircClient.say channel, "Listen in at #{target.displayAddress} now!"