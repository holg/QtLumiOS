//
//  ContentView.swift
//  QEulumdat
//
//  Created by Holger Trahe on 13.05.23.
//

import SwiftUI
import WebKit

enum WebViewError: Error {
    case contentConversion(String)
    case emptyFileName
    case inivalidFilePath
    
    var message: String {
        switch self {
        case let .contentConversion(message):
            return "There was an error converting the file path to an HTML String. Error \(message)"
        case .emptyFileName:
            return "The file name was empty."
        case .inivalidFilePath:
            return "The file path is invalid."
        }
    }
}

let freeport = extern_get_port()

func http_serve() async {
    let string_path = Bundle.main.path(forResource: "qtlogo", ofType: "svg").unsafelyUnwrapped
    let dir = string_path.replacingOccurrences(of: "qtlogo.svg", with: "")
    start_server(dir, freeport)
    //start_server(".")
}

func callhttp_serve() {
    let task = Task {
        await http_serve()
    }
}

struct WebView: UIViewRepresentable {
    let htmlFileName: String
    let onError: (WebViewError) -> Void
    let t = callhttp_serve()

    func makeUIView(context: Context) -> some UIView {
        // Allow access to local files.
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(htmlFileName, onError: onError)
        return webView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

extension WKWebView {
    
    func load(_ htmlFileName: String, onError:
        (WebViewError) -> Void){
        guard !htmlFileName.isEmpty else {
            return onError(.emptyFileName)
        }
        guard let filePath = Bundle.main.path(forResource: htmlFileName, ofType: "html") else {
            return onError(.inivalidFilePath)
        }
        do {
            //let htmlString = try String(contentsOfFile: filePath, encoding: .utf8)
            //loadHTMLString(htmlString, baseURL: URL(fileURLWithPath: filePath))
            // This won't load the WASM, so we dd do the rust tiny_http lib to serve ourselves
            let url = String(format: "http://127.0.0.1:%d/QLumEdit.html", freeport)
            load(URLRequest(url: URL(string: url)!))
        } catch let error {
            onError(.contentConversion(error.localizedDescription))
        }
        
    }
}

struct ContentView: View {
    var body: some View {
        WebView(htmlFileName: "QLumEdit", onError: { error in
            print(error.message)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
