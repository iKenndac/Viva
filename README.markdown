## A Legal Note ##

Viva is not an official Spotify project. I work at Spotify, and the company has very graciously allowed me to use their graphics and logos. However, these are NOT covered under the BSD license that the code is under, and are NOT included in this repository - a build script will download them separately. Distribution of the graphics contained in Viva is strictly prohibited.

## What Viva Is ##

Viva is a Spotify client for Mac OS X Lion. Both building and running require Mac OS X 10.7. Viva is built entirely on Spotify's libspotify C library.

This client's purpose in life is to be a showcase of the Spotify platform as well as a playground for experimenting with ideas and new APIs. It's very rough around the edges, and even whole views (such as the Local Files view) are blank.

## What Viva Is NOT ##

Viva is NOT intended to be a replacement Spotify desktop client. It's missing many features (such as playlist management) which make it generally unsuitable for sole use. While this will be improved over time, it's not a priority. Issues filed against Viva along the lines of "It doesn't do [feature in desktop client]" will likely be closed.

The target audience of Viva is developers - please keep that in mind. In addition, Viva **requires** a Spotify Premium account - this requirement will never change. If you wish to build Viva from source, you also need a libspotify developer key, which can be requested from here: http://developer.spotify.com/en/libspotify/overview/

## Building ##

1. Clone Viva.
2. Run `git submodule update --init` in the Viva directory. If I get tickets about it not building and you haven't run this, you lose 5 internet points.
3. Supply an appkey.c file (see above).
4. Build away!

## Interesting Areas ##

Viva has been made in my hackday and spare time, which has resulting in the code being rather... scattered. However, there are some nice examples of various Mac OS X technologies in there. A few of my favourites:

Core Data over multiple threads: `LocalFileSource.m`.

Core Audio Graphs, including a Graphic EQ: `VivaPlaybackManager.m`, in the "Core Audio" section.

Using AVFoundation to get media file metadata: `LocalFileSource.m`, `-parseMediaFileAtPath:intoContext:`.

Using AVFoundation to convert audio files to PCM data for manual playback through Core Audio: `VivaLocalFileDecoderWorker.m`.

Using FSEvents to watch a directory tree for changes: `LocalFileSource.m`.

