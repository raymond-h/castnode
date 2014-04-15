{ bitrate } = require './sound-util'

request = require 'request'

ogg = require 'ogg'
vorbis = require 'vorbis'
Throttle = require 'throttle'

class exports.IcecastServer
	constructor: (@hostPath, @password) ->
		@req = request.put @hostPath,
			auth: user: 'source', pass: @password
			headers: 'content-type': 'application/ogg'

		@out = new stream.PassThrough

		@out.pipe @req

	stream: (metadata, inFormat, source, callback) ->
		outFormat =
			sampleRate: 44100
			bitDepth: 32
			channels: 2
			float: true

		console.log "Got in format", inFormat

		oggEncoder = new ogg.Encoder
		vorbisEncoder = new vorbis.Encoder inFormat

		for tag, cmt of metadata
			vorbisEncoder.addComment tag, cmt

		source
		.pipe new Throttle (bitrate inFormat) / 8
		.pipe vorbisEncoder
		.pipe oggEncoder.stream()

		oggEncoder.on 'end', (a...) ->
			callback? a...

		oggEncoder.pipe @out, end: false

		setTimeout ->
			oggEncoder.unpipe @out
			((a...) -> callback? a...)()

		, 6000

		this

	end: ->
		@out.end()