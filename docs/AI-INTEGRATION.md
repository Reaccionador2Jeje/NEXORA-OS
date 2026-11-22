# NEXORA AI

NEXORA AI is a lightweight GTK desktop client included in the NEXORA XFCE profile.

## Supported service format

The client sends a non-streaming chat-completions request with a JSON body containing `model` and `messages`. It accepts the OpenAI-compatible response shape (`choices[0].message.content`) and Ollama's OpenAI-compatible endpoint.

## Local Ollama example

If an Ollama server is already installed and running on the same computer:

- Endpoint: `http://127.0.0.1:11434/v1/chat/completions`
- Model: the exact model name available in that Ollama installation, for example `llama3.2`
- API key: leave blank for a local server that does not require one.

For a hosted compatible provider, enter its documented chat-completions endpoint, model name and key in the Connection dialog.

## Privacy and limits

- No model weights, API key, or paid subscription are bundled.
- API keys are stored in the current user's `~/.config/nexora/ai.json` with owner-only permissions.
- Prompts and responses are sent to the endpoint the user configures.
- The app needs a reachable local or remote inference service to generate answers.
- The initial version keeps chat history in memory only; it does not persist conversations.

NEXORA AI is an integrated desktop client, not a claim that a large language model is already installed locally.
