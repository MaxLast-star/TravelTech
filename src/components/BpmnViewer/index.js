import React, { useEffect, useRef, useState, useCallback } from "react";
import BrowserOnly from "@docusaurus/BrowserOnly";
import useBaseUrl from "@docusaurus/useBaseUrl";

function BpmnViewerInner({ file, height }) {
  const containerRef = useRef(null);
  const wrapRef = useRef(null);
  const viewerRef = useRef(null);
  const [ready, setReady] = useState(false);
  const [full, setFull] = useState(false);

  // file задаётся от корня static, например "/bpmn/p01-disruption.bpmn".
  // useBaseUrl подставит baseUrl: локально "/bpmn/...", на Pages "/TravelTech/bpmn/...".
  const fileUrl = useBaseUrl(file);

  useEffect(() => {
    let cancelled = false;

    async function loadBpmn() {
      // NavigatedViewer, а не Viewer: базовый вьюер не подключает модули
      // MoveCanvas и ZoomScroll, поэтому диаграмму нельзя ни двигать, ни масштабировать.
      const NavigatedViewer = (await import("bpmn-js/lib/NavigatedViewer"))
        .default;
      await import("bpmn-js/dist/assets/diagram-js.css");
      await import("bpmn-js/dist/assets/bpmn-js.css");
      await import("bpmn-js/dist/assets/bpmn-font/css/bpmn-embedded.css");

      if (cancelled || !containerRef.current) {
        return;
      }

      if (viewerRef.current) {
        viewerRef.current.destroy();
        viewerRef.current = null;
      }

      const viewer = new NavigatedViewer({
        container: containerRef.current,
        keyboard: { bindTo: containerRef.current },
      });
      viewerRef.current = viewer;

      try {
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        const xml = await response.text();
        await viewer.importXML(xml);
        viewer.get("canvas").zoom("fit-viewport", "auto");
        if (!cancelled) {
          setReady(true);
        }
      } catch (err) {
        console.error("Ошибка загрузки BPMN:", err);
        if (containerRef.current) {
          containerRef.current.innerHTML =
            '<div style="display:flex;align-items:center;justify-content:center;' +
            'height:100%;color:#888;font-size:13px;padding:1rem;text-align:center;">' +
            "Диаграмма не загрузилась.<br/>Файл: " +
            fileUrl +
            "</div>";
        }
      }
    }

    loadBpmn();

    return () => {
      cancelled = true;
      setReady(false);
      if (viewerRef.current) {
        viewerRef.current.destroy();
        viewerRef.current = null;
      }
    };
  }, [fileUrl]);

  const canvas = () => viewerRef.current && viewerRef.current.get("canvas");

  const zoomBy = useCallback((factor) => {
    const c = canvas();
    if (c) {
      c.zoom(Math.min(4, Math.max(0.2, c.zoom() * factor)));
    }
  }, []);

  const fit = useCallback(() => {
    const c = canvas();
    if (c) {
      c.zoom("fit-viewport", "auto");
    }
  }, []);

  // Пересчёт после смены размера контейнера: во весь экран и обратно.
  useEffect(() => {
    if (!ready) return undefined;
    const t = setTimeout(fit, 60);
    return () => clearTimeout(t);
  }, [full, ready, fit]);

  useEffect(() => {
    if (!full) return undefined;
    const onKey = (e) => {
      if (e.key === "Escape") setFull(false);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [full]);

  const btn = {
    border: "1px solid var(--ifm-color-emphasis-300)",
    borderRadius: "6px",
    background: "var(--ifm-background-surface-color)",
    color: "var(--ifm-font-color-base)",
    cursor: "pointer",
    fontSize: "0.8rem",
    lineHeight: 1,
    padding: "0.35rem 0.6rem",
  };

  const wrapStyle = full
    ? {
        position: "fixed",
        inset: 0,
        zIndex: 400,
        background: "var(--ifm-background-color)",
        padding: "0.75rem",
        display: "flex",
        flexDirection: "column",
      }
    : {};

  return (
    <div ref={wrapRef} style={wrapStyle}>
      <div
        style={{
          display: "flex",
          gap: "0.4rem",
          alignItems: "center",
          marginBottom: "0.4rem",
          flexWrap: "wrap",
        }}
      >
        <button
          type="button"
          style={btn}
          onClick={() => zoomBy(1.25)}
          aria-label="Приблизить"
        >
          +
        </button>
        <button
          type="button"
          style={btn}
          onClick={() => zoomBy(0.8)}
          aria-label="Отдалить"
        >
          −
        </button>
        <button type="button" style={btn} onClick={fit}>
          Вписать
        </button>
        <button type="button" style={btn} onClick={() => setFull((v) => !v)}>
          {full ? "Свернуть (Esc)" : "Во весь экран"}
        </button>
        <span
          style={{
            fontSize: "0.75rem",
            color: "var(--ifm-color-emphasis-600)",
          }}
        >
          Тянуть мышью — двигать, Ctrl + колесо — масштаб
        </span>
      </div>
      <div
        ref={containerRef}
        style={{
          width: "100%",
          height: full ? "100%" : height || "600px",
          flex: full ? "1 1 auto" : undefined,
          border: "1px solid var(--ifm-color-emphasis-300)",
          borderRadius: "8px",
          overflow: "hidden",
          backgroundColor: "#ffffff",
        }}
      />
      {!full && (
        <p style={{ fontSize: "0.8rem", marginTop: "0.5rem" }}>
          <a href={fileUrl} download>
            Скачать исходник .bpmn
          </a>
        </p>
      )}
    </div>
  );
}

export default function BpmnViewer({ file, height }) {
  return (
    <BrowserOnly
      fallback={
        <div style={{ padding: "2rem", textAlign: "center", color: "#888" }}>
          Загрузка диаграммы...
        </div>
      }
    >
      {() => <BpmnViewerInner file={file} height={height} />}
    </BrowserOnly>
  );
}
