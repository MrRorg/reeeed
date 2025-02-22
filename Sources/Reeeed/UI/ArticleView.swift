//
//  ArticleView.swift
//  Reeeed
//
//  Created by Alexey Nikitin on 2/12/25.
//

import SwiftUI

public enum ArticleViewState: String {
    case reader, web, fallbackWeb
}

public struct ArticleView: View {
    var url: URL
    var theme: ReaderTheme = .init()
    var onLinkClicked: ((URL) -> Void)?
    @Binding var viewState: ArticleViewState
    
    public init(url: URL, viewState: Binding<ArticleViewState> = .constant(.web)) {
        self.url = url
        self.onLinkClicked = nil
        self._viewState = viewState
    }
    
    public var body: some View {
        content
            .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    var content: some View {
        switch viewState {
        case .web:
            WebPageView(url: url) { url in
                onLinkClicked?(url)
            }
        case .reader:
            ReaderView(url: url, viewState: $viewState, theme: theme) { url in
                onLinkClicked?(url)
            }
        case .fallbackWeb:
            WebPageView(url: url) { url in
                onLinkClicked?(url)
            }
        }
    }
}

private struct WebPageView: View {
    var url: URL
    var onLinkClicked: (URL) -> Void
    
    @StateObject private var content = WebContent()
    
    var body: some View {
        WebView(content: content)
            .onAppear {
                content.populate { content in
                    content.load(url: url)
                }
            }
            .onChange(of: url) { _, newValue in
                content.populate { content in
                    content.load(url: url)
                }
            }
    }
}

private enum ReaderViewStatus: Equatable {
    case fetching, failed
    case extracted
}

private struct ReaderView: View {
    var url: URL
    @Binding var viewState: ArticleViewState
    var theme: ReaderTheme
    var onLinkClicked: (URL) -> Void
    
    @State private var status: ReaderViewStatus = .fetching
    @StateObject private var content = WebContent(transparent: true)
    
    var body: some View {
        WebView(content: content)
            .overlay {
                if status != .extracted {
                    ReaderPlaceholder(theme: theme)
                }
            }
            .onAppear {
                
            }
            .task(id: url) {
                do {
                    var result = try await Reeeed.fetchAndExtractContent(fromURL: url)
                    var html = result.html(includeExitReaderButton: false, theme: theme)
                    self.status = .extracted
                    content.populate { content in
                        content.load(html: html, baseURL: result.url)
                    }
                } catch {
                    self.status = .failed
                    self.viewState = .fallbackWeb
                }
            }
    }
}

extension ArticleView {
    public func theme(_ theme: ReaderTheme) -> Self {
        var copy = self
        copy.theme = theme
        return copy
    }
}
