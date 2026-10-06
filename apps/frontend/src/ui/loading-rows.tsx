export function LoadingRows({
  label,
  rows = 2,
}: {
  label: string;
  rows?: number;
}) {
  return (
    <div className="loading-rows" role="status" aria-label={label}>
      <span className="sr-only">{label}</span>
      <div aria-hidden="true">
        {Array.from({ length: rows }, (_, index) => (
          <div className="loading-row" key={index}>
            <span className="skeleton skeleton-circle" />
            <span className="loading-label">
              <span className="skeleton skeleton-title" />
              <span className="skeleton skeleton-subtitle" />
            </span>
            <span className="skeleton skeleton-amount" />
          </div>
        ))}
      </div>
    </div>
  );
}
