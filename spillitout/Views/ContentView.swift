// Swift 5.0
//
//  ContentView.swift
//  spillitout
//
//  Created by thorfinn on 2/14/25.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
import PDFKit
import Speech
import AVFoundation
import AVKit

struct ContentView: View {
    private let headerString = "\n\n"
    @State private var entries: [HumanEntry] = []
    @State private var text: String = ""

    @State private var selectedFont: String = "Arial"
    @State private var currentRandomFont: String = ""
    @State private var timeRemaining: Int = AppSettings.defaultTimerDuration
    @State private var timerIsRunning = false
    @State private var fontSize: CGFloat = 18
    @State private var bottomNavOpacity: Double = 1.0
    @State private var selectedEntryId: UUID? = nil
    @State private var showingSidebar = false
    @State private var placeholderText: String = ""
    @State private var lastTypingTime: Date? = nil
    @State private var typingTimer: Timer? = nil
    @State private var deviceUUID: String = ""
    @State private var isCheckingSubscription = false
    @State private var showingPaymentSuccess = false
    @State private var showingPaymentFailure = false
    @State private var showingSubscriptionRequired = false
    @State private var isPollingForSubscription = false

    // App state for navigation
    @StateObject private var appState = AppState.shared
    
    // Services
    @StateObject private var fileService = FileService()
    @StateObject private var speechService = SpeechService()
    @StateObject private var preferencesService = PreferencesService()
    @StateObject private var backspaceService = BackspaceService()
    private let pdfExportService = PDFExportService()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let availableFonts = NSFontManager.shared.availableFontFamilies
    
    private func loadExistingEntries() {
        entries = fileService.loadExistingEntries()
        
        // Check if we need to create a new entry
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        
        // Check if there's an empty entry from today
        let hasEmptyEntryToday = entries.contains { entry in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            if let entryDate = dateFormatter.date(from: entry.date) {
                var components = calendar.dateComponents([.year, .month, .day], from: entryDate)
                components.year = calendar.component(.year, from: today)
                
                if let entryDateWithYear = calendar.date(from: components) {
                    let entryDayStart = calendar.startOfDay(for: entryDateWithYear)
                    return calendar.isDate(entryDayStart, inSameDayAs: todayStart) && entry.previewText.isEmpty
                }
            }
            return false
        }
        
        if entries.isEmpty {
            createNewEntry()
        } else if !hasEmptyEntryToday {
            createNewEntry()
        } else {
            if let todayEntry = entries.first(where: { entry in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d"
                if let entryDate = dateFormatter.date(from: entry.date) {
                    var components = calendar.dateComponents([.year, .month, .day], from: entryDate)
                    components.year = calendar.component(.year, from: today)
                    
                    if let entryDateWithYear = calendar.date(from: components) {
                        let entryDayStart = calendar.startOfDay(for: entryDateWithYear)
                        return calendar.isDate(entryDayStart, inSameDayAs: todayStart) && entry.previewText.isEmpty
                    }
                }
                return false
            }) {
                selectedEntryId = todayEntry.id
                if let content = fileService.loadEntry(entry: todayEntry) {
                    text = content
                }
            }
        }
    }
    
    private var lineHeight: CGFloat {
        fontSize * 0.3
    }
    
    private var backgroundColor: Color {
        preferencesService.colorScheme == .light ? Color(red: 0.992, green: 0.992, blue: 0.992) : Color(red: 0.08, green: 0.08, blue: 0.08)
    }
    
    // Font buttons section
    private var fontButtonsSection: some View {
        FontButtonsSection(
            fontSize: $fontSize,
            selectedFont: $selectedFont,
            currentRandomFont: $currentRandomFont,
            fontSizes: AppSettings.fontSizes,
            availableFonts: availableFonts
        )
    }
    

    
    private var textColor: Color {
        preferencesService.colorScheme == .light ? Color.gray : Color.gray.opacity(0.8)
    }
    
    private var textHoverColor: Color {
        preferencesService.colorScheme == .light ? Color.black : Color.white
    }
    
    // Bottom navigation view
    private var bottomNavigationView: some View {
        VStack {
            Spacer()
            HStack {
                fontButtonsSection
                Spacer()
                UtilityButtonsSection(
                    timeRemaining: $timeRemaining,
                    timerIsRunning: $timerIsRunning,
                    showingSidebar: $showingSidebar,
                    speechService: speechService,
                    preferencesService: preferencesService,
                    backspaceService: backspaceService,
                    text: text,
                    onNewEntry: createNewEntry,
                    onReflect: handleReflectButtonClick,
                    onBottomNavHover: handleBottomNavHover
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var writingView: some View {
        HStack(spacing: 0) {
            // Main content
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                
                TextEditorView(
                    text: $text,
                    selectedFont: $selectedFont,
                    fontSize: $fontSize,
                    placeholderText: $placeholderText,
                    bottomNavOpacity: bottomNavOpacity,
                    onTextChange: handleTextChange
                )
                
                bottomNavigationView
            }
            .padding()
            .background(backgroundColor)
            
            // Right sidebar
            if showingSidebar {
                Divider()
                SidebarView(
                    entries: $entries,
                    selectedEntryId: $selectedEntryId,
                    onSelectEntry: selectEntry,
                    onDeleteEntry: deleteEntry,
                    onExportEntry: exportEntryAsPDF,
                    fileService: fileService
                )
            }
        }
        .frame(minWidth: 1100, minHeight: 600)
        .animation(.easeInOut(duration: 0.2), value: showingSidebar)
        .preferredColorScheme(preferencesService.colorScheme)
    }
    
    private var reflectionSelectionView: some View {
        ReflectionSelectionView(
            appState: appState,
            currentText: text,
            reflectionService: ReflectionService(fileService: fileService)
        )
        .frame(minWidth: 800, minHeight: 600)
        .preferredColorScheme(preferencesService.colorScheme)
    }
    
    private var voiceAgentView: some View {
        VoiceAgentWrapperView(
            appState: appState,
            initialContext: appState.reflectionContext
        )
        .frame(minWidth: 1100, minHeight: 600)
        .preferredColorScheme(preferencesService.colorScheme)
    }

    var body: some View {
        Group {
            switch appState.currentMode {
            case .writing:
                writingView
            case .reflectionSelection:
                reflectionSelectionView
            case .voiceAgent:
                voiceAgentView
            }
        }
        .onAppear {
            showingSidebar = false

            // Get or create device UUID
            deviceUUID = DeviceUUIDService.shared.getOrCreateDeviceUUID()

            loadExistingEntries()
            setupKeyboardEvents()

            // Setup speech service callback after view is initialized
            speechService.onTextUpdate = { newText in
                DispatchQueue.main.async {
                    self.text = newText
                }
            }
        }
        .onChange(of: text) { _ in
            saveCurrentEntry()
        }
        .onReceive(timer) { _ in
            updateTimer()
        }
        .alert("Subscription Required", isPresented: $showingSubscriptionRequired) {
            Button("Continue") {
                showingSubscriptionRequired = false
                proceedToCheckout()
            }
            Button("Cancel", role: .cancel) {
                showingSubscriptionRequired = false
            }
        } message: {
            Text("The Reflect feature requires an active subscription. You will be redirected to complete your purchase.")
        }
        .alert("Subscription Active!", isPresented: $showingPaymentSuccess) {
            Button("Continue") {
                showingPaymentSuccess = false
                appState.switchToReflectionSelection()
            }
        } message: {
            Text("Your subscription is now active. You can now use the Reflect feature!")
        }
        .alert("Payment Failed", isPresented: $showingPaymentFailure) {
            Button("OK") {
                showingPaymentFailure = false
            }
        } message: {
            Text("We couldn't process your payment. Please try again.")
        }
    }
    
    // MARK: - Helper Methods

    private func handleReflectButtonClick() {
        guard !isCheckingSubscription else { return }

        isCheckingSubscription = true

        Task {
            do {
                let hasSubscription = try await SubscriptionService.shared.checkSubscription(deviceId: deviceUUID)

                await MainActor.run {
                    isCheckingSubscription = false

                    if hasSubscription {
                        // User has subscription, proceed to reflection
                        appState.switchToReflectionSelection()
                    } else {
                        // User doesn't have subscription, show popup first
                        showingSubscriptionRequired = true
                    }
                }
            } catch {
                await MainActor.run {
                    isCheckingSubscription = false
                    print("Error checking subscription: \(error)")
                    // Show error alert to user
                    showSubscriptionCheckError()
                }
            }
        }
    }

    private func proceedToCheckout() {
        Task {
            do {
                _ = try await PaymentService.shared.createCheckoutSession(deviceId: deviceUUID)
                // Checkout URL will open in browser automatically
                // Start polling for subscription activation
                startPollingForSubscription()
            } catch {
                print("Error creating checkout session: \(error)")
                // Show error alert to user
                await MainActor.run {
                    showCheckoutError()
                }
            }
        }
    }

    private func startPollingForSubscription() {
        guard !isPollingForSubscription else { return }

        isPollingForSubscription = true

        Task {
            // Poll every 3 seconds for up to 5 minutes (100 attempts)
            for attempt in 1...100 {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                do {
                    let hasSubscription = try await SubscriptionService.shared.checkSubscription(deviceId: deviceUUID)

                    if hasSubscription {
                        // Subscription activated!
                        await MainActor.run {
                            isPollingForSubscription = false
                            showingPaymentSuccess = true
                        }
                        return
                    }
                } catch {
                    print("Error polling subscription: \(error)")
                }

                // Check if user is still on this screen
                if appState.currentMode != .writing {
                    await MainActor.run {
                        isPollingForSubscription = false
                    }
                    return
                }
            }

            // Polling timed out - user may have abandoned checkout
            await MainActor.run {
                isPollingForSubscription = false
            }
        }
    }

    private func showCheckoutError() {
        let alert = NSAlert()
        alert.messageText = "Payment Error"
        alert.informativeText = "Unable to create checkout session. Please try again later."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func showSubscriptionCheckError() {
        let alert = NSAlert()
        alert.messageText = "Subscription Check Failed"
        alert.informativeText = "Unable to verify subscription status. Please check your connection and try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func handleBottomNavHover(_ hovering: Bool) {
        // Keep navbar opaque by default - no transparency behavior
        bottomNavOpacity = 1.0
    }
    
    private func setupKeyboardEvents() {
        // Add keyboard event monitoring for ESC key to exit fullscreen and backspace blocking
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // 53 is the key code for ESC
                if let window = NSApplication.shared.windows.first {
                    if window.styleMask.contains(.fullScreen) {
                        window.toggleFullScreen(nil)
                    }
                }
                return nil // Consume the ESC event
            } else if event.keyCode == 51 && self.backspaceService.isBackspaceDisabled { // 51 is the key code for Backspace
                return nil // Consume the backspace event when disabled
            }
            return event
        }
    }
    
    private func updateTimer() {
        if timerIsRunning && timeRemaining > 0 {
            timeRemaining -= 1
        } else if timeRemaining == 0 {
            timerIsRunning = false
            // Keep navbar opaque - no animation needed
            bottomNavOpacity = 1.0
        }
    }
    
    private func saveCurrentEntry() {
        if let currentId = selectedEntryId,
           let currentEntry = entries.first(where: { $0.id == currentId }) {
            _ = fileService.saveEntry(text: text, entry: currentEntry)
            // Update preview text
            if let index = entries.firstIndex(where: { $0.id == currentId }) {
                let previewText = fileService.updatePreviewText(for: currentEntry)
                entries[index].previewText = previewText
            }
        }
    }
    
    private func selectEntry(_ entry: HumanEntry) {
        // Save current entry before switching
        saveCurrentEntry()
        
        selectedEntryId = entry.id
        if let content = fileService.loadEntry(entry: entry) {
            text = content
        }
    }

    
    private func createNewEntry() {
        let newEntry = HumanEntry.createNew()
        entries.insert(newEntry, at: 0)
        selectedEntryId = newEntry.id
        
        if entries.count == 1 {
            // Read welcome message from default.md
            if let defaultMessageURL = Bundle.main.url(forResource: "default", withExtension: "md"),
               let defaultMessage = try? String(contentsOf: defaultMessageURL, encoding: .utf8) {
                text = "\n\n" + defaultMessage
            }
            _ = fileService.saveEntry(text: text, entry: newEntry)
            let previewText = fileService.updatePreviewText(for: newEntry)
            if let index = entries.firstIndex(where: { $0.id == newEntry.id }) {
                entries[index].previewText = previewText
            }
        } else {
            text = ""
            placeholderText = AppSettings.placeholderOptions.randomElement() ?? "Begin writing"
            _ = fileService.saveEntry(text: text, entry: newEntry)
        }
    }
    
    private func deleteEntry(_ entry: HumanEntry) {
        if fileService.deleteEntry(entry: entry) {
            if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                entries.remove(at: index)
                
                // If the deleted entry was selected, select the first entry or create a new one
                if selectedEntryId == entry.id {
                    if let firstEntry = entries.first {
                        selectedEntryId = firstEntry.id
                        if let content = fileService.loadEntry(entry: firstEntry) {
                            text = content
                        }
                    } else {
                        createNewEntry()
                    }
                }
            }
        }
    }
    
    private func exportEntryAsPDF(_ entry: HumanEntry) {
        if let content = fileService.loadEntry(entry: entry) {
            pdfExportService.exportEntryAsPDF(
                entry: entry,
                content: content,
                selectedFont: selectedFont,
                fontSize: fontSize,
                lineHeight: 4.0
            )
        }
    }
    
    private func handleTextChange() {
        let now = Date()
        lastTypingTime = now
        
        // Start timer if not already running and text is not empty
        if !timerIsRunning && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            timerIsRunning = true
        }
        
        // Cancel existing typing timer
        typingTimer?.invalidate()
        
        // Set new timer to stop after 3 seconds of inactivity
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            if self.timerIsRunning {
                self.timerIsRunning = false
            }
        }
    }
}

// MARK: - VoiceAgent Wrapper View

struct VoiceAgentWrapperView: View {
    @ObservedObject var appState: AppState
    let initialContext: String?
    @State private var viewModel = AppViewModel()
    
    var body: some View {
        // VoiceAgent content - no back button, only disconnect via phone down button
        AppView(initialContext: initialContext, appState: appState)
            .environment(viewModel)
    }
}

#Preview {
    ContentView()
}
