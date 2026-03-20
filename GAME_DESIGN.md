# Game Design Document — Learn How To Minigolf

## Game Concept

`Learn How To Minigolf` is a minimalistic minigolf game for mobile devices.

The gameplay consists of a basic minigolf game: multiple levels, each one consisting of a minigolf course with a hole in which players need to place the ball by hitting it the least amount of times possible.

This is just an experiment to see how I can, with the help of Claude, build a fully 3D mobile phone video game. There are no special pretenssions further than that. The goal is to make the whole gameplay as simple as pleasant as possible, and be able to ship a ready for production product that can be sold in the APP store markets.

Will my game development skills and Claude support up to the task? Let's see!

## Visual Style

I would like to have a minimalistic visual style, with flat colors, no complex lighting. Just to keep everything minimal, simple and colourful.

My first inspiration comes from a project called `Isoputt`, that enbodies very well this idea. If you see the screenshots attached, you can see that the levels in `Isoputt` are composed of simple squared geometry with walls, ramps, the hole, a simple golf ball, some triangular-shaped corners, and small decoration such as some water surface. There is a single light focus point, and the backgroung is always some gradient combined with a fog effect to give the impression of height:

![Screenshot 2026-03-20 at 15.29.39](/Users/pascu/Desktop/Screenshot 2026-03-20 at 15.29.39.png)

![Screenshot 2026-03-20 at 15.29.29](/Users/pascu/Desktop/Screenshot 2026-03-20 at 15.29.29.png)

![Screenshot 2026-03-20 at 15.29.12](/Users/pascu/Desktop/Screenshot 2026-03-20 at 15.29.12.png)

![Screenshot 2026-03-20 at 15.29.19](/Users/pascu/Desktop/Screenshot 2026-03-20 at 15.29.19.png)

These designs remind me a lot of the look and feel of Monument Valley, where the approach with the colors, shapes, and camera looks kind of the same (despite that, the design is slightly more elaborated):

![monument-valley-at-10-the-story-of-the-most-meticulous-v0-_5Og1AbIv2llyC_fUWvdD7XZ1u5Qml5RBUaOWJhC5VM](/Users/pascu/Desktop/monument-valley-at-10-the-story-of-the-most-meticulous-v0-_5Og1AbIv2llyC_fUWvdD7XZ1u5Qml5RBUaOWJhC5VM.webp)

## Camera

As you can see in the games I take my inspiration from, the camera is always isometric and proportional in all axes. Ideally, the entire level design fits on the screen, so the camera can be fixed at all times.

## Controls

Since this is a mobile game, the idea is that the game uses touch mechanics to be played.

The idea is to use drag and drop gestures to indicate the direction and strength to hit the ball. The player will press the screen and drag the finger around it. We will calculate the position of the finger respect the starting drag coordinates to calculate the direction of the shot, and the distance between the original drag coordinates and the finger to determine the strength of the shot. When the player release the finger from the screen, direction and strength will be computed and applied to the ball.

## Ball Physics

We should try to make realistic ball physics, so the game feels also real and the game mechanics feel intuitive to the player.

## Course / Levels

I want to keep the first iteration as simple as possible. As you can see in the examples avobe, having rams of different heights, walls, squared and triangular corners, a hole, and some special areas like water is more than enough to implement the game levels. We can be more creative in future iterations, but now we should keep it small and simple. Lets focus on creating a good game feel first, and explore more ellaborated courses later, once we hit the right parameters in gameplay and graphics.

## Scoring

Nothing crazy, we will count the amount of hits needed. The lower the better.

## Game Flow

For now I do not want to think in a game flow, I just want a game scene with a course scene, the ball, and some simple UI. Every time the player hits the ball, the ball starts rolling, and the player has to wait for it to be done rolling to perform another shot. When the ball reaches the hole, the game ends. A screen appears and displays the number of hits, and allows playing the same level again.

## UI

At first, I do not want UI at all. We can explore this later on.

## Audio

For now nothing. We could add some simple sound effects for the hit of the ball, when it rolls, hits the walls and so on, but we will keep this simple too.

## Multiplayer

No multiplayer.

## Stretch Goals

- Level selection.
- Worlds.
- Online score-board.

## Out of Scope

<!-- Anything you explicitly do NOT want in this game. -->
