## A Legal Note ##

Viva is not an official Spotify project. I work at Spotify, and the company has very graciously allowed me to use their graphics and logos. However, these are NOT covered under the BSD license that the code is under, and are NOT included in this repository - a build script will download them separately. Distribution of the graphics contained in Viva is strictly prohibited.

## What Viva Is ##

Viva is a Spotify client for Mac OS X Lion. Both building and running require Mac OS X 10.7. Viva is built entirely on Spotify's libspotify C library.

This client's purpose in life is to be a showcase of the Spotify platform as well as a playground for experimenting with ideas and new APIs. It's very rough around the edges, and even whole views are blank.

Some features:

- Nice playback experience (gapless playback, EQ).
- Support for playing "local files" (MP3, M4A, Apple Lossless, FLAC).
- Last.fm scrobbling.

## What Viva Is NOT ##

Viva is NOT intended to be a replacement Spotify desktop client. It's missing many features (such as playlist management) which make it generally unsuitable for sole use. While this will be improved over time, it's not a priority. Issues filed against Viva along the lines of "It doesn't do [feature in desktop client]" will likely be closed.

The target audience of Viva is developers - please keep that in mind. In addition, Viva **requires** a Spotify Premium account - this requirement will never change. If you wish to build Viva from source, you also need a libspotify developer key, which can be requested from here: http://developer.spotify.com/en/libspotify/overview/

## Downloading ##

If you'd like to download Viva without building, you'll find periodic snapshot builds in the Downloads section of the repository's home on GitHub. You don't need an appkey to use these, but you still need a Spotify Premium account.

## Building ##

1. Clone Viva using `git clone --recursive git://github.com/iKenndac/Viva.git` to make sure you get all the submodules too.
2. If you got excited and cloned the repo before reading this, run `git submodule update --init` in the Viva directory to grab the submodules. If I get tickets about it not building and you haven't got the submodules checked out, you lose 5 internet points!
3. Supply an appkey.c file (see above).
4. Build away!

## Interesting Areas ##

Viva has been made in my hackday and spare time, which has resulting in the code being rather... scattered. However, there are some nice examples of various Mac OS X technologies in there. A few of my favourites:

Core Data over multiple threads: `LocalFileSource.m`.

Core Audio Graphs, including a Graphic EQ: `SPCoreAudioController.m`.

Using AVFoundation to get media file metadata: `LocalFileSource.m`, `-parseMediaFileAtPath:intoContext:`.

Using AVFoundation to convert audio files to PCM data for manual playback through Core Audio: `VivaAVAssetDecoderWorker.m`.

Using FSEvents to watch a directory tree for changes: `LocalFileSource.m`.

Using libFLAC to get FLAC metadata: `LocalFileSource+LocalFileSourceFLACAdditions.m`.

Using libFLAC to decode FLAC files for playback: `VivaFLACDecoderWorker.m`.

