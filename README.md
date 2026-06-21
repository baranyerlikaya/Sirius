# Sirius

Sirius is a highly optimized, client-sided death and freecam system for Roblox. It replaces the default death sequence with a seamless out-of-body experience, allowing players to navigate the map as a free-flying entity until they choose to respawn.

## Performance & Architecture

The system is designed with zero server replication overhead. When a player dies, the server acts strictly as a signal dispatcher via a single RemoteEvent. The entire soul rendering, camera tracking, and movement logic is processed locally on the client. This means even with a high volume of simultaneous deaths, server performance remains completely unaffected.

## Cinematic Camera

Sirius features a smooth camera transition bound to RenderStepped. Upon death, the camera dynamically pulls back and expands its Field of View using an easing curve. This provides a polished, wide-angle cinematic effect without any physics stuttering.

## Installation

Download the project files from this repository and copy the contents of the `src` folder directly into your own Roblox place. Make sure to place the Client and Server scripts in their respective StarterPlayerScripts and ServerScriptService locations as structured in the repository.

## Roadmap

Future updates will introduce a configuration API for adjusting flight speeds and FOV targets, as well as optional server replication modes for visibility toggles.


For questions you can contact with me discord @baranyerlikaya
