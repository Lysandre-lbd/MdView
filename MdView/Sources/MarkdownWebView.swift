import SwiftUI
import WebKit

enum PDFExportType {
    case continuous
    case print
}

class MarkdownWebViewCoordinator: NSObject, WKNavigationDelegate {
    var lastMarkdown: String = ""
    var isLoaded: Bool = false

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoaded = true
    }
}

struct MarkdownWebView: NSViewRepresentable {
    var markdownText: String
    @Binding var pdfExportType: PDFExportType?

    func makeCoordinator() -> MarkdownWebViewCoordinator {
        MarkdownWebViewCoordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if markdownText != context.coordinator.lastMarkdown {
            context.coordinator.lastMarkdown = markdownText
            
            if context.coordinator.isLoaded {
                // Real-time update via JS to avoid flicker
                let jsMarkdownData = try? JSONEncoder().encode(markdownText)
                let safeMarkdownString = String(data: jsMarkdownData ?? Data(), encoding: .utf8) ?? "\"\""
                nsView.evaluateJavaScript("window.updateMarkdown(\(safeMarkdownString))", completionHandler: nil)
            } else {
                // Initial load
                nsView.loadHTMLString(buildHTML(for: markdownText), baseURL: nil)
            }
        }

        if let exportType = pdfExportType {
            DispatchQueue.main.async {
                self.pdfExportType = nil
                self.waitAndExport(nsView, type: exportType, coordinator: context.coordinator)
            }
        }
    }

    private func waitAndExport(_ webView: WKWebView, type: PDFExportType, coordinator: MarkdownWebViewCoordinator, attempt: Int = 0) {
        if coordinator.isLoaded || attempt > 20 {
            performExport(webView, type: type)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitAndExport(webView, type: type, coordinator: coordinator, attempt: attempt + 1)
            }
        }
    }

    private func performExport(_ webView: WKWebView, type: PDFExportType) {
        switch type {
        case .continuous:
            webView.evaluateJavaScript("document.documentElement.scrollHeight") { result, _ in
                let height = (result as? CGFloat) ?? webView.bounds.height
                let config = WKPDFConfiguration()
                config.rect = CGRect(x: 0, y: 0, width: webView.bounds.width, height: height)
                webView.createPDF(configuration: config) { result in
                    DispatchQueue.main.async {
                        guard let data = try? result.get() else { return }
                        let panel = NSSavePanel()
                        panel.allowedContentTypes = [.pdf]
                        panel.nameFieldStringValue = "Document.pdf"
                        panel.title = "Enregistrer le PDF"
                        if panel.runModal() == .OK, let url = panel.url {
                            try? data.write(to: url)
                        }
                    }
                }
            }
        case .print:
            webView.printView(nil)
        }
    }

    func buildHTML(for markdownText: String) -> String {
        let jsMarkdownData = try? JSONEncoder().encode(markdownText)
        let safeMarkdownString = String(data: jsMarkdownData ?? Data(), encoding: .utf8) ?? "\"\""

        func bundleContent(_ name: String, _ ext: String) -> String {
            guard let path = Bundle.main.path(forResource: name, ofType: ext),
                  let content = try? String(contentsOfFile: path, encoding: .utf8) else { return "" }
            return content
        }

        func bundleBase64(_ name: String, _ ext: String) -> String {
            guard let path = Bundle.main.path(forResource: name, ofType: ext),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return "" }
            return data.base64EncodedString()
        }

        let markedJS = bundleContent("marked.min", "js")
        let katexJS = bundleContent("katex.min", "js")
        let hlJS = bundleContent("highlight.min", "js")
        var katexCSS = bundleContent("katex.min", "css")
        let hlLightCSS = bundleContent("highlight-github.min", "css")
        let hlDarkCSS = bundleContent("highlight-github-dark.min", "css")

        let fonts: [(String, String, String, String)] = [
            ("KaTeX_Main-Regular", "KaTeX_Main", "normal", "normal"),
            ("KaTeX_Main-Bold", "KaTeX_Main", "normal", "bold"),
            ("KaTeX_Main-Italic", "KaTeX_Main", "italic", "normal"),
            ("KaTeX_Math-Italic", "KaTeX_Math", "italic", "normal"),
            ("KaTeX_Size1-Regular", "KaTeX_Size1", "normal", "normal"),
            ("KaTeX_Size2-Regular", "KaTeX_Size2", "normal", "normal"),
            ("KaTeX_Size3-Regular", "KaTeX_Size3", "normal", "normal"),
            ("KaTeX_Size4-Regular", "KaTeX_Size4", "normal", "normal"),
            ("KaTeX_AMS-Regular", "KaTeX_AMS", "normal", "normal"),
            ("KaTeX_Fraktur-Regular", "KaTeX_Fraktur", "normal", "normal"),
            ("KaTeX_Caligraphic-Regular", "KaTeX_Caligraphic", "normal", "normal"),
            ("KaTeX_SansSerif-Regular", "KaTeX_SansSerif", "normal", "normal"),
            ("KaTeX_Typewriter-Regular", "KaTeX_Typewriter", "normal", "normal"),
        ]
        var fontFaces = ""
        for (file, family, style, weight) in fonts {
            let b64 = bundleBase64(file, "woff2")
            if !b64.isEmpty {
                fontFaces += "@font-face{font-family:'\(family)';font-style:\(style);font-weight:\(weight);src:url('data:font/woff2;base64,\(b64)') format('woff2');}\n"
            }
        }

        katexCSS = katexCSS.replacingOccurrences(of: #"url\(fonts/[^)]+\)"#, with: "url(DISABLED)", options: .regularExpression)

        return """
        <!DOCTYPE html><html><head>
        <meta charset="UTF-8">
        <script>\(markedJS)</script>
        <script>\(katexJS)</script>
        <script>\(hlJS)</script>
        <style>\(fontFaces)\(katexCSS)</style>
        <style media="(prefers-color-scheme:light)">\(hlLightCSS)</style>
        <style media="(prefers-color-scheme:dark)">\(hlDarkCSS)</style>
        <style>
          body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;font-size:15px;line-height:1.7;color:#24292e;max-width:820px;margin:0 auto;padding:24px;transition: background 0.2s, color 0.2s;}
          @media(prefers-color-scheme:dark){body{color:#e6edf3;background:#0d1117}}
          h1,h2,h3,h4,h5,h6{margin-top:24px;margin-bottom:12px;font-weight:600;line-height:1.25}
          h1{font-size:2em;border-bottom:1px solid #eaecef;padding-bottom:.3em}
          h2{font-size:1.5em;border-bottom:1px solid #eaecef;padding-bottom:.3em}
          @media(prefers-color-scheme:dark){h1,h2{border-bottom-color:#30363d}}
          p{margin:0 0 16px}
          code{background:rgba(27,31,35,.07);border-radius:4px;padding:.2em .4em;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:.9em}
          pre{border-radius:6px;overflow:auto;margin:0 0 16px}
          pre code{background:transparent;padding:0}
          @media(prefers-color-scheme:dark){code{background:rgba(255,255,255,.1)}pre{background:#161b22}}
          blockquote{margin:0 0 16px;padding:0 1em;color:#57606a;border-left:.25em solid #dfe2e5}
          @media(prefers-color-scheme:dark){blockquote{color:#8b949e;border-left-color:#3b434b}}
          table{border-collapse:collapse;width:100%;margin-bottom:16px}
          th,td{border:1px solid #dfe2e5;padding:8px 13px}
          th{background:#f6f8fa;font-weight:600}
          tr:nth-child(2n){background:#f6f8fa}
          @media(prefers-color-scheme:dark){th,td{border-color:#30363d}th,tr:nth-child(2n){background:#161b22}}
          .katex-display{overflow-x:auto;overflow-y:hidden;margin:16px 0}
          img{max-width:100%}
          a{color:#0969da}
          @media(prefers-color-scheme:dark){a{color:#58a6ff}}
        </style></head><body>
        <div id="content"></div>
        <script>
        window.updateMarkdown = function(md) {
          var mb=[],im=[];
          // 1. Math protection with improved regex
          md = md.replace(/\\\\\\$/g, "%%%ESCAPED_DOLLAR%%%");
          md = md.replace(/\\$\\$\\s*([\\s\\S]+?)\\s*\\$\\$/g, function(_,p){mb.push(p);return'\\x00MB'+(mb.length-1)+'\\x00';});
          md = md.replace(/\\$((?:\\\\.|[^$])+)\\$/g, function(_,p){im.push(p);return'\\x00MI'+(im.length-1)+'\\x00';});
          
          // 2. Parsing
          var html = marked.parse(md);

          // 3. Math restoration
          html = html.replace(/\\x00MB(\\d+)\\x00/g, function(_,i){
            try{return '<div class="katex-display">' + katex.renderToString(mb[+i],{displayMode:true,throwOnError:false}) + '</div>';}
            catch(e){return '$$' + mb[+i] + '$$';}
          });
          html = html.replace(/\\x00MI(\\d+)\\x00/g, function(_,i){
            try{return katex.renderToString(im[+i],{displayMode:false,throwOnError:false});}
            catch(e){return '$' + im[+i] + '$';}
          });
          html = html.replace(/%%%ESCAPED_DOLLAR%%%/g, "$");

          document.getElementById('content').innerHTML = html;
          
          if(typeof hljs !== 'undefined')
            document.querySelectorAll('pre code').forEach(function(b){hljs.highlightElement(b);});
        };

        // Initial render
        window.updateMarkdown(\(safeMarkdownString));
        </script>
        </body></html>
        """
    }
}
