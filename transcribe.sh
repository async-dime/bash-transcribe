#!/bin/bash

OPENAI_API_KEY="your_openai_api_key"

# Define the prompt for the OpenAI API call
prompt="I have a video transcript, please rephrase it into concise and brief blog article in nicely formatted markdown file. Video transcript is below:"

# Define a function to clean up the VTT content
clean_vtt_content() {
  local prompt="$1"
  local vtt_content="$2"
  local clean_content=$(echo "$vtt_content" | sed "s/^WEBVTT/$prompt/")
  clean_content=$(echo "$clean_content" | sed -E 's/[0-9]{2}:[0-9]{2}\.[0-9]{3} --> [0-9]{2}:[0-9]{2}\.[0-9]{3}//g')
  local final_content=$(echo "$clean_content" | tr -s '[:space:]' ' ')
  echo "$final_content"
}

# Get the URL from the command line argument
url="$1"

# Check if jq command is available
if ! command -v jq &>/dev/null; then
  echo "jq command not found. Please install it and try again."
  exit 1
fi

# Create the output directory if it doesn't exist
if [ ! -d "output" ]; then
  mkdir output
fi

# Set the output directory to the existing or newly created "output" directory
output_dir="output"

# Run yt_whisper command in background and capture PID
yt_whisper "$url" >/dev/null 2>&1 &
yt_whisper_pid=$!

# Poll for the existence of the .vtt file
echo "Processing .vtt file..."
wait_time=0
while true; do
  vtt_files=$(find . -maxdepth 1 -type f -name "*.vtt" -newermt "-5 seconds")
  if [[ -n "$vtt_files" ]]; then
    break
  fi
  echo -n "."
  sleep 5
  wait_time=$((wait_time + 5))
done

# Kill yt_whisper command
kill "$yt_whisper_pid"

# Clean up the .vtt file and output to .txt file
vtt_file=$(echo "$vtt_files" | sort -r | head -n 1)
if [[ -n "$vtt_file" ]]; then
  echo "Newest modified .vtt file: $vtt_file"
  vtt_content=$(cat "$vtt_file")
  final_content=$(clean_vtt_content "$prompt" "$vtt_content")
  txt_file="$output_dir/$(echo "$vtt_file" | sed 's/\.vtt$/.txt/')"
  echo "$final_content" >"$txt_file"
  echo "Output written to $txt_file"

  # Remove the .vtt file
  rm "$vtt_file"

  # Call OpenAI API with the text in the .txt file
  echo "Calling OpenAI API..."
  messages=$(jq -n --arg content "$final_content" '[{"role": "system", "content": "You are a helpful assistant."}, {"role": "user", "content": $content}]')
  response=$(curl -sS https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d '{
      "model": "gpt-3.5-turbo",
      "messages": '"$messages"',
      "temperature": 0.2,
      "max_tokens": 3500
    }')

  echo "OpenAI API response: $response"

  # Extract the generated text from the response
  generatedText=$(echo "$response" | jq -r '.choices[0].message.content')
  if [[ -n "$generatedText" ]]; then
    echo "Generated text: $generatedText"
    markdownFile="$(echo "$txt_file" | sed 's/\.txt$/.md/')"
    echo "$generatedText" >"$markdownFile"
    echo "Output written to $markdownFile"
  else
    echo "Error generating text"
    exit 1
  fi
else
  echo "No .vtt files found in directory"
  exit 1
fi
