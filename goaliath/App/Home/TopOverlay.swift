//
//  TopOverlay.swift
//  goaliath
//
//  Created by Daudi Sagala on 11/11/26.
//

import SwiftUI


struct TopOverlay: View {
    @EnvironmentObject private var live: GoaliathLiveStore
    var geometry: GeometryProxy
    @Binding var showMenu: Bool
    private let background = Color(hex: "EDF6F9")
    private let primary = Color(hex: "263B55")
    private let secondary = Color(hex: "637D91")
    private let accent = Color(hex: "526FA5")
    
    var body: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            } label: {
                ZStack {
                    Circle().fill(.white)
                        .frame(width: 40, height: 40)
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 24))
                        .foregroundStyle(primary)
                        .padding(10)
                }
                
            }
            
            Spacer()
            
            HStack {
                Text("Wed, Nov 11")
                    .font(.custom("Fredoka-SemiBold", size: 20))
                    .foregroundStyle(primary)
            }
            .frame(width: geometry.size.width * 0.5, height: 40, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 25).fill(.white))
          
            
            Spacer()
            
            //MARK: token count button
            GoaliathTokenHeaderButton(wallet: live.profile?.tokens ?? UserToken(balance: 0, earnedTotal: 0, purchasedTotal: 0, giftsReceivedTotal: 0, giftsSentTotal: 0, spentTotal: 0, recentTransactions: []))
        }
        .padding(.horizontal)
    }
}


