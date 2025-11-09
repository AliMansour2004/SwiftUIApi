//
//  Post.swift
//  NetworkingPractice
//
//  Created by Ali Mansour on 07/11/2025.
//

import Foundation

struct Post: Identifiable, Codable {
  let userId: Int
  let id: Int
  let title: String
  let body: String
}


