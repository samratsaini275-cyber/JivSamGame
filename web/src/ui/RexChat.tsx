// IG-style DMs with Rex Calloway — thread list + chat bubbles + reply chips.
import { useEffect, useRef, useState } from "react";
import { useGame } from "./hooks";
import {
  unlockedThreads, threadMessages, pendingPitch, repliesFor, RexDMThread,
} from "../engine/rexChat";
import { rexItemByID, REX_TIER_NAMES } from "../engine/data";
import { money } from "./format";
import { sfx } from "./sfx";

export function RexScreen({ onGoEmpire }: { onGoEmpire: () => void }) {
  const game = useGame();
  const [threadID, setThreadID] = useState<string | null>(null);

  if (!game.rexUnlocked) return <DMsLocked onGoEmpire={onGoEmpire} />;

  const threads = unlockedThreads(game);
  const active = threads.find((t) => t.id === threadID) ?? null;

  return active
    ? <ChatView thread={active} onBack={() => setThreadID(null)} />
    : <ThreadList threads={threads} onOpen={setThreadID} />;
}

function DMsLocked({ onGoEmpire }: { onGoEmpire: () => void }) {
  return (
    <div className="screen dms-locked">
      <div className="ghost-thread">
        <RexAvatar />
        <div className="thread-info">
          <div className="thread-title">Rex Calloway</div>
          <div className="thread-preview blurred">Yo. Been watching the brand…</div>
        </div>
        <span className="ghost-lock">🔒</span>
      </div>
      <div className="lock-title">Someone wants to slide in</div>
      <div className="lock-sub">
        A certain lifestyle consultant only DMs founders who move product.
        Unlock <b>Sneaker Resells</b> to get on his radar.
      </div>
      <button className="btn-cta lock-cta" onClick={onGoEmpire}>
        SHOW ME THE HUSTLE
      </button>
    </div>
  );
}

function ThreadList({ threads, onOpen }: { threads: RexDMThread[]; onOpen: (id: string) => void }) {
  const game = useGame();
  return (
    <div className="screen dms">
      <div className="dms-header">
        <div className="section-title">DMs</div>
        <div className="section-sub">Rex Calloway · lifestyle consultant</div>
      </div>
      <div className="thread-list">
        {threads.map((t) => {
          const unread = pendingPitch(threadMessages(t, game), game) !== null;
          return (
            <button key={t.id} className="thread-row" onClick={() => onOpen(t.id)}>
              <RexAvatar />
              <div className="thread-info">
                <div className="thread-title">{t.title}</div>
                <div className="thread-preview">{t.preview}</div>
              </div>
              {unread && <span className="unread-dot" />}
            </button>
          );
        })}
      </div>
      <div className="dms-footnote">
        Rex slides in with new pitches as the bag grows. His gear boosts the whole empire.
      </div>
    </div>
  );
}

function RexAvatar({ size = 46 }: { size?: number }) {
  return (
    <span className="rex-avatar" style={{ width: size, height: size, fontSize: size * 0.42 }}>
      🕶️
    </span>
  );
}

function ChatView({ thread, onBack }: { thread: RexDMThread; onBack: () => void }) {
  const game = useGame();
  const messages = threadMessages(thread, game);
  const pitch = pendingPitch(messages, game);
  const replies = pitch ? repliesFor(pitch, game) : [];
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    game.markRexMet();
  }, []);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight });
  }, [messages.length, replies.length]);

  return (
    <div className="screen chat">
      <div className="chat-header">
        <button className="back-btn" onClick={onBack} aria-label="Back">‹</button>
        <RexAvatar size={38} />
        <div className="chat-header-info">
          <div className="chat-name">{thread.title}</div>
          <div className="chat-status">online · probably at a valet stand</div>
        </div>
      </div>

      <div className="chat-scroll" ref={scrollRef}>
        {messages.map((m) => {
          const item = rexItemByID(m.itemID);
          const isPitchCard = m.sender === "rex" && m.pitchID && item;
          return (
            <div key={m.id} className={`bubble-row ${m.sender}`}>
              {isPitchCard ? (
                <div className="bubble rex pitch-card">
                  <div className="pitch-head">
                    <span className="pitch-emoji">{item.emoji}</span>
                    <div>
                      <div className="pitch-name">{item.name}</div>
                      <div className={`pitch-tier t${item.tier}`}>
                        {REX_TIER_NAMES[item.tier]} · {money(item.cost)}
                      </div>
                    </div>
                  </div>
                  <div className="pitch-blurb">{item.blurb}</div>
                  <div className="pitch-boost">✨ {item.boostText}</div>
                </div>
              ) : (
                <div className={`bubble ${m.sender}`}>{m.text}</div>
              )}
            </div>
          );
        })}
        {pitch && replies.length > 0 && (
          <div className="typing-hint">Rex is waiting on you…</div>
        )}
      </div>

      <div className="reply-bar">
        {pitch && replies.length > 0 ? (
          replies.map((r, i) => {
            const primary =
              r.action.type === "buy" || r.action.type === "equip" ||
              (r.action.type === "introAck" && i === 0);
            return (
              <button
                key={r.id}
                className={`reply-chip ${r.disabled ? "disabled" : ""} ${primary ? "primary" : ""}`}
                disabled={r.disabled}
                onClick={() => { game.handleRexReply(r.action, pitch); sfx.message(); }}
              >
                {r.label}
              </button>
            );
          })
        ) : (
          <div className="reply-idle">Keep stacking — Rex will slide back in.</div>
        )}
      </div>
    </div>
  );
}
