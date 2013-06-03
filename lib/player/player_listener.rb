
# Listener to the underlying java music player events.
module PlayerListener

	# Callback for opened event.
	def opened(stream, properties)
		# puts ":::::::::::::::: opended: stream => #{stream}, properties: => #{properties}"
		# "mp3.id3tag.track"=>"3",
		# "mp3.crc"=>false, "mp3.id3tag.orchestra"=>"Noel Gallagher",
		# "mp3.copyright"=>false, "album"=>"High Flying Birds  ",
		# "mp3.id3tag.genre"=>"Britpop",
		# "mp3.framesize.bytes"=>1040, "author"=>"Noel Gallagher",
		# "mp3.version.layer"=>"3",
		# "mp3.length.frames"=>9573, "mp3.vbr.scale"=>0, "mp3.bitrate.nominal.bps"=>320000, "mp3.version.encoding"=>"MPEG1L3",
		# "mp3.id3tag.v2"=>#<Java::JavaIo::ByteArrayInputStream:0x1cafa973>, "mp3.id3tag.publisher"=>"Sour Mash (Indigo)",
		# "mp3.padding"=>false, "audio.framerate.fps"=>38.28125, "mp3.length.bytes"=>9995066, "audio.channels"=>2, "mp3.framerate.fps"=>38.28125, "mp3.id3tag.disc"=>"1",
		# "mp3.vbr"=>false, "audio.samplerate.hz"=>44100.0, "mp3.original"=>true
		# "date"=>"2011",
		# "title"=>"If I Had A Gun",
		# "audio.type"=>"MP3",
		# "audio.length.bytes"=>9995066, "vbr"=>false, "mp3.id3tag.v2.version"=>"3",
		# "audio.length.frames"=>9573, "mp3.channels"=>2, "mp3.version.mpeg"=>"1",
		# "duration"=>250070000, "mp3.frequency.hz"=>44100, "mp3.header.pos"=>27658, "basicplayer.sourcedataline"=>#<#<Class:0x3a3c7b60>:0x3a83b5aa>, "bitrate"=>320000, "mp3.mode"=>0, "comment"=>"",
	end

	# Callback for progress event.
	def progress(bytesread, microseconds, pcmdata, properties)
		# puts ":::::::::::::::: progress: bytesread => #{bytesread}, microseconds => #{microseconds},  pcmdata => #{pcmdata}, properties => #{properties}"
#@song_status = properties
		# puts "------ #{@progress["mp3.frame"]} ::: #{@progress["mp3.position.byte"]}"
		# bytesread => 35850
		# microseconds: 0
		# pcmdata: [B@39bebb16, 
		# properties: {
		# "mp3.position.microseconds"=>26122, 
		# "mp3.frame.size.bytes"=>1040, 
		# "mp3.frame"=>1, 
		# "mp3.frame.bitrate"=>320000, 
		# "mp3.position.byte"=>1040
		# }
        update_progress(properties['mp3.position.microseconds'] / 1000000, properties['mp3.position.byte'], properties['mp3.frame.size.bytes'])
	end

	# Callback for stateUpdated event.
	def stateUpdated(event)
		# si esta reproduciendo..
		#if @status == :EOM
			# y llega un status de STOPPED y position -1
			# la rola se acabo y pasamos a la siguiente
			#puts ":::::::::::::::: Estando en OEM => #{STATES[event.code]}"
			#if STATES[event.code] == :STOPPED
				#self.next()
				#puts ":::::::::::::: Invoking Next! #{event.code}"
				#return self.execute('next')
			#end
		#end

#if STATES[event.code] == :EOM
    #return self.execute('next')
#end

#@status = STATES[event.code]
		#puts ":::::::::::::::: New status => #{@status}"
        update_state(Cultome::CultomePlayerListener::STATES[event.code])
	end

	# Callback for setController event.
	def setController(controller)
		# puts ":::::::::::::::: setController: controller => #{controller}"
	end
end