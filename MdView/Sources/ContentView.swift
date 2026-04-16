import SwiftUI

struct ContentView: View {
    @Binding var document: MarkdownDocument
    @State private var pdfExportType: PDFExportType? = nil
    @State private var isEditorVisible: Bool = true

    var body: some View {
        HSplitView {
            if isEditorVisible {
                TextEditor(text: $document.text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(minWidth: 200)
                    .transition(.move(edge: .leading))
            }

            MarkdownWebView(markdownText: document.text, pdfExportType: $pdfExportType)
                .frame(minWidth: 300)
        }
        .animation(.default, value: isEditorVisible)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isEditorVisible.toggle()
                } label: {
                    Label(isEditorVisible ? "Masquer l'éditeur" : "Afficher l'éditeur", systemImage: isEditorVisible ? "sidebar.left" : "sidebar.right")
                }
                .help(isEditorVisible ? "Masquer l'éditeur (Mode lecture)" : "Afficher l'éditeur")
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    pdfExportType = .continuous
                } label: {
                    Label("Exporter PDF", systemImage: "square.and.arrow.up")
                }
                .help("Exporter en PDF page continue")
            }
        }
    }
}
