# Simple Bash Youtube Transcription

This is a bash script that transcribes YouTube videos to text using [yt-whisper](https://github.com/m1guelpf/yt-whisper). The script transcribes the video into a `.vtt` file, converts it to a `.txt` file, and then uses the OpenAI API to convert it into a simple blog post-style `.md` file.

## Installation

To use this script, you need to install `yt-whisper`. This particular version has been tested and works:

```
pip install git+https://github.com/m1guelpf/yt-whisper.git@refs/pull/38/head
```

## Creating an Alias

To run the transcription script from your desktop, you need to create an alias in your `.bashrc` file. Replace the file path in the example below with the location where you saved your `transcribe.sh` file:

```
alias transcribe='/home/user/Data/transcribe.sh'
```

## Running the Script

To run the script, simply type `transcribe` in the terminal and paste the YouTube link you want to transcribe, like this:

```
transcribe https://www.youtube.com/watch?v=0000000000
```

You can also customize the prompt for the OpenAI API call by changing the `prompt` variable in the script. Additionally, you can modify the OpenAI API parameters such as the model, temperature, and max_tokens by changing the corresponding variables in the script.