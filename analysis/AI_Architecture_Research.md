## AI Integration Architecture Research for Fitflow

This document outlines the research and recommendations for the AI integration architecture of the Fitflow application, focusing on real-time response streaming, structured data output, Markdown rendering, and memory management.

### 1. Real-time AI Response Streaming

**Problem:** The current implementation simulates streaming, leading to a suboptimal user experience. True real-time streaming is necessary to display AI responses as they are generated.

**Research Findings:**

*   **Server-Sent Events (SSE):** SSE is a simple and effective technology for pushing real-time updates from a server to a client. It is well-suited for streaming AI responses. Libraries like `EventSource` for Swift provide easy-to-use clients for SSE.
*   **WebSockets:** WebSockets offer a more powerful, bidirectional communication channel. While more complex to set up than SSE, they are a viable option for real-time communication.
*   **Swift Concurrency:** Modern Swift concurrency features (`async/await`, `AsyncStream`) are well-suited for handling real-time data streams from either SSE or WebSockets.

**Recommendation:**

Implement **Server-Sent Events (SSE)** for streaming AI responses. This approach provides the necessary real-time capabilities with less complexity than WebSockets. The backend (Supabase Edge Functions) will need to be configured to send SSE streams, and the iOS app will use a library like `EventSource` or a custom implementation with `URLSession` and `AsyncStream` to consume these streams.

### 2. Structured AI Output and Markdown Rendering

**Problem:** The user wants AI-generated content to be displayed in a visually appealing and structured manner, using Markdown.

**Research Findings:**

*   **Structured Output from AI:** Both Gemini and OpenAI APIs support structured output, allowing you to specify a JSON schema for the response. This is the recommended approach for getting structured data from the AI.
*   **Markdown in SwiftUI:**
    *   **Native Support:** Newer versions of SwiftUI have built-in support for rendering Markdown within `Text` views.
    *   **Third-party Libraries:** For more advanced styling and features, libraries like `MarkdownUI` are highly recommended. `MarkdownUI` is compatible with GitHub Flavored Markdown and offers extensive customization options.

**Recommendation:**

1.  **Utilize Structured JSON Output:** Modify the backend AI calls to request structured JSON output from the AI models. This will ensure that the data for workout plans, meal plans, etc., is returned in a predictable and parsable format.
2.  **Embed Markdown in JSON:** Within the structured JSON, use Markdown for descriptive text fields (e.g., exercise instructions, meal descriptions).
3.  **Implement `MarkdownUI`:** Integrate the `MarkdownUI` library into the SwiftUI frontend to render the Markdown content. This will provide the flexibility to create the rich, visually appealing displays the user desires.

### 3. AI Memory Management with Vector Databases

**Problem:** The app needs a robust memory system to provide personalized and contextual AI interactions.

**Research Findings:**

*   **Vector Databases for AI Memory:** Vector databases are the standard for implementing long-term memory in AI applications. They store text and other data as vector embeddings, allowing for fast similarity searches.
*   **Supabase and `pgvector`:** Supabase has built-in support for the `pgvector` PostgreSQL extension, which provides vector similarity search capabilities. This makes Supabase an excellent choice for implementing a vector database for AI memory.
*   **Conversational AI:** Vector databases are particularly effective for conversational AI, as they can store and retrieve past conversations to maintain context.

**Recommendation:**

1.  **Leverage Supabase `pgvector`:** Use the `pgvector` extension in the Supabase database to create a vector store for AI memory.
2.  **Store Conversational History:** Store user-AI conversations as vector embeddings in the `pgvector` store. This will allow the AI to recall past interactions and provide more contextual responses.
3.  **Store User Preferences and Data:** In addition to conversations, store user preferences, goals, and other relevant data as vector embeddings to further personalize the AI's responses.
4.  **Implement a Memory Service:** The existing `MemoryService` in the app should be expanded to interact with the `pgvector` database, handling the embedding and retrieval of data.

### Summary of Recommended AI Architecture

*   **Frontend (iOS):** SwiftUI with `MarkdownUI` for rendering, and a custom SSE client using `URLSession` and `AsyncStream` for real-time streaming.
*   **Backend (Supabase):**
    *   **Edge Functions:** To handle AI API calls, requesting structured JSON output with embedded Markdown.
    *   **PostgreSQL Database:** With the `pgvector` extension enabled to serve as a vector database for AI memory.
*   **AI Models (Grok/OpenAI):** Configured to provide structured JSON responses.

This architecture will provide a robust, scalable, and user-friendly AI experience, addressing the key requirements of real-time interaction, rich content display, and personalization.

