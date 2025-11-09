//
//  PostsViewModel.swift
//  NetworkingPractice
//
//  Created by Ali Mansour on 07/11/2025.
//

import SwiftUI
import Combine
import Foundation

@MainActor
final class PostsViewModel: ObservableObject {
  @Published var posts: [Post] = []
  @Published var isLoading = false      // initial / refresh spinner
  @Published var isPaging  = false      // bottom spinner for next pages
  @Published var error: String?

  private let api = APIClient()
  private var loadTask: Task<Void, Never>?

  // 📄 Paging state
  private var page = 1
  private let pageSize = 20
  private var hasMore = true

  // MARK: - Public API

  func load() { loadFirstPage() }       // initial load
  func refresh() { loadFirstPage() }    // pull-to-refresh

  /// Call from the last row's onAppear
  func loadMoreIfNeeded(currentPost: Post?) {
    guard hasMore, !isPaging, !isLoading else { return }
    guard let currentPost = currentPost else { return }
    if currentPost.id == posts.last?.id {
      page += 1
      loadNextPage()
    }
  }

  // MARK: - Internal loads

  private func loadFirstPage() {
    loadTask?.cancel()
    page = 1
    hasMore = true
    posts.removeAll()

    loadTask = Task { await fetchPage(page, replace: true) }
  }

  private func loadNextPage() {
    guard hasMore else { return }
    loadTask?.cancel() // safe: avoid overlapping
    loadTask = Task { await fetchPage(page, replace: false) }
  }

  private func fetchPage(_ page: Int, replace: Bool) async {
    if replace { isLoading = true } else { isPaging = true }
    defer {
      if replace { isLoading = false } else { isPaging = false }
    }

    do {
      #if DEBUG
      print("📄 Fetching page \(page) • replace=\(replace)")
      #endif

      let items: [Post] = try await api.get(
        "posts",
        query: [
          URLQueryItem(name: "_page",  value: String(page)),
          URLQueryItem(name: "_limit", value: String(pageSize))
        ]
      )
      try Task.checkCancellation()

      error = nil
      if replace {
        posts = items
      } else {
        posts += items
      }

      // If fewer than a full page returned, no more data.
      hasMore = items.count == pageSize

      #if DEBUG
      print("✅ Loaded \(items.count) items (total \(posts.count)) • hasMore=\(hasMore)")
      #endif
    } catch is CancellationError {
      #if DEBUG
      print("⏹️ Canceled page \(page)")
      #endif
    } catch let apiErr as APIError {
      self.error = apiErr.localizedDescription
    } catch {
      self.error = error.localizedDescription
    }
  }

  deinit { loadTask?.cancel() }
}

