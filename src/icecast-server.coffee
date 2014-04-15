{ bitrate, pcmFormatConstant } = require './sound-util'

stream = require 'stream'

request = require 'request'

ogg = require 'ogg'
vorbis = require 'vorbis'
Throttle = require 'throttle'
pcmUtils = require 'pcm-utils'

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

		formatter = new pcmUtils.Formatter(
			pcmFormatConstant inFormat
			pcmFormatConstant outFormat
		)

		oggEncoder = new ogg.Encoder
		vorbisEncoder = new vorbis.Encoder outFormat

		for tag, cmt of metadata
			vorbisEncoder.addComment tag, cmt

		source
		.pipe formatter
		.pipe new Throttle (bitrate outFormat) / 8
		.pipe vorbisEncoder
		.pipe oggEncoder.stream()

		oggEncoder.on 'end', (a...) ->
			callback? a...

		oggEncoder.pipe @out, end: false

		this

	end: ->
		@out.end()