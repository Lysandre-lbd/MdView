import Cocoa
import Quartz
import WebKit

class PreviewViewController: NSViewController, QLPreviewingController {

    var webView: WKWebView!

    override var nibName: NSNib.Name? { return nil }

    override func loadView() {
        let frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        webView = WKWebView(frame: frame)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        self.view = webView
    }

    func preparePreviewOfSearchableItem(identifier: String, queryString: String?, completionHandler handler: @escaping (Error?) -> Void) {
        handler(nil)
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let markdown = try String(contentsOf: url, encoding: .utf8)
                let html = self.buildHTML(for: markdown)
                DispatchQueue.main.async {
                    self.webView.loadHTMLString(html, baseURL: nil)
                    handler(nil)
                }
            } catch {
                DispatchQueue.main.async { handler(error) }
            }
        }
    }

    private func buildHTML(for markdown: String) -> String {
        let safe = (try? JSONEncoder().encode(markdown))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""

        func load(_ name: String, _ ext: String) -> String {
            guard let path = Bundle.main.path(forResource: name, ofType: ext),
                  let s = try? String(contentsOfFile: path, encoding: .utf8) else { return "" }
            return s
        }
        func b64(_ name: String, _ ext: String) -> String {
            guard let path = Bundle.main.path(forResource: name, ofType: ext),
                  let d = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return "" }
            return d.base64EncodedString()
        }

        let markedJS = load("marked.min", "js")
        let katexJS  = load("katex.min",  "js")
        let hlJS     = load("highlight.min", "js")
        var katexCSS = load("katex.min",  "css")
        let hlLight  = load("highlight-github.min", "css")
        let hlDark   = load("highlight-github-dark.min", "css")

        let fonts: [(String, String, String, String)] = [
            ("KaTeX_Main-Regular","KaTeX_Main","normal","normal"),
            ("KaTeX_Main-Bold","KaTeX_Main","normal","bold"),
            ("KaTeX_Main-Italic","KaTeX_Main","italic","normal"),
            ("KaTeX_Math-Italic","KaTeX_Math","italic","normal"),
            ("KaTeX_Size1-Regular","KaTeX_Size1","normal","normal"),
            ("KaTeX_Size2-Regular","KaTeX_Size2","normal","normal"),
            ("KaTeX_Size3-Regular","KaTeX_Size3","normal","normal"),
            ("KaTeX_Size4-Regular","KaTeX_Size4","normal","normal"),
            ("KaTeX_AMS-Regular","KaTeX_AMS","normal","normal"),
        ]
        var ff = ""
        for (file, family, style, weight) in fonts {
            let data = b64(file, "woff2"); guard !data.isEmpty else { continue }
            ff += "@font-face{font-family:'\(family)';font-style:\(style);font-weight:\(weight);src:url('data:font/woff2;base64,\(data)') format('woff2');}\n"
        }
        katexCSS = katexCSS.replacingOccurrences(of: #"url\(fonts/[^)]+\)"#, with: "url(DISABLED)", options: .regularExpression)

        return """
        <!DOCTYPE html><html><head><meta charset="UTF-8">
        <script>\(markedJS)</script>
        <script>\(katexJS)</script>
        <script>\(hlJS)</script>
        <style>\(ff)\(katexCSS)</style>
        <style media="(prefers-color-scheme:light)">\(hlLight)</style>
        <style media="(prefers-color-scheme:dark)">\(hlDark)</style>
        <style>
        body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;font-size:15px;line-height:1.7;color:#24292e;max-width:860px;margin:0 auto;padding:28px}
        @media(prefers-color-scheme:dark){body{color:#e6edf3;background:#0d1117}}
        h1,h2,h3,h4,h5,h6{margin-top:20px;margin-bottom:10px;font-weight:600}
        h1{font-size:2em;border-bottom:1px solid #eaecef;padding-bottom:.3em}
        h2{font-size:1.5em;border-bottom:1px solid #eaecef;padding-bottom:.3em}
        @media(prefers-color-scheme:dark){h1,h2{border-bottom-color:#30363d}}
        p{margin:0 0 14px}
        code{background:rgba(27,31,35,.07);border-radius:4px;padding:.2em .4em;font-family:ui-monospace,Menlo,monospace;font-size:.9em}
        pre{border-radius:6px;overflow:auto;margin:0 0 14px}
        pre code{background:transparent;padding:0}
        @media(prefers-color-scheme:dark){code{background:rgba(255,255,255,.1)}pre{background:#161b22}}
        blockquote{margin:0 0 14px;padding:0 1em;color:#57606a;border-left:.25em solid #dfe2e5}
        @media(prefers-color-scheme:dark){blockquote{color:#8b949e;border-left-color:#3b434b}}
        table{border-collapse:collapse;width:100%;margin-bottom:14px}
        th,td{border:1px solid #dfe2e5;padding:7px 12px}
        th{background:#f6f8fa;font-weight:600}
        @media(prefers-color-scheme:dark){th,td{border-color:#30363d}th{background:#161b22}}
        .katex-display{overflow-x:auto;margin:14px 0}
        img{max-width:100%}a{color:#0969da}
        @media(prefers-color-scheme:dark){a{color:#58a6ff}}
        </style></head><body>
        <div id="c"></div>
        <script>
        (function(){
          var r=\(safe),mb=[],im=[];
          r=r.replace(/\\$\\$([\\s\\S]+?)\\$\\$/g,function(_,p){mb.push(p.trim());return'\\x00MB'+(mb.length-1)+'\\x00';});
          r=r.replace(/\\$([^\\n$]+?)\\$/g,function(_,p){im.push(p);return'\\x00MI'+(im.length-1)+'\\x00';});
          var h=marked.parse(r);
          h=h.replace(/\\x00MB(\\d+)\\x00/g,function(_,i){try{return'<div class="katex-display">'+katex.renderToString(mb[+i],{displayMode:true,throwOnError:false})+'</div>';}catch(e){return'$$'+mb[+i]+'$$';}});
          h=h.replace(/\\x00MI(\\d+)\\x00/g,function(_,i){try{return katex.renderToString(im[+i],{displayMode:false,throwOnError:false});}catch(e){return'$'+im[+i]+'$';}});
          document.getElementById('c').innerHTML=h;
          if(typeof hljs!=='undefined')document.querySelectorAll('pre code').forEach(function(b){hljs.highlightElement(b);});
        })();
        </script></body></html>
        """
    }
}
