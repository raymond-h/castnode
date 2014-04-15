{ IcecastServer } = require './icecast-server'

_ = require 'underscore'

lame = require 'lame'
Spotify = require 'spotify-web'

config = require '../config.json'

spotifyUrls = [
	'spotify:track:4C1b6JHElDfsDD1mY1gsxS'
	'spotify:track:6WP64G01l6k2fdomEl5Vrs'
]

{ spotify, target } = config

icecastServer = new IcecastServer target.address, target.password

Spotify.login spotify.user, spotify.password, (err, spotify) ->
	return console.error err.stack if err?

	console.log "Logged in to Spotify..."

	spotify.get spotifyUrls[0], (err, track) ->
		return console.error err.stack if err?

		metadata =
			title: track.name
			artist: track.artist.map((a) -> a.name).join ', '
			album: track.album.name

		console.log "Now playing: #{metadata.title} by #{metadata.artist}"

		lameDecoder = new lame.Decoder

		lameDecoder.on 'format', (inFormat) ->
			icecastServer.stream metadata, inFormat, lameDecoder, ->
				icecastServer.end()
				spotify.disconnect()

		track.play().pipe lameDecoder