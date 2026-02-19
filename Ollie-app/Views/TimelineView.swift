//
//  TimelineView.swift
//  Ollie-app
//

import SwiftUI

struct TimelineView: View {
    @State private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timeline content
                if viewModel.events.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    eventList
                }

                // Quick log bar
                QuickLogBar { type in
                    viewModel.quickLog(type)
                }
            }
            .navigationTitle(viewModel.displayDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.goToPreviousDay()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if !viewModel.isToday {
                            Button("Vandaag") {
                                viewModel.goToToday()
                            }
                            .font(.subheadline)
                        }

                        Button {
                            viewModel.goToNextDay()
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(viewModel.isToday)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingLocationPicker) {
                if let type = viewModel.pendingEventType {
                    LocationPickerSheet(
                        eventType: type,
                        onSelect: { location in
                            viewModel.logWithLocation(location)
                        },
                        onCancel: {
                            viewModel.cancelLocationPicker()
                        }
                    )
                }
            }
        }
    }

    private var eventList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.events) { event in
                        EventRow(event: event)
                            .id(event.id)
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: viewModel.events.count) {
                // Scroll to bottom when new event is added
                if let lastEvent = viewModel.events.last {
                    withAnimation {
                        proxy.scrollTo(lastEvent.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "pawprint")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nog geen gebeurtenissen")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Tik op een knop hieronder om te beginnen")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }
}

#Preview {
    TimelineView()
}
