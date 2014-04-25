[![Gem Version](https://badge.fury.io/rb/cultome_player.png)](http://badge.fury.io/rb/cultome_player)
[![Build Status](https://travis-ci.org/cultome/cultome_player.svg)](https://travis-ci.org/cultome/cultome_player)
[![Coverage Status](https://coveralls.io/repos/cultome/cultome_player/badge.png)](https://coveralls.io/r/cultome/cultome_player)

# Cultome Player
A handy music library explorer. Is designed to facilitate you to play the music you like in the moment you want.

**"I want to play exactly this music"**

The player is designed around this concept, so it has commands to help you find music in your library and play it.

## Usage

Lets see a couple examples and translate it to what to expect

```ruby
play a:weird
```
Generate a playlist with songs whose artist contains the string 'weird' in their name.

```ruby
play @history
```
Generate a playlist with all the songs you have heard in this session.

```ruby
play a:gorillaz b:demon
```
Generate a playlist with songs from albums that contains the string 'demon' in their name and their artist's name contains the string 'gorillaz'

```ruby
search rose
```
Finds all the songs whose title, artist'name or album's name has the string 'rose' in them.

```ruby
play 12
```
From the *focused list*, play the 12th item but dont modify the *current playlist*. If the *focused list* is a list of songs, then play a song, but if the *focused list* is of artists o albums, the play all the song from that artist o album.

```ruby
play @album
```
Generate a playlist with the songs from the *current song*'s album

```ruby
play @search
```
Generate a playlist with the results of the latest *search*.

```ruby
play @tribal
```
Generates a playlist with song whose genres includes 'tribal'

## Player's command interface
To understand the command interface, you need to understand its parameters types and formats.

#### Criterio
A criterio is a key:value pair. In this moment only three keys are valid:
```
* a    Stand for Artist
* b    Stand for Album
* t    Stand for Title
```

Examples of criterio are:

```ruby
a:duffy
```
```ruby
b:"this is"
```
```ruby
t:Jugulator
```

#### Literal
A chain of non-space characters. If you require spaces you can wrap the text in " or ' so this can be considered only one parameter.

Examples of literals are:

```ruby
tunnels
```

```ruby
"The miss and the pit"
```

#### Object
The objects are words with special meaning to the player prefixed with an @. In this moment the fully recognized objects are:
```
* @library         Refers to the complete list of songs in you *connected* collection.
* @search          Refers to the list of songs returned in your last search.
* @playlist        Refers to the current playlist. @current work as well.
* @history         Refers to the playlist of songs you have heard in this session.
* @queue           Refers to the list of songs scheduled to be played next.
* @song            Refers to the current song playing.
* @artist          Refers to the current song's artist playing.
* @album           Refers to the current song's album playing.
* @drives          Refers to all the drives the player knows.
```

Some others are not player's objects but act as special functions placeholders.
```
* @artists         Referes to the complete list of artists in you *connected* collection.
* @albums          Referes to the complete list of albums in you *connected* collection.
* @genres          Referes to the complete list of genres in you *connected* collection.
* @recently_added  Referes to the list of recently added to the collection's songs.
* @recently_played Referes to the list of recently played songs.
* @more_played     Referes to the list of songs with more playbacks.
* @less_played     Referes to the list of songs with less playbacks.
* @populars        Referes to the list of songs with highest puntuations from playback preferences.
```

And anything else is interpreted as follow:
* If there is a @drive with the same name, the @drive is used. The spaces in the @drive name are replaced with _. So, @my_drive search a drive with name 'my drive', no matter the case.
* Try to match a genre, with same name tranformation as above. So, @rock refers to the genre named 'rock', no matter the case.

#### Number
The numbers refers to elements in a displayed list. When a list is displayed, that lists becomes the *focused list* and any given numerical parameter refers to the elements in this list. Depending on the list type, that will be the type of parameter used.A *focused list* is usually the latest list displayed by the player.

Lets say we have the following *focused list*:

```ruby
35 :::: Song: Suburban War \ Artist: Arcade Fire \ Album: The Suburbs ::::
36 :::: Song: Butcher Blues \ Artist: Kasabian \ Album: Kasabian ::::
37 :::: Song: Master Of Puppets \ Artist: Metallica \ Album: 40 Greatest Metal Songs (Vh1) ::::
38 :::: Song: Gavilán O Paloma \ Artist: La Lupita \ Album: Un Tributo A José José ::::
39 :::: Song: La Primavera \ Artist: Manu Chao \ Album: Proxima Estacion: Esperanza ::::
40 :::: Song: Caviar And Meths \ Artist: Judas Priest \ Album: Rocka Rolla ::::
41 :::: Song: Take Me Out \ Artist: Franz Ferdinand \ Album: Take Me Out ::::
42 :::: Song: Si Señor \ Artist: Control Machete \ Album: Artilleria Pesada, Presenta ::::
43 :::: Song: Her We Kum \ Artist: Molotov \ Album: Dance And Dense Denso ::::
```

Because is a songs list, if we do

```ruby
play 39
```
We're saying that we want to play the song 'La Primavera'. But if we have the following *focused list*:

```ruby
149 :::: Artist: Paloma Faith ::::
150 :::: Artist: Duffy ::::
151 :::: Artist: Ke$Ha ::::
152 :::: Artist: Interpol ::::
153 :::: Artist: Jean Knight ::::
154 :::: Artist: Curtis Mayfield ::::
155 :::: Artist: War ::::
```

And the we do

```ruby
play 151
```

We get a playlist with all the songs of 'Ke$ha'. Similar behavior if we have had a albums list.

#### Path
Is an absolute path inside the filesystem. As with literals if the path has any spaces in it, is required to be wrapped inside " or '. In this moment there is no route expansion, so path like ~/music are not valids.

```
/home/usuario/music
```

#### Boolean
Basicly anything that match the next regex is considered a boolean value, so watch out if you try to insert a literal value instead of a boolean.
```
/^(on|off|yes|false|true|si|no|y|n|s|ok)$/
```

Note: When the command parser digest your input it try to guess the type of the tokens the best it can. It will match from specific to general, and boolean are more specificthan literals. If you try to write a literal, but yor literal is one of the recognized boolean types, it will detect it as such. This can cause some commands behave in unexpected ways in the worst case, in others may simpy fail.

So pay attention if something goes weird when you type "search yes".

#### IP
A valid IP4 address.

```ruby
192.168.0.1
```


## Commands
The commands are very rustic. Basicly consist in a command name and a list of parameters.

```ruby
<command> [<param>...]
```

The following command are implemented in this moment.

```
* help           Provides information for player features.
* play           Creates a playlist and start playing. Resumes playback.
* pause          Toggle pause.
* stop           Stops current playback.
* next           Play the next song in current playlist.
* prev           Play the last song in history playlist.
* quit           Quits the playback and exit the player.
* search         Search into the connected music drives.
* show           Shows representations of diverse objects in the player.
* enqueue        Append a playlist to the queue playlist.
* shuffle        Check the state of shuffle. Can turn it on and off.
* connect        Add or reconnect a drive to the music library.
* disconnect     Disconnect a drive from the music library.
* ff             Fast forward 10 seconds the current playback.
* fb             Fast backward 10 seconds the current playback.
* repeat         Repeat the current playback from the begining.
```

Parameters passed to commands that dont require any are simply ignored.

Normally and where makes sense, multiple parameters can mix types. For example, in the 'play' the following is valid and means 'Create a playlist with the results from last search, the artist 'Loly' and any song, artist or album whose name contains 'little'.

```ruby
play @search a:Loly little
```

The following search songs of artist named 'Poor' or 'Rich'

```ruby
search a:Poor a:Rich
```

If in doubt of a command please refer to the help of the command inside the app with the following:
```ruby
help <command_name>
```

## Installation
Due I'm not a genius, I rely in an excelent media player as a multimedia backbone. So, unless you're trying to write yor own adapter for other music player, you need to have Mpg123 installed. With linux, is a piece of cake:

For Ubuntu
```
sudo apt-get install mpg123
```

When you finish install this gem:
```ruby
gem install cultome_player

cultome_player

connect /home/user/music => main

play
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request