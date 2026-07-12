// Crisp SVG playing cards — drawn suits (no glyphs/emoji), aged-ivory faces,
// and an art-deco face-down back. Purely presentational.
import { Card, Suit } from "../engine/blackjack";

const SUIT_PATH: Record<Suit, string> = {
  hearts: "M12 21c-.4-.35-8.5-6.6-8.5-12.3A4.5 4.5 0 0 1 12 6a4.5 4.5 0 0 1 8.5 2.7C20.5 14.4 12.4 20.65 12 21Z",
  diamonds: "M12 2 21 12 12 22 3 12Z",
  spades: "M12 2s9 7.2 9 12.4A3.9 3.9 0 0 1 13.3 16c.15 2.2 1 3.3 2.7 4H8c1.7-.7 2.55-1.8 2.7-4A3.9 3.9 0 0 1 3 14.4C3 9.2 12 2 12 2Z",
  clubs: "M12 3.2a3.3 3.3 0 0 1 2.7 5.2 3.3 3.3 0 1 1 .3 6.3A3.3 3.3 0 0 1 12 14.6a3.3 3.3 0 0 1-3 .1 3.3 3.3 0 1 1 .3-6.3A3.3 3.3 0 0 1 12 3.2ZM10.8 13.5 9.8 20h4.4l-1-6.5Z",
};

function isRed(suit: Suit): boolean {
  return suit === "hearts" || suit === "diamonds";
}

function Pip({ suit, size = 24, className }: { suit: Suit; size?: number; className?: string }) {
  return (
    <svg viewBox="0 0 24 24" width={size} height={size} className={className} aria-hidden>
      <path d={SUIT_PATH[suit]} fill="currentColor" />
    </svg>
  );
}

interface Props {
  card?: Card;
  faceDown?: boolean;
  /** Stagger index for the deal animation. */
  index?: number;
}

export function PlayingCard({ card, faceDown, index = 0 }: Props) {
  const style = { animationDelay: `${index * 90}ms` } as React.CSSProperties;

  if (faceDown || !card) {
    return (
      <div className="pcard pcard-back" style={style} aria-label="face-down card">
        <svg viewBox="0 0 60 84" className="pcard-back-art" aria-hidden>
          <rect x="4" y="4" width="52" height="76" rx="5" fill="none" stroke="#d4a943" strokeOpacity="0.55" strokeWidth="1.4" />
          <rect x="8" y="8" width="44" height="68" rx="3" fill="none" stroke="#d4a943" strokeOpacity="0.28" strokeWidth="1" />
          <path d="M30 12 44 42 30 72 16 42Z" fill="none" stroke="#d4a943" strokeOpacity="0.35" strokeWidth="1" />
          <path d="M30 24 38 42 30 60 22 42Z" fill="#d4a943" fillOpacity="0.14" />
          <circle cx="30" cy="42" r="4" fill="none" stroke="#d4a943" strokeOpacity="0.5" strokeWidth="1" />
          <text x="30" y="45.5" textAnchor="middle" fontSize="7" fontFamily="Limelight, serif" fill="#d4a943" fillOpacity="0.8">A</text>
        </svg>
      </div>
    );
  }

  const red = isRed(card.suit);
  return (
    <div className={`pcard ${red ? "red" : "black"}`} style={style} aria-label={`${card.rank} of ${card.suit}`}>
      <span className="pcard-corner tl">
        <span className="pcard-rank">{card.rank}</span>
        <Pip suit={card.suit} size={11} />
      </span>
      <span className="pcard-center">
        <Pip suit={card.suit} size={30} className="pcard-pip" />
      </span>
      <span className="pcard-corner br">
        <span className="pcard-rank">{card.rank}</span>
        <Pip suit={card.suit} size={11} />
      </span>
    </div>
  );
}
