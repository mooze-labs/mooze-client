import { SelectField } from "../../ui/select-field";
import { CopyButton } from "../../ui/copy-button";
import { useState } from "react";
import { QRCodeSVG } from "qrcode.react";
import type { ReceiveRequestDto } from "../../core/desktop.generated";
import { useT } from "../../i18n/messages";
import { Button } from "../../ui";
export function RequestPanel({
  request,
  busy,
  error,
  onRetry,
}: {
  request: ReceiveRequestDto | null;
  busy: boolean;
  error: string;
  onRetry: () => void;
}) {
  const t = useT();
  const [qrMode, setQrMode] = useState("request");
  return (
    <>
      {request ? (
        <>
          <div className="qr">
            <QRCodeSVG
              value={qrMode === "request" ? request.uri : request.address}
              size={210}
              level="M"
            />
          </div>
          <SelectField
            label={t("Conteúdo do QR")}
            className={"field qr-mode"}
            value={qrMode}
            onValueChange={(value) => setQrMode(value)}
            items={[
              {
                value: "request",
                label: <>{t("Pedido de pagamento")}</>,
              },
              { value: "address", label: <>{t("Somente endereço")}</> },
            ]}
          />
          <p className="mono address wrap">{request.address}</p>
          <div className="actions receive-copy-actions">
            <CopyButton
              value={qrMode === "request" ? request.uri : request.address}
              label={t(
                qrMode === "request"
                  ? "Copiar pedido de pagamento"
                  : "Copiar endereço",
              )}
              className="primary"
            />
            <CopyButton
              value={qrMode === "request" ? request.address : request.uri}
              label={t(
                qrMode === "request"
                  ? "Copiar endereço"
                  : "Copiar pedido de pagamento",
              )}
            />
          </div>
        </>
      ) : busy ? (
        <p role="status">{t("Gerando pedido…")}</p>
      ) : error ? (
        <Button onClick={onRetry}>{t("Tentar novamente")}</Button>
      ) : null}
    </>
  );
}
