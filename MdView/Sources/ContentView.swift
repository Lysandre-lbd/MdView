import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var pdfExportType: PDFExportType? = nil

    var body: some View {
        HSplitView {
            TextEditor(text: $document.text)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(minWidth: 300)

            MarkdownWebView(markdownText: document.text, pdfExportType: $pdfExportType)
                .frame(minWidth: 300)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    pdfExportType = .continuous
                } label: {
                    Label("Exporter PDF", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
