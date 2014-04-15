{ bitrate, pcmFormatConstant } = require './sound-util'

stream = require 'stream'

request = require 'request'

ogg = require 'ogg'
vorbis = require 'vorbis'
Throttle = require 'throttle'
pcmUtils = require 'pcm-utils'

class exports.IcecastServer
	constructor: (@options) ->
		@req = request.put @options.address,
			auth: user: 'source', pass: @options.password
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
			cmt = [].concat cmt
			vorbisEncoder.addComment tag, c for c in cmt

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