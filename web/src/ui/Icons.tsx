// Crisp stroke icons — currentColor so tabs/buttons tint them.

function Svg({ children, size = 22 }: { children: React.ReactNode; size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.9"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden
    >
      {children}
    </svg>
  );
}

export function IconEmpire({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <path d="M3 21h18" />
      <path d="M5 21V8.5L12 4l7 4.5V21" />
      <path d="M9.5 21v-5.5h5V21" />
      <path d="M9.5 9.5h.01M14.5 9.5h.01M12 12.5h.01" />
    </Svg>
  );
}

export function IconChat({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <path d="M21 11.5a8.5 8.5 0 0 1-8.5 8.5c-1.5 0-3-.4-4.2-1.1L3 20l1.1-4.1A8.5 8.5 0 1 1 21 11.5z" />
      <path d="M8.5 11.5h.01M12.5 11.5h.01M16.5 11.5h.01" />
    </Svg>
  );
}

export function IconSpark({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <path d="M12 3l1.9 5.6L19.5 10.5l-5.6 1.9L12 18l-1.9-5.6L4.5 10.5l5.6-1.9z" />
      <path d="M18.5 3.5l.6 1.9 1.9.6-1.9.6-.6 1.9-.6-1.9-1.9-.6 1.9-.6z" />
    </Svg>
  );
}

export function IconProfile({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <circle cx="12" cy="8" r="4" />
      <path d="M4.5 20.5c1.4-3.7 4.2-5.5 7.5-5.5s6.1 1.8 7.5 5.5" />
    </Svg>
  );
}

export function IconCasino({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <path d="M12 3s7 5.6 7 9.6A3 3 0 0 1 13 14c.1 1.7.8 2.6 2 3.2H9c1.2-.6 1.9-1.5 2-3.2A3 3 0 0 1 5 12.6C5 8.6 12 3 12 3Z" />
    </Svg>
  );
}

export function IconMap({ size }: { size?: number }) {
  return (
    <Svg size={size}>
      <path d="M9 4L3.5 6v14L9 18l6 2 5.5-2V4L15 6z" />
      <path d="M9 4v14M15 6v14" />
    </Svg>
  );
}

export function IconSound({ muted, size = 16 }: { muted: boolean; size?: number }) {
  return (
    <Svg size={size}>
      <path d="M11 5.5L6.5 9H3v6h3.5L11 18.5z" />
      {muted ? (
        <path d="M16 9.5l5 5M21 9.5l-5 5" />
      ) : (
        <>
          <path d="M15.5 9a4.2 4.2 0 0 1 0 6" />
          <path d="M18.2 6.8a8 8 0 0 1 0 10.4" />
        </>
      )}
    </Svg>
  );
}

export function IconLock({ size = 12 }: { size?: number }) {
  return (
    <Svg size={size}>
      <rect x="5" y="10.5" width="14" height="10" rx="2.5" />
      <path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" />
    </Svg>
  );
}
