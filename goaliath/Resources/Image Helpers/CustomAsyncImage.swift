//
//  CustomAsyncImage.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/9/26.
//


import SwiftUI

struct CustomAsyncImage: View {
    @StateObject private var loader = ImageLoader()
    let url: URL

    init(url: URL) {
        self.url = url
    }
 
    var body: some View {
        image
            .onAppear {
                loader.loadImage(from: url)
            }
            .onDisappear { loader.cancel() }
            .onChange(of: url) { _, newURL in loader.loadImage(from: newURL) }
    }

    private var image: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
            } else {
                
                Image("placeholder")
                    .resizable()
                
            }
        }
    }
}