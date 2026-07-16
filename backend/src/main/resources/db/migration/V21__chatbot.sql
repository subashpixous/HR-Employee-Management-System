-- ============================================================
-- V21 — AI Chatbot: server-side API keys + knowledge base
--
-- All third-party AI keys live here (server-side) so they are
-- NEVER shipped to the browser. Only admins (USER_MANAGE) can
-- read/update them through /api/chatbot/admin/settings.
--
-- NOTE: the keys seeded below are the ones provided during setup.
-- Rotate them from the Admin > AI Assistant screen for production.
-- ============================================================

-- Chatbot configuration + provider API keys (stored as system settings).
-- INSERT IGNORE keeps any value an admin has already customised.
INSERT IGNORE INTO system_settings (setting_key, setting_value, description) VALUES
 ('CHATBOT_ENABLED',      'true',                              'Master on/off switch for the AI assistant'),
 ('CHATBOT_LLM_PROVIDER', 'groq',                              'Primary LLM provider: groq | gemini'),
 ('GROQ_API_KEY',         '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', 'Groq API key (chat + Whisper speech-to-text)'),
 ('GROQ_MODEL',           'llama-3.3-70b-versatile',           'Groq chat completion model'),
 ('GROQ_STT_MODEL',       'whisper-large-v3',                  'Groq Whisper speech-to-text model'),
 ('GEMINI_API_KEY',       'AQ.Ab8RN6Ivb4XHKSIRFZUJsOPUkDKj76xzqgSmCuOHVbM6ODz30Q', 'Google Gemini API key (LLM fallback + translation)'),
 ('GEMINI_MODEL',         'gemini-1.5-flash',                  'Gemini model name'),
 ('ELEVENLABS_API_KEY',   'sk_70b7302fead1e267bcd5bfe18935df2c5cdfabe46ff50eab', 'ElevenLabs API key (natural text-to-speech)'),
 ('ELEVENLABS_VOICE_ID',  'EXAVITQu4vr4xnSDxMaL',              'ElevenLabs voice id (premade, free-tier friendly, multilingual)'),
 ('ELEVENLABS_MODEL',     'eleven_multilingual_v2',            'ElevenLabs TTS model (supports Tamil/Hindi/English)'),
 ('FIRECRAWL_API_KEY',    'fc-ff82fc33277440e1b56b8fa3495ca2cd', 'Firecrawl API key (website knowledge ingestion)'),
 ('CHATBOT_WEBSITE_URL',  'https://pixoustech.com',            'Company website crawled to train the assistant');

-- Knowledge base: static + Firecrawl-ingested documents the assistant
-- grounds its answers on. MEDIUMTEXT so a full page of scraped markdown fits.
CREATE TABLE IF NOT EXISTS chatbot_knowledge (
    id          BIGINT AUTO_INCREMENT PRIMARY KEY,
    source      VARCHAR(255) NOT NULL,                 -- 'seed' | 'firecrawl' | 'manual'
    title       VARCHAR(255),
    content     TEXT         NOT NULL,
    enabled     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_chatbot_knowledge_enabled (enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
