//
//  TimelineSheetModifiers.swift
//  Otis-app
//
//  ViewModifier that applies all shared sheet handling to timeline views
//

import SwiftUI
import OtisShared

/// ViewModifier that applies all timeline sheet handling
struct TimelineSheetModifiers: ViewModifier {
    @ObservedObject var viewModel: TimelineViewModel
    @ObservedObject var mediaCaptureViewModel: MediaCaptureViewModel
    @Binding var selectedPhotoEvent: PuppyEvent?
    let reduceMotion: Bool
    var spotStore: SpotStore
    var locationManager: LocationManager

    /// Direct observation of SheetCoordinator to ensure sheet state changes trigger view updates
    @ObservedObject private var sheetCoordinator: SheetCoordinator

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        viewModel: TimelineViewModel,
        mediaCaptureViewModel: MediaCaptureViewModel,
        selectedPhotoEvent: Binding<PuppyEvent?>,
        reduceMotion: Bool,
        spotStore: SpotStore,
        locationManager: LocationManager
    ) {
        self.viewModel = viewModel
        self.mediaCaptureViewModel = mediaCaptureViewModel
        self._selectedPhotoEvent = selectedPhotoEvent
        self.reduceMotion = reduceMotion
        self.spotStore = spotStore
        self.locationManager = locationManager
        self.sheetCoordinator = viewModel.sheetCoordinator
    }

    /// Binding that excludes mediaPicker from sheet presentation (handled by fullScreenCover)
    private var sheetBinding: Binding<SheetCoordinator.ActiveSheet?> {
        Binding(
            get: {
                if case .mediaPicker = sheetCoordinator.activeSheet {
                    return nil  // Don't present as sheet - fullScreenCover handles this
                }
                return sheetCoordinator.activeSheet
            },
            set: { sheetCoordinator.activeSheet = $0 }
        )
    }

    func body(content: Content) -> some View {
        content
            // Single sheet presentation using item-based approach
            // Uses sheetBinding to exclude mediaPicker (handled by fullScreenCover instead)
            .sheet(item: sheetBinding) { sheet in
                sheetContent(for: sheet)
            }
            // Media picker uses fullScreenCover (separate from sheets)
            .fullScreenCover(isPresented: Binding(
                get: { viewModel.sheetCoordinator.isShowingMediaPicker },
                set: { if !$0 { viewModel.dismissMediaPicker() } }
            )) {
                MediaPicker(
                    source: viewModel.mediaPickerSource,
                    onImageSelected: { image, data in
                        mediaCaptureViewModel.processImage(image, originalData: data)
                        viewModel.dismissMediaPicker()
                        viewModel.showLogMomentSheet()
                    },
                    onCancel: {
                        viewModel.dismissMediaPicker()
                    }
                )
            }
            // Media preview (item-based fullScreenCover)
            .fullScreenCover(item: $selectedPhotoEvent) { event in
                MediaPreviewView(
                    event: event,
                    onDelete: {
                        viewModel.deleteEvent(event)
                        selectedPhotoEvent = nil
                    }
                )
            }
            // Delete confirmation dialog
            .confirmationDialog(
                Strings.Timeline.deleteConfirmTitle,
                isPresented: viewModel.showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    viewModel.confirmDeleteEvent()
                }
                Button(Strings.Common.cancel, role: .cancel) {
                    viewModel.cancelDeleteEvent()
                }
            } message: {
                if let event = viewModel.eventToDelete {
                    Text(Strings.Timeline.deleteConfirmMessage(event: event.type.label, time: event.time.timeString))
                }
            }
            // Undo banner overlay
            .overlay(alignment: .bottom) {
                if viewModel.showingUndoBanner {
                    UndoBanner(
                        message: Strings.Timeline.eventDeleted,
                        onUndo: viewModel.undoDelete,
                        onDismiss: viewModel.dismissUndoBanner
                    )
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.showingUndoBanner)
            // Celebration banner overlay (shows above undo banner position)
            .overlay(alignment: .top) {
                if viewModel.showingCelebrationBanner {
                    CelebrationBanner(
                        message: viewModel.celebrationMessage,
                        onDismiss: viewModel.dismissCelebrationBanner
                    )
                    .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                    .padding(.top, 60)
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8), value: viewModel.showingCelebrationBanner)
    }

    // MARK: - Sheet Content Builder

    @ViewBuilder
    private func sheetContent(for sheet: SheetCoordinator.ActiveSheet) -> some View {
        switch sheet {
        case .potty(let preselected):
            PottyQuickLogSheet(
                onSave: viewModel.logPottyEvent,
                onCancel: viewModel.cancelPottySheet,
                preselected: preselected
            )
            .adaptivePresentationDetents(
                compact: [.height(580)],
                regular: [.medium, .large]
            )

        case .allEvents:
            AllEventsSheet(
                onSelect: { type in
                    // Moment events need special handling - show camera/library choice first
                    if type == .moment {
                        viewModel.sheetCoordinator.transitionToSheet(.momentSourcePicker)
                    } else if type == .uitlaten {
                        // Walk: check if activity in progress, otherwise show start/log choice
                        if viewModel.isWalkInProgress {
                            viewModel.sheetCoordinator.transitionToSheet(.endActivity)
                        } else {
                            viewModel.sheetCoordinator.transitionToSheet(.startActivity(.walk))
                        }
                    } else if type == .slapen {
                        // Nap: check if nap in progress, otherwise show start/log choice
                        if viewModel.isNapInProgress {
                            viewModel.sheetCoordinator.transitionToSheet(.endActivity)
                        } else {
                            viewModel.sheetCoordinator.transitionToSheet(.startActivity(.nap))
                        }
                    } else if type == .coverageGap {
                        // Coverage gap: show start or end sheet depending on state
                        if let activeGap = viewModel.activeCoverageGap {
                            viewModel.sheetCoordinator.transitionToSheet(.endCoverageGap(activeGap))
                        } else {
                            viewModel.sheetCoordinator.transitionToSheet(.startCoverageGap)
                        }
                    } else {
                        viewModel.sheetCoordinator.transitionToSheet(.quickLog(type))
                    }
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.fraction(0.75), .large],
                regular: [.medium, .large]
            )

        case .quickLog(let type, let suggestedTime):
            QuickLogSheet(
                eventType: type,
                onSave: viewModel.logFromQuickSheet,
                onCancel: viewModel.cancelQuickLogSheet,
                suggestedTime: suggestedTime,
                spotStore: type == .uitlaten ? spotStore : nil,
                locationManager: type == .uitlaten ? locationManager : nil,
                onSaveWalk: type == .uitlaten ? { time, spot, lat, lon, note in
                    viewModel.logWalkEvent(time: time, spot: spot, latitude: lat, longitude: lon, note: note)
                    viewModel.sheetCoordinator.dismissSheet()
                } : nil
            )
            .adaptivePresentationDetents(
                compact: [type == .uitlaten ? .height(550) : (type.requiresLocation ? .height(480) : .height(380))],
                regular: [.medium, .large]
            )

        case .logEvent(let type):
            LogEventSheet(eventType: type) { note, who, exercise, result, durationMin in
                viewModel.logEvent(
                    type: type,
                    note: note,
                    who: who,
                    exercise: exercise,
                    result: result,
                    durationMin: durationMin
                )
                viewModel.sheetCoordinator.dismissSheet()
            }

        case .locationPicker(let type):
            LocationPickerSheet(
                eventType: type,
                onSelect: viewModel.logWithLocation,
                onCancel: viewModel.cancelLocationPicker
            )
            .adaptivePresentationDetents(
                compact: [.height(200)],
                regular: [.medium]
            )

        case .mediaPicker:
            // Handled by fullScreenCover above, this case shouldn't be reached
            EmptyView()

        case .momentSourcePicker:
            MomentSourcePickerSheet(
                onCamera: {
                    viewModel.openCamera()
                },
                onLibrary: {
                    viewModel.openPhotoLibrary()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.height(200)],
                regular: [.medium]
            )

        case .logMoment:
            LogMomentSheet(
                viewModel: mediaCaptureViewModel,
                onSave: { event in
                    viewModel.addEvent(event)
                    viewModel.dismissLogMomentSheet()
                    mediaCaptureViewModel.reset()
                    HapticFeedback.success()
                },
                onCancel: {
                    viewModel.dismissLogMomentSheet()
                    mediaCaptureViewModel.reset()
                }
            )

        case .otisPlus:
            OtisPlusSheet(
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onSubscribed: {
                    viewModel.sheetCoordinator.transitionToSheet(.subscriptionSuccess)
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .subscriptionSuccess:
            SubscriptionSuccessView(
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.medium],
                regular: [.medium]
            )

        case .editEvent(let event):
            EditEventSheet(
                event: event,
                onSave: { updatedEvent in
                    viewModel.updateEvent(updatedEvent)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onDelete: {
                    viewModel.deleteEvent(event)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                householdMembers: viewModel.profileStore.profile?.householdMembers
            )
            .adaptivePresentationDetents(
                compact: [.medium, .large],
                regular: [.medium, .large]
            )

        case .endSleep(let startTime):
            EndSleepSheet(
                sleepStartTime: startTime,
                onSave: { wakeUpTime in
                    viewModel.logWakeUp(time: wakeUpTime)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.height(420)],
                regular: [.medium]
            )

        case .startActivity(let activityType, let preselectedLocation):
            StartActivitySheet(
                activityType: activityType,
                puppyName: viewModel.puppyName,
                preselectedLocation: preselectedLocation,
                onStartNow: { startTime, napLocation in
                    viewModel.startActivity(type: activityType, startTime: startTime, napLocation: napLocation)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onLogCompleted: {
                    // Transition to specialized sheet for retrospective logging
                    if activityType == .walk {
                        viewModel.sheetCoordinator.transitionToSheet(.walkLog)
                    } else {
                        // Calculate default nap duration from recent events
                        let recentEvents = viewModel.getRecentEvents()
                        let defaultDuration = SleepCalculations.defaultNapDuration(events: recentEvents)
                        viewModel.sheetCoordinator.transitionToSheet(.napLog(defaultDuration: defaultDuration))
                    }
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .endActivity:
            if let activity = viewModel.currentActivity {
                ActivityEndSheet(
                    activity: activity,
                    onEnd: { minutesAgo, note in
                        viewModel.endActivity(minutesAgo: minutesAgo, note: note)
                    },
                    onCancel: {
                        viewModel.sheetCoordinator.dismissSheet()
                    },
                    onDiscard: {
                        viewModel.cancelActivity()
                    }
                )
                .adaptivePresentationDetents(
                    compact: [.height(480)],
                    regular: [.medium]
                )
            } else {
                EmptyView()
            }

        case .walkLog:
            WalkLogSheet(
                onSave: { startTime, duration, didPee, didPoop, spot, note in
                    viewModel.logWalkEvent(
                        time: startTime,
                        durationMin: duration,
                        didPee: didPee,
                        didPoop: didPoop,
                        spot: spot,
                        note: note
                    )
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                },
                spotStore: spotStore,
                locationManager: locationManager
            )
            .adaptivePresentationDetents(
                compact: [.height(520), .large],
                regular: [.medium, .large]
            )

        case .napLog(let defaultDuration):
            NapLogSheet(
                onSave: { startTime, endTime, note, napLocation in
                    viewModel.logCompletedNap(startTime: startTime, endTime: endTime, note: note, napLocation: napLocation)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                },
                defaultDurationMinutes: defaultDuration
            )
            .adaptivePresentationDetents(
                compact: [.height(520), .medium],
                regular: [.medium, .large]
            )

        case .startCoverageGap:
            StartCoverageGapSheet(
                onSave: { gapType, startTime, location, note in
                    viewModel.startCoverageGap(type: gapType, startTime: startTime, location: location, note: note)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .endCoverageGap(let gap):
            EndCoverageGapSheet(
                gap: gap,
                onEnd: { endTime, note in
                    viewModel.endCoverageGap(gap, endTime: endTime, note: note)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onCancel: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.height(450)],
                regular: [.medium]
            )

        case .gapDetection(let hours, let puppyName, let suggestedStartTime):
            GapDetectionSheet(
                hours: hours,
                puppyName: puppyName,
                suggestedStartTime: suggestedStartTime,
                onLogCoverage: {
                    // Transition to start coverage gap sheet
                    viewModel.sheetCoordinator.transitionToSheet(.startCoverageGap)
                },
                onDismiss: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.medium],
                regular: [.medium]
            )

        case .catchUp(let hours, let puppyName, let context):
            CatchUpSheet(
                puppyName: puppyName,
                hoursSinceLastEvent: hours,
                context: context,
                onComplete: { result in
                    viewModel.processCatchUpResult(result)
                    viewModel.sheetCoordinator.dismissSheet()
                },
                onSkip: {
                    viewModel.sheetCoordinator.dismissSheet()
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        // Placeholder cases for future sheets (handled elsewhere or not yet implemented)
        case .weightLog, .trainingLog, .socializationLog, .settings, .profileEdit, .notificationSettings:
            EmptyView()

        // Canonical sheets (single sources of truth)
        case .developmentJourney:
            DevelopmentJourneySheet(
                onNavigateToSocialization: {
                    viewModel.sheetCoordinator.presentSheet(.socializationWindow)
                },
                onNavigateToMedical: {
                    viewModel.sheetCoordinator.presentSheet(.medicalCare)
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .socializationWindow:
            SocializationWindowSheet(
                onNavigateToDevelopment: {
                    viewModel.sheetCoordinator.presentSheet(.developmentJourney)
                },
                onLogExposure: {
                    viewModel.sheetCoordinator.presentSheet(.socializationLog)
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .medicalCare:
            MedicalCareSheet(
                onNavigateToDevelopment: {
                    viewModel.sheetCoordinator.presentSheet(.developmentJourney)
                },
                onSelectMilestone: { milestone in
                    // The milestone completion sheet is handled separately in HealthTabView
                    // For now, just dismiss - the parent view will handle the selection
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .fullTimeline:
            FullTimelineSheet(
                viewModel: viewModel,
                onEditEvent: { event in
                    viewModel.editEvent(event)
                },
                onDeleteEvent: { event in
                    viewModel.deleteEvent(event)
                },
                onPhotoTap: { event in
                    selectedPhotoEvent = event
                }
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .walkScheduleEditor:
            if let profile = viewModel.profileStore.profile {
                WalkScheduleEditor(
                    initialSchedule: profile.walkSchedule,
                    ageInMonths: profile.ageInMonths,
                    onSave: { newSchedule in
                        viewModel.profileStore.updateWalkSchedule(newSchedule)
                        viewModel.sheetCoordinator.dismissSheet()
                    }
                )
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            } else {
                // Fallback if no profile (shouldn't happen in practice)
                Text("Profile not available")
            }

        case .crateTrainingGuide:
            CrateTrainingGuideSheet(eventStore: viewModel.eventStore)
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )

        case .pottyTrainingGuide:
            PottyTrainingGuideSheet(
                streakInfo: viewModel.streakInfo,
                patternAnalysis: viewModel.patternAnalysis,
                outdoorPercentage: viewModel.outdoorPercentage,
                ageInWeeks: viewModel.profileStore.profile?.ageInWeeks ?? 12,
                shouldShowIncidentMessage: viewModel.shouldShowPottyIncidentMessage,
                shouldShowReactivationPrompt: viewModel.shouldShowPottyReactivationPrompt,
                incidentCount: viewModel.incidentsSincePottyMastery.count
            )
            .adaptivePresentationDetents(
                compact: [.large],
                regular: [.medium, .large]
            )

        case .addAppointmentWithPrefill(let prefill):
            if let appointmentStore = viewModel.appointmentStore {
                AddEditAppointmentSheet(
                    appointmentStore: appointmentStore,
                    prefill: prefill
                )
                .adaptivePresentationDetents(
                    compact: [.large],
                    regular: [.medium, .large]
                )
            } else {
                // Fallback if no appointment store (shouldn't happen in practice)
                Text("Appointment store not available")
            }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies all timeline sheet handling modifiers
    func timelineSheetHandling(
        viewModel: TimelineViewModel,
        mediaCaptureViewModel: MediaCaptureViewModel,
        selectedPhotoEvent: Binding<PuppyEvent?>,
        reduceMotion: Bool,
        spotStore: SpotStore,
        locationManager: LocationManager
    ) -> some View {
        modifier(TimelineSheetModifiers(
            viewModel: viewModel,
            mediaCaptureViewModel: mediaCaptureViewModel,
            selectedPhotoEvent: selectedPhotoEvent,
            reduceMotion: reduceMotion,
            spotStore: spotStore,
            locationManager: locationManager
        ))
    }
}
