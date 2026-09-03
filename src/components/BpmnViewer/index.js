import React, {useEffect, useRef} from 'react';
import BrowserOnly from '@docusaurus/BrowserOnly';
import useBaseUrl from '@docusaurus/useBaseUrl';

function BpmnViewerInner({file, height}) {
  const containerRef = useRef(null);
  const viewerRef = useRef(null);

  // file задаётся от корня static, например "/bpmn/p01-disruption.bpmn".
  // useBaseUrl подставит baseUrl: локально "/bpmn/...", на Pages "/TravelTech/bpmn/...".
  const fileUrl = useBaseUrl(file);

  useEffect(() => {
    let cancelled = false;

    async function loadBpmn() {
      const BpmnJS = (await import('bpmn-js')).default;
      await import('bpmn-js/dist/assets/diagram-js.css');
      await import('bpmn-js/dist/assets/bpmn-js.css');
      await import('bpmn-js/dist/assets/bpmn-font/css/bpmn-embedded.css');

      if (cancelled || !containerRef.current) {
        return;
      }

      if (viewerRef.current) {
        viewerRef.current.destroy();
        viewerRef.current = null;
      }

      const viewer = new BpmnJS({container: containerRef.current});
      viewerRef.current = viewer;

      try {
        const response = await fetch(fileUrl);
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        const xml = await response.text();
        await viewer.importXML(xml);
        viewer.get('canvas').zoom('fit-viewport');
      } catch (err) {
        console.error('Ошибка загрузки BPMN:', err);
        if (containerRef.current) {
          containerRef.current.innerHTML =
            '<div style="display:flex;align-items:center;justify-content:center;' +
            'height:100%;color:#888;font-size:13px;padding:1rem;text-align:center;">' +
            'Диаграмма не загрузилась.<br/>Файл: ' +
            fileUrl +
            '</div>';
        }
      }
    }

    loadBpmn();

    return () => {
      cancelled = true;
      if (viewerRef.current) {
        viewerRef.current.destroy();
        viewerRef.current = null;
      }
    };
  }, [fileUrl]);

  return (
    <div>
      <div
        ref={containerRef}
        style={{
          width: '100%',
          height: height || '600px',
          border: '1px solid var(--ifm-color-emphasis-300)',
          borderRadius: '8px',
          overflow: 'hidden',
          backgroundColor: '#ffffff',
        }}
      />
      <p style={{fontSize: '0.8rem', marginTop: '0.5rem'}}>
        <a href={fileUrl} download>
          Скачать исходник .bpmn
        </a>
      </p>
    </div>
  );
}

export default function BpmnViewer({file, height}) {
  return (
    <BrowserOnly
      fallback={
        <div style={{padding: '2rem', textAlign: 'center', color: '#888'}}>
          Загрузка диаграммы...
        </div>
      }>
      {() => <BpmnViewerInner file={file} height={height} />}
    </BrowserOnly>
  );
}
