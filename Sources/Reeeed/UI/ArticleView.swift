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
    var onLinkClicked: ((URL) -> Bool)?
    @Binding var viewState: ArticleViewState
    
    public init(url: URL, viewState: Binding<ArticleViewState> = .constant(.web)) {
        self.url = url
        self.onLinkClicked = nil
        self._viewState = viewState
    }
    
    public var body: some View {
        content
//            .ignoresSafeArea(edges: .all)
    }
    
    @ViewBuilder
    var content: some View {
        switch viewState {
        case .web:
            WebPageView(url: url) { url in
                onLinkClicked?(url) ?? false
            }
        case .reader:
            ReaderView(url: url, viewState: $viewState, theme: theme) { url in
                onLinkClicked?(url) ?? false
            }
        case .fallbackWeb:
            WebPageView(url: url) { url in
                onLinkClicked?(url) ?? false
            }
        }
    }
}

private struct WebPageView: View {
    var url: URL
    var onLinkClicked: (URL) -> Bool
    
    @StateObject private var content = WebContent()
    
    var body: some View {
        WebView(content: content)
            .ignoresSafeArea(edges: .all)
            .onAppear {
                setupLinkNavigation()
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
    
    private func setupLinkNavigation() -> Void {
        content.shouldBlockNavigation = { request -> Bool in
            if request.navigationType == .linkActivated, let url = request.request.url {
                return !onLinkClicked(url)
            }
            
            return false
        }
    }
}

private enum ReaderViewStatus: Equatable {
    case fetching, failed
    case extracted(ReadableDoc)
}

private struct ReaderView: View {
    var url: URL
    @Binding var viewState: ArticleViewState
    var theme: ReaderTheme
    var onLinkClicked: (URL) -> Bool
    
    @State private var status: ReaderViewStatus = .fetching
    @StateObject private var content = WebContent(transparent: true)
    
    init(url: URL, viewState: Binding<ArticleViewState>, theme: ReaderTheme, onLinkClicked: @escaping (URL) -> Bool) {
        self.url = url
        self._viewState = viewState
        self.theme = theme
        self.onLinkClicked = onLinkClicked
    }
    
    var body: some View {
        WebView(content: content)
            .ignoresSafeArea(edges: .all)
            .overlay {
                if status == .fetching {
                    ReaderPlaceholder(theme: theme)
                }
            }
            .onAppear {
                setupLinkNavigation()
            }
            .task(id: url) {
                do {
                    var result = try await Reeeed.fetchAndExtractContent(fromURL: url)
                    self.status = .extracted(result)
                    var html = result.html(includeExitReaderButton: false, theme: theme)
                    content.populate { content in
                        content.load(html: html, baseURL: result.url)
                    }
                } catch {
                    if await !Task.isCancelled {
                        self.status = .failed
                        self.viewState = .fallbackWeb
                    }
                }
            }
            .onChange(of: theme) { oldValue, newValue in
                if case .extracted(let readableDoc) = status {
                    var html = readableDoc.html(includeExitReaderButton: false, theme: theme)
                    content.populate { content in
                        content.load(html: html, baseURL: readableDoc.url)
                    }
                }
            }
    }
    
    private func setupLinkNavigation() -> Void {
        content.shouldBlockNavigation = { request -> Bool in
            if request.navigationType == .linkActivated, let url = request.request.url {
                return !onLinkClicked(url)
            }
            
            return false
        }
    }
}

extension ArticleView {
    public func theme(_ theme: ReaderTheme) -> Self {
        var copy = self
        copy.theme = theme
        return copy
    }
    
    public func onLinkClicked(_ perform: @escaping (URL) -> Bool) -> Self {
        var copy = self
        copy.onLinkClicked = perform
        return copy
    }
}
