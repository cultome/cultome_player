# CulToMe Player
A handy music library explorer. Is designed to facilitate you to play the music you like in the moment you want.

**"I want to play exactly this music"**

The player is designed around this concept, so it has commands to help you find music in your library and play it.

### Usage examples

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

### Player's command interface
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
```
The objects are words with special meaning to the player prefixed with an @. In this moment the fully recognized objects are:
* @library         Refers to the complete list of songs in you *connected* collection.
* @search          Refers to the list of songs returned in your last search.
* @playlist        Refers to the current playlist.
* @history         Refers to the playlist of songs you have heard in this session.
* @queue           Refers to the list of songs scheduled to be played next.
* @song            Refers to the current song playing.
* @artist          Refers to the current song's artist playing.
* @album           Refers to the current song's album playing.
* @drives          Refers to all the drives the player knows.
```

```
Some others are not player's objects but act as special functions placeholders.
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
1.  If there is a @drive with the same name, the @drive is used. The spaces in the @drive name are replaced with _. So, @my_drive search a drive with name 'my drive', no matter the case.
2.  Try to match a genre, with same name tranformation as above. So, @rock refers to the genre named 'rock', no matter the case.

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

```ruby
/home/usuario/music
```

#### IP
A valid IP4 address.

```ruby
192.168.0.1
```


### Commands
The commands are very rustic. Basicly consist in a command name and a list of parameters.

```ruby
<command> [<param>...]
```

The following command are implemented in this moment.

```
* play (<number>|<criteria>|<object>|<literal>)*     Create and inmediatly plays playlists
* enqueue (<number>|<criteria>|<object>|<literal>)*  Append the created playlist to the current playlist
* search (<criteria>|<object>|<literal>)*            Find inside library for song with the given criteria.
* show <object>                                      Display information about status, objects and library.
* pause                                              Pause playback.
* stop                                               Stops playback.
* next                                               Play the next song in the queue.
* prev                                               Play the previous song from the history.
* connect <path> => <literal>                        Add files to the library.
* disconnect <literal>                               Remove filesfrom the library.
* quit                                               Exit the player.
* ff                                                 Fast forward 5 sec.
* fb                                                 Fast backward 5 sec.
* shuffle <number>|<literal>                         Check and change the status of shuffle.
* repeat                                             Repeat the current song.
* kill                                               Delete from disk the current song.
* copy <object> => <path>                            Copy a player's object's songs to a directory
* help <literal>                                     Show this help.
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

### Installation
First of all you need JRuby installed in your system. There are many tutorial in internet to do this.

To distinguish from pure ruby, I'm gonna assume that all the JRuby executable are prepended with a j.

```ruby
jgem install cultome_player

cultome_player

connect /home/user/music => main

play
```

### What's new
**Version 0.2.0**

* The code were reorganized to be more API-oriented, even when this was not the mainly intention of this project, but can be uselful for others to use it this way.
* The some commands were extracted from the core, like help and kill.
* The command 'copy <object> <destiny_path>' were added to copy all the songs in the objet to a directory in the filesystem.
* The option 'search @\<artist|album\>' was implemented to facilitate the __'that album rocks! lets hear it!'__.
* The player now emit exception-thrown events, a general exception and a player's exception.
* The aliases/shortcuts/macros plugin is in place. With this you can translate user input into commands, for example type 'sa' and the players tranform it to 'search @artist'.
* Changes in plugin structure. Not the final version but a step ahead for building a better plugin model.
* Some minor bugs fixes, like the db hanging or the lost in focus when search is empty.

**Version 0.3.0**

* Colors!!! Yeah! a color schema that you can customize if you dont like mine.
* Some ASCII progress bars to let you know the player is not stuck!
* Improvement in the 'help <command>' command, to, hopefully help you you surf in the player.
* Add but not yet fully tested the *share* command to share music between two machines.
* Some minor bugs fixed.
* Specs up to date! YEAH!

### Ideas for the next release

* Add tags to the songs, for example 'party' or 'sadness'.
* Last.fm scrobbler, altough normally when I hear music the wifi is never available =S

### TODO
* Complete and update specs
* Refine the taste analizer, which is the component that give preference points to songs.
* Leave JRuby and convert to pure Ruby
* Improve the memory usage, it simply too high!
* Change the underlying in.memory database for a real one, thinking on mongo
* Updates to preserve db information

### Additional Information

#### jlGui BasicPlayer
This component is what I use to play music and is included within the libraries of this project, dependencies included of course.

[jlGui](http://www.javazoom.net/jlgui/developerguide.html)

