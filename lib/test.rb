require 'persistence'

# Album.create(id: 0, name: "unknown")
# Artist.create(id: 0, name: "unknown")
Drive.create(name: "rolateca", path: "C:\\ws\\cultome_player")

s=Song.create(name: "If a Had A Gun", artist_id: 1, album_id: 1, year: 2011, track: 1, duration: 123, drive_id: 1, relative_path: "01.mp3")
Album.create(name: "High Flying Birds")
Artist.create(name: "Noel Gallagher")
britpop = Genre.create(name: "Britpop")
s.genres << britpop

s2=Song.create(name: "The Death of You And Me", artist_id: 1, album_id: 1, year: 2011, track: 1, duration: 90, drive_id: 1, relative_path: "01.mp3")
rock = Genre.create(name: "Rock")
s2.genres << rock
s2.genres << britpop

s3=Song.create(name: "Paranoid", artist_id: 2, album_id: 2, year: 1978, track: 9, duration: 100, drive_id: 1, relative_path: "01.mp3")
Album.create(name: "Paranoid")
Artist.create(name: "Black Sabbath")
s3.genres << Genre.create(name: "Metal")
s3.genres << rock

s4=Song.create(name: "Stand By Me", artist_id: 3, album_id: 3, year: 2003, track: 4, duration: 180, drive_id: 1, relative_path: "01.mp3")
Album.create(name: "Now Or Never")
Artist.create(name: "Oasis")
s4.genres << britpop

s5=Song.create(name: "Destination Calabria", artist_id: 0, album_id: 0, year: 0, track: 0, duration: 145, drive_id: 1, relative_path: "01.mp3")
s5.genres << Genre.create(name: "Electronic")