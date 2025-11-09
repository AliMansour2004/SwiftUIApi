//
//  PostsView.swift
//  NetworkingPractice
//
//  Created by Ali Mansour on 07/11/2025.
//

import SwiftUI

struct PostsView: View {
  @StateObject private var vm = PostsViewModel()

  var body: some View {
    NavigationStack {
      Group {
        if vm.isLoading && vm.posts.isEmpty {
          ProgressView("Loading…")
        } else if let error = vm.error, vm.posts.isEmpty {
          VStack(spacing: 12) {
            Text("Something went wrong").font(.headline)
            Text(error).foregroundStyle(.red).multilineTextAlignment(.center)
            Button("Retry") { vm.load() }.buttonStyle(.borderedProminent)
          }
          .padding()
        } else if vm.posts.isEmpty {
          ContentUnavailableView("No posts", systemImage: "tray")
        } else {
          List {
            ForEach(vm.posts) { post in
              VStack(alignment: .leading, spacing: 6) {
                Text(post.title).font(.headline)
                Text(post.body).foregroundStyle(.secondary)
              }
              .padding(.vertical, 4)
            }

            // Footer area: spinner → load button → "All caught up"
            if vm.isPaging {
              HStack {
                Spacer()
                ProgressView().padding(.vertical, 12)
                Spacer()
              }
            } else if vm.hasMore {
              HStack {
                Spacer()
                Button {
                  vm.loadMore()
                } label: {
                  HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                    Text("Load more")
                  }
                }
                .buttonStyle(.bordered)
                .padding(.vertical, 12)
                Spacer()
              }
            } else {
              HStack {
                Spacer()
                Text("All caught up")
                  .foregroundStyle(.secondary)
                  .padding(.vertical, 12)
                Spacer()
              }
            }
          }
          .listStyle(.plain)
        }
      }
      .navigationTitle("Posts")
      .task { vm.load() }
      .refreshable { vm.refresh() }
    }
  }
}
