pcmUtils = require 'pcm-utils'

exports.bitrate = (format) -> format.sampleRate * format.bitDepth * format.channels

exports.pcmFormatConstant = (format) ->
	if format.float or format.bitDepth is 32 then pcmUtils.FMT_F32LE
	else if format.bitDepth is 16
		if format.signed then pcmUtils.FMT_S16LE
		else pcmUtils.FMT_U16LE