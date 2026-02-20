//
//  ConnectionSection.swift
//  Glance Companion
//
//  Section displaying connection status and sync button.
//

import SwiftUI
import CoreBluetooth

struct ConnectionSection: View {
    let bleManager: BLEManager
    let useDemoData: Bool
    let syncAction: () -> Void
    
    private var isConnected: Bool {
        bleManager.connectedPeripheral != nil
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Row
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if bleManager.isScanning {
                        ProgressView()
                    } else {
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundStyle(statusColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                if !isConnected {
                    Button {
                        bleManager.startScanning()
                    } label: {
                        Label(
                            bleManager.isScanning ? "Scanning..." : "Scan for X4",
                            systemImage: "antenna.radiowaves.left.and.right"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bleManager.isScanning)
                }
                
                Button(action: syncAction) {
                    Label(
                        bleManager.isSending ? "Syncing..." : "Sync Now",
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!isConnected || bleManager.isSending)
            }
            
            if isConnected {
                Button {
                    bleManager.disconnect()
                } label: {
                    Label("Disconnect", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            // Activity Log
            ActivityLogView(messages: bleManager.logMessages)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
        )
        .glassEffect(in: .rect(cornerRadius: 30))
    }
    
    private var statusColor: Color {
        if isConnected { return .green }
        return .red
    }
    
    private var statusIcon: String {
        if isConnected { return "wifi" }
        return "wifi.slash"
    }
    
    private var statusTitle: String {
        if isConnected { return "Connected" }
        if bleManager.isScanning { return "Scanning..." }
        return "Not Connected"
    }
    
    private var statusSubtitle: String {
        if isConnected { return bleManager.connectedPeripheral?.name ?? "Xteink X4" }
        return "Tap \"Scan for X4\" to connect"
    }
}

// MARK: - Activity Log

private struct ActivityLogView: View {
    let messages: [LogMessage]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Label("Activity Log", systemImage: "terminal")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(messages.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.2), in: Capsule())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(messages.reversed()) { message in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(logColor(for: message.text))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)
                                
                                Text(message.text)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                }
                .frame(maxHeight: 200)
            }
        }
    }
    
    private func logColor(for message: String) -> Color {
        if message.contains("ERROR") { return .red }
        if message.contains("success") || message.contains("Ready") { return .green }
        return .blue
    }
}
