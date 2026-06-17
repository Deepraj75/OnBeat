# OnBeat

An application which checks the user's rhythm and tells them how close to the beat they were.

## Pictures

![OnBeat icon](assets/logo.png)

![Home page](assets/Home%20page.jpg)

![Rhythm Analysis](assets/Rhythm%20analysis.jpg)

## Why I Built It

I am a guitarist and one of the things that I was struggling with, while I was thinking about what idea should become my first app, was rhythm. Staying in rhythm is fundamental for any musician. It is essential for a musician to catch every beat with precision. However, right now, to check how "on beat" they are, musicians have to rely on their own sense of timing, which is imperfect for beginners, or seek the help of a professional. This is why I made OnBeat - an app which checks how close to the beat the user is.

## How It Works

The user starts out by setting a BPM, after which the app plays a four-beat metronome along which a user has to clap or play their instrument. I will refer to these events as "claps" for simplicity. The app records this and analyses the recording to detect the claps.

Sound is stored as a series of amplitudes, so to detect the claps, the app checks for amplitudes above a particular threshold. The right value for the threshold is chosen after multiple experiments to ensure that only the claps, and each clap, are detected. Once such an amplitude is found, the local maxima is found in a 100 ms window. This is done to make sure that the detected clap belongs to the clap. After a clap is detected, we skip half a beat to avoid processing amplitudes which will not be claps. All the while, we skip a small window around the metronome clicks to avoid detecting them as claps. As to the concern that it might not detect the claps if the user is too close, the skip time is chosen to be so small that a human can't realistically be that close to the beat. This value is chosen after trying out multiple values.

Once the claps are detected, the timings of the claps are noted and compared with the timings of the clicks. The comparison is as such: clap 1 with click 1, clap 2 with click 2, and so on. Based on the difference between the timings of the claps and their corresponding clicks, a score is calculated, based on which a grade is assigned to the user and displayed.

Since the clap detection algorithm isn't perfect, in case extra claps are detected due to some disturbance, only the first 4 claps are considered.

## Features

- Adjustable BPM (30-240)
- Four-beat metronome
- Graph showing the sound wave produced
- Grade assigned based on how "on beat" the user was

## Tools Used

- Dart as the programming language
- Flutter as the UI framework
- VS Code for writing code
- Android Studio for Android building tools
- GIMP for creating the icon

## Challenges

- Problem: I initially used the audioplayers package to play the metronome clicks, because of which I wasn't able to record audio and play the metronome at the same time.
  - Fix: I used the soloud package, which treats the metronome clicks as short sound effects, allowing them to be played while the app is recording audio.

- Problem: The biggest challenge for me was making the clap detection algorithm accurate.
  - Fix: I tried out many different thresholds and skip times until the clap detection was mostly accurate.

## Scope for Improvement

- The clap detection is still not perfect. It sometimes misses actual claps or adds extra ones.
- The current duration of the metronome (4 beats) is too small.
- The app doesn't support different time signatures.
- The metronome clicks are not accented. Accent basically means making the first beat of a bar louder than the other beats.
- The graph can show which points were detected as claps once the clap detection is perfected.
- The app doesn't keep a history of the user's previous analyses.
- The app doesn't tell the user whether they are rushing (ahead of the beat) or dragging (behind the beat).
- Dosen't work on iOS
