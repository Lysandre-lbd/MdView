import SwiftUI

@main
struct MdViewApp: App {
    
    init() {
        checkAndRequestDefaultApp()
    }
    
    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            ContentView(document: file.$document)
                .frame(minWidth: 800, minHeight: 600)
        }
    }
    
    private func checkAndRequestDefaultApp() {
        let uti = "net.daringfireball.markdown" as CFString
        
        // Ensure bundle identifier is valid
        guard let bundleID = Bundle.main.bundleIdentifier as CFString? else { return }
        
        // Check current default app
        let currentDefault = LSCopyDefaultRoleHandlerForContentType(uti, .editor)?.takeRetainedValue() as String?
        
        if currentDefault != (bundleID as String) {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Application par défaut"
                alert.informativeText = "MdView n'est actuellement pas l'application par défaut pour les fichiers Markdown. Voulez-vous la définir comme application par défaut ?"
                alert.addButton(withTitle: "Oui")
                alert.addButton(withTitle: "Non")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    let status = LSSetDefaultRoleHandlerForContentType(uti, .editor, bundleID)
                    if status != noErr {
                        print("Erreur lors de l'assignation : \\(status)")
                    }
                }
                
                // QuickLook prompt right after Default App prompt closes
                self.promptForQuickLook()
            }
        } else {
            promptForQuickLook()
        }
    }
    
    private func promptForQuickLook() {
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "QuickLookRegistered") {
            // Force-register the QuickLook extension via pluginkit
            DispatchQueue.global(qos: .background).async {
                if let extPath = Bundle.main.builtInPlugInsURL?
                    .appendingPathComponent("MdViewQuickLook.appex").path {
                    let task = Process()
                    task.launchPath = "/usr/bin/pluginkit"
                    task.arguments = ["-a", extPath]
                    try? task.run()
                    task.waitUntilExit()
                    
                    let task2 = Process()
                    task2.launchPath = "/usr/bin/pluginkit"
                    task2.arguments = ["-e", "use", "-i", "com.lysandre.MdView.MdViewQuickLook"]
                    try? task2.run()
                    task2.waitUntilExit()
                }
                
                DispatchQueue.main.async {
                    defaults.set(true, forKey: "QuickLookRegistered")
                    let alert = NSAlert()
                    alert.messageText = "Aperçu QuickLook Activé ✓"
                    alert.informativeText = "L'extension QuickLook de MdView a été enregistrée. Sélectionnez un fichier .md dans le Finder et appuyez sur Espace pour l'aperçu instantané."
                    alert.addButton(withTitle: "Super !")
                    alert.runModal()
                }
            }
        }
    }
}
