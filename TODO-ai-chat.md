# TODO: In-App AI Chat (BYOK — Bring Your Own Key)

Add an AI chat tab where users can ask questions about their puppy's data using their own LLM API key. No server needed, no AI costs for us.

## Concept

The app has all the puppy data locally. An AI chat lets users ask natural questions:
- "Wanneer moet ze weer plassen?"
- "Hoe lang slaapt ze gemiddeld overdag?"
- "Gaat het beter met de zindelijkheid?"
- "Vergelijk deze week met vorige week"

The LLM gets the puppy's data as context and answers based on actual patterns.

## Architecture

```
┌──────────────────────────────────────┐
│  Chat UI (SwiftUI)                    │
│  ┌──────────────────────────────────┐ │
│  │ 💬 "Hoe lang was ze wakker?"     │ │
│  │ 🤖 "Gemiddeld 47 min vandaag,   │ │
│  │     langste was 1u12 na lunch."  │ │
│  └──────────────────────────────────┘ │
│           ↓ user message               │
│  ┌──────────────────────────────────┐ │
│  │ Context Builder                   │ │
│  │ - Today's events (JSONL)         │ │
│  │ - Calculated stats               │ │
│  │ - Puppy profile                  │ │
│  │ → System prompt + user message   │ │
│  └──────────┬───────────────────────┘ │
│              ↓                         │
│  ┌──────────────────────────────────┐ │
│  │ LLM Provider (user's API key)    │ │
│  │ OpenAI / Anthropic / Ollama      │ │
│  └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

## Step 1: API Key Settings

Create `Views/Settings/AISettingsView.swift`:

```swift
struct AISettings: Codable {
    var provider: AIProvider
    var apiKey: String
    var model: String  // e.g. "gpt-4o-mini", "claude-sonnet-4-20250514"
    
    enum AIProvider: String, Codable, CaseIterable {
        case openai = "OpenAI"
        case anthropic = "Anthropic"
        case ollama = "Ollama (lokaal)"
    }
}
```

- Store API key in iOS Keychain (NOT UserDefaults — it's a secret)
- Provider picker: OpenAI, Anthropic, Ollama
- Model selector per provider (hardcoded sensible defaults)
- "Test verbinding" button
- For Ollama: custom base URL field (default: `http://localhost:11434`)

## Step 2: Context Builder

Create `Services/AIContextBuilder.swift`:

The context builder prepares the system prompt with relevant puppy data. Key principle: **send only what's needed**, not the entire history. Token budget matters.

```swift
class AIContextBuilder {
    /// Build system prompt with relevant context for a user question
    func buildContext(question: String, profile: PuppyProfile) -> String {
        var context = """
        Je bent een slimme puppy-assistent. Je helpt de eigenaar van \(profile.name), 
        een \(profile.breed ?? "puppy") geboren op \(profile.birthDate.formatted()).
        
        Antwoord in het Nederlands. Wees concreet en gebruik de data.
        Als je iets niet weet uit de data, zeg dat eerlijk.
        
        """
        
        // Always include: today's events
        context += "## Vandaag\n" + todayEventsAsText()
        
        // Always include: key stats
        context += "\n## Statistieken\n" + currentStatsAsText()
        
        // Conditionally include based on question topic:
        // - Sleep question → include sleep breakdown
        // - Potty question → include gap analysis + predictions
        // - Trend question → include weekly comparison
        
        return context
    }
}
```

**Smart context selection** (keeps token usage low):
- Always: today's events + puppy age + key stats (potty %, streak)
- If question mentions sleep/dutje/nacht: add sleep analysis
- If question mentions plas/poep/zindelijk: add gap stats + predictions
- If question mentions week/trend/vergelijk: add weekly breakdown
- Fallback: include everything if question is vague

## Step 3: LLM Service

Create `Services/LLMService.swift`:

```swift
protocol LLMProvider {
    func chat(messages: [ChatMessage], model: String, apiKey: String) async throws -> String
}

class OpenAIProvider: LLMProvider { /* POST /v1/chat/completions */ }
class AnthropicProvider: LLMProvider { /* POST /v1/messages */ }
class OllamaProvider: LLMProvider { /* POST /api/chat */ }
```

- Streaming support (show response as it arrives)
- Error handling: invalid key, rate limit, network error
- Token counting (optional, for cost awareness)
- Timeout handling

## Step 4: Chat UI

Create `Views/Chat/ChatView.swift`:

- Tab bar item: 💬 Chat
- Message list (LazyVStack, scroll to bottom)
- Text input with send button
- Typing indicator while waiting for response
- Messages persist in local storage (per conversation, max ~50 messages)
- "Nieuw gesprek" button to clear context
- First-time: prompt to set up API key in settings

Design: keep it simple, native iOS feel. No custom bubbles — use alternating background colors like iMessage.

## Step 5: Suggested Questions

Show suggestion chips when chat is empty:

```
┌─────────────────────────────────┐
│  Stel een vraag over [puppy]... │
│                                  │
│  💡 Suggesties:                  │
│  ┌───────────────────────────┐  │
│  │ Wanneer moet ze plassen?  │  │
│  │ Hoe ging het vandaag?     │  │
│  │ Slaapt ze genoeg?         │  │
│  │ Tips voor zindelijkheid   │  │
│  └───────────────────────────┘  │
└─────────────────────────────────┘
```

## Step 6: Tool Use (optional, advanced)

Instead of pre-building context, let the LLM request specific data via tool/function calls:

```json
{
    "name": "get_events",
    "parameters": { "date": "2026-02-19", "type": "plassen" }
}
{
    "name": "get_stats",
    "parameters": { "metric": "potty_gaps", "days": 7 }
}
{
    "name": "get_predictions",
    "parameters": {}
}
```

This is more flexible and token-efficient but requires OpenAI/Anthropic function calling support. Ollama support varies. Consider this a v2 of the chat feature.

## Privacy & Cost Considerations

- **API key stays on device** (Keychain) — never sent to our servers
- **Data stays on device** — sent directly to user's chosen LLM provider
- **Cost is user's responsibility** — show estimated token usage per message
- **Ollama option** — fully offline, zero cost, full privacy
- **No account needed** — the AI feature works with just an API key

## Recommended Default Models

| Provider | Model | Why |
|----------|-------|-----|
| OpenAI | gpt-4o-mini | Cheap, fast, good enough for data Q&A |
| Anthropic | claude-sonnet-4-20250514 | Best reasoning, great with structured data |
| Ollama | llama3.2 | Free, local, decent quality |

## Done Criteria
- [ ] Can configure API key for OpenAI, Anthropic, or Ollama
- [ ] Chat tab with message history
- [ ] AI responses use actual puppy data as context
- [ ] Streaming responses (text appears as it generates)
- [ ] Suggested questions on empty chat
- [ ] API key stored securely in Keychain
- [ ] Works offline with Ollama
- [ ] Clear error messages for auth/network issues

Delete this file when done.
