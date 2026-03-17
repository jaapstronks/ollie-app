//
//  Strings+Health.swift
//  OtisShared
//
//  Health tracking, conditions, symptoms, allergies, and senior wellness strings.
//

import Foundation

extension Strings {
    // MARK: - Health
    public enum Health {
        public static var title: String { String(localized: "Health", bundle: Strings.bundle) }
        public static var weight: String { String(localized: "Weight", bundle: Strings.bundle) }
        public static var milestones: String { String(localized: "Milestones", bundle: Strings.bundle) }
        public static var noWeightData: String { String(localized: "No weight data yet", bundle: Strings.bundle) }
        public static var logFirstWeight: String { String(localized: "Log your first weight measurement", bundle: Strings.bundle) }
        public static var logWeight: String { String(localized: "Log weight", bundle: Strings.bundle) }
        public static var currentWeight: String { String(localized: "Current weight", bundle: Strings.bundle) }
        public static var growthCurve: String { String(localized: "Growth curve", bundle: Strings.bundle) }
        public static var referenceRange: String { String(localized: "Reference range", bundle: Strings.bundle) }
        public static var weightOnTrack: String { String(localized: "On track", bundle: Strings.bundle) }
        public static var weightAboveReference: String { String(localized: "Above reference", bundle: Strings.bundle) }
        public static var weightBelowReference: String { String(localized: "Below reference", bundle: Strings.bundle) }
        public static func sinceLast(_ delta: String) -> String {
            String(localized: "\(delta) since last", bundle: Strings.bundle)
        }
        public static func sincePrevious(_ delta: String, date: String) -> String {
            String(localized: "\(delta) since \(date)", bundle: Strings.bundle)
        }
        public static var weeks: String { String(localized: "Weeks", bundle: Strings.bundle) }
        public static var kg: String { String(localized: "kg", bundle: Strings.bundle) }
        public static func yourPet(isPuppy: Bool) -> String {
            isPuppy
                ? String(localized: "Your puppy", bundle: Strings.bundle)
                : String(localized: "Your dog", bundle: Strings.bundle)
        }
        /// Legacy static version for backward compatibility
        public static var yourPuppy: String { String(localized: "Your puppy", bundle: Strings.bundle) }
        public static var reference: String { String(localized: "Reference", bundle: Strings.bundle) }
        public static var done: String { String(localized: "Done", bundle: Strings.bundle) }
        public static var nextUp: String { String(localized: "Next up", bundle: Strings.bundle) }
        public static var future: String { String(localized: "Upcoming", bundle: Strings.bundle) }
        public static var overdue: String { String(localized: "Overdue", bundle: Strings.bundle) }
        public static var firstDewormingBreeder: String { String(localized: "First deworming (breeder)", bundle: Strings.bundle) }
        public static var firstVaccination: String { String(localized: "First vaccination (DHP + Lepto)", bundle: Strings.bundle) }
        public static var firstVetVisit: String { String(localized: "First vet visit", bundle: Strings.bundle) }
        public static var firstDewormingHome: String { String(localized: "First deworming (home)", bundle: Strings.bundle) }
        public static var secondVaccination: String { String(localized: "Second vaccination (DHP + Lepto + Rabies)", bundle: Strings.bundle) }
        public static var thirdVaccination: String { String(localized: "Third vaccination (cocktail)", bundle: Strings.bundle) }
        public static var neuteredDiscussion: String { String(localized: "Spay/neuter discussion with vet", bundle: Strings.bundle) }
        public static var yearlyVaccination: String { String(localized: "Yearly vaccination", bundle: Strings.bundle) }
        public static func weekNumber(_ week: Int) -> String {
            String(localized: "Week \(week)", bundle: Strings.bundle)
        }
        public static func monthNumber(_ month: Int) -> String {
            String(localized: "\(month) months", bundle: Strings.bundle)
        }
        public static var weightKg: String { String(localized: "Weight (kg)", bundle: Strings.bundle) }
        public static var enterWeight: String { String(localized: "Enter weight", bundle: Strings.bundle) }
        public static var weightPlaceholder: String { String(localized: "e.g. 8.5", bundle: Strings.bundle) }
    }

    // MARK: - Health Conditions
    /// Strings for health condition tracking
    public enum HealthConditions {
        // Categories
        public static var categoryAllergyImmune: String { String(localized: "Allergies & Immune", bundle: Strings.bundle) }
        public static var categoryMusculoskeletal: String { String(localized: "Joints & Mobility", bundle: Strings.bundle) }
        public static var categoryEndocrine: String { String(localized: "Hormonal", bundle: Strings.bundle) }
        public static var categoryCardiac: String { String(localized: "Heart", bundle: Strings.bundle) }
        public static var categoryNeurological: String { String(localized: "Neurological", bundle: Strings.bundle) }
        public static var categoryDigestive: String { String(localized: "Digestive", bundle: Strings.bundle) }
        public static var categoryUrinary: String { String(localized: "Kidney & Urinary", bundle: Strings.bundle) }
        public static var categoryRespiratory: String { String(localized: "Respiratory", bundle: Strings.bundle) }
        public static var categoryEye: String { String(localized: "Eyes", bundle: Strings.bundle) }
        public static var categoryEar: String { String(localized: "Ears", bundle: Strings.bundle) }
        public static var categorySkin: String { String(localized: "Skin", bundle: Strings.bundle) }
        public static var categoryCognitive: String { String(localized: "Cognitive", bundle: Strings.bundle) }
        public static var categoryCancer: String { String(localized: "Cancer", bundle: Strings.bundle) }
        public static var categoryOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Condition types - Allergies & Immune
        public static var foodAllergy: String { String(localized: "Food Allergy", bundle: Strings.bundle) }
        public static var environmentalAllergy: String { String(localized: "Environmental Allergy", bundle: Strings.bundle) }
        public static var atopicDermatitis: String { String(localized: "Atopic Dermatitis", bundle: Strings.bundle) }
        public static var autoimmune: String { String(localized: "Autoimmune Disease", bundle: Strings.bundle) }

        // Condition types - Musculoskeletal
        public static var hipDysplasia: String { String(localized: "Hip Dysplasia", bundle: Strings.bundle) }
        public static var elbowDysplasia: String { String(localized: "Elbow Dysplasia", bundle: Strings.bundle) }
        public static var arthritis: String { String(localized: "Arthritis", bundle: Strings.bundle) }
        public static var luxatingPatella: String { String(localized: "Luxating Patella", bundle: Strings.bundle) }
        public static var ivdd: String { String(localized: "IVDD (Disc Disease)", bundle: Strings.bundle) }

        // Condition types - Endocrine
        public static var diabetes: String { String(localized: "Diabetes", bundle: Strings.bundle) }
        public static var hypothyroidism: String { String(localized: "Hypothyroidism", bundle: Strings.bundle) }
        public static var hyperthyroidism: String { String(localized: "Hyperthyroidism", bundle: Strings.bundle) }
        public static var cushings: String { String(localized: "Cushing's Disease", bundle: Strings.bundle) }
        public static var addisons: String { String(localized: "Addison's Disease", bundle: Strings.bundle) }

        // Condition types - Cardiac
        public static var heartMurmur: String { String(localized: "Heart Murmur", bundle: Strings.bundle) }
        public static var dilatedCardiomyopathy: String { String(localized: "Dilated Cardiomyopathy", bundle: Strings.bundle) }
        public static var mitralValveDisease: String { String(localized: "Mitral Valve Disease", bundle: Strings.bundle) }
        public static var congestiveHeartFailure: String { String(localized: "Congestive Heart Failure", bundle: Strings.bundle) }

        // Condition types - Neurological
        public static var epilepsy: String { String(localized: "Epilepsy", bundle: Strings.bundle) }
        public static var vestibularDisease: String { String(localized: "Vestibular Disease", bundle: Strings.bundle) }
        public static var degenerativeMyelopathy: String { String(localized: "Degenerative Myelopathy", bundle: Strings.bundle) }

        // Condition types - Digestive
        public static var ibd: String { String(localized: "Inflammatory Bowel Disease", bundle: Strings.bundle) }
        public static var pancreatitis: String { String(localized: "Pancreatitis", bundle: Strings.bundle) }
        public static var megaesophagus: String { String(localized: "Megaesophagus", bundle: Strings.bundle) }
        public static var exocrinePancreaticInsufficiency: String { String(localized: "Exocrine Pancreatic Insufficiency", bundle: Strings.bundle) }

        // Condition types - Urinary/Renal
        public static var chronicKidneyDisease: String { String(localized: "Chronic Kidney Disease", bundle: Strings.bundle) }
        public static var bladderStones: String { String(localized: "Bladder Stones", bundle: Strings.bundle) }
        public static var incontinence: String { String(localized: "Incontinence", bundle: Strings.bundle) }

        // Condition types - Respiratory
        public static var collapsedTrachea: String { String(localized: "Collapsed Trachea", bundle: Strings.bundle) }
        public static var laryngealParalysis: String { String(localized: "Laryngeal Paralysis", bundle: Strings.bundle) }
        public static var brachycephalicSyndrome: String { String(localized: "Brachycephalic Syndrome", bundle: Strings.bundle) }

        // Condition types - Eye
        public static var cataracts: String { String(localized: "Cataracts", bundle: Strings.bundle) }
        public static var glaucoma: String { String(localized: "Glaucoma", bundle: Strings.bundle) }
        public static var progressiveRetinalAtrophy: String { String(localized: "Progressive Retinal Atrophy", bundle: Strings.bundle) }
        public static var dryEye: String { String(localized: "Dry Eye (KCS)", bundle: Strings.bundle) }

        // Condition types - Ear
        public static var chronicOtitis: String { String(localized: "Chronic Ear Infections", bundle: Strings.bundle) }

        // Condition types - Skin
        public static var demodeticMange: String { String(localized: "Demodectic Mange", bundle: Strings.bundle) }
        public static var sebaceousAdenitis: String { String(localized: "Sebaceous Adenitis", bundle: Strings.bundle) }

        // Condition types - Cancer
        public static var mastCellTumor: String { String(localized: "Mast Cell Tumor", bundle: Strings.bundle) }
        public static var lymphoma: String { String(localized: "Lymphoma", bundle: Strings.bundle) }
        public static var osteosarcoma: String { String(localized: "Osteosarcoma", bundle: Strings.bundle) }
        public static var hemangiosarcoma: String { String(localized: "Hemangiosarcoma", bundle: Strings.bundle) }

        // Condition types - Cognitive
        public static var canineCognitiveDysfunction: String { String(localized: "Cognitive Dysfunction", bundle: Strings.bundle) }

        // Other
        public static var otherCondition: String { String(localized: "Other Condition", bundle: Strings.bundle) }

        // Severity levels
        public static var severityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }
        public static var severityManaged: String { String(localized: "Managed", bundle: Strings.bundle) }

        // Status
        public static var statusActive: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var statusMonitoring: String { String(localized: "Monitoring", bundle: Strings.bundle) }
        public static var statusResolved: String { String(localized: "Resolved", bundle: Strings.bundle) }
        public static var statusRemission: String { String(localized: "In Remission", bundle: Strings.bundle) }

        // Monitoring frequency
        public static var frequencyDaily: String { String(localized: "Daily", bundle: Strings.bundle) }
        public static var frequencyWeekly: String { String(localized: "Weekly", bundle: Strings.bundle) }
        public static var frequencyBiweekly: String { String(localized: "Every 2 weeks", bundle: Strings.bundle) }
        public static var frequencyMonthly: String { String(localized: "Monthly", bundle: Strings.bundle) }
        public static var frequencyQuarterly: String { String(localized: "Every 3 months", bundle: Strings.bundle) }

        // Risk levels
        public static var riskLow: String { String(localized: "Low Risk", bundle: Strings.bundle) }
        public static var riskModerate: String { String(localized: "Moderate Risk", bundle: Strings.bundle) }
        public static var riskHigh: String { String(localized: "High Risk", bundle: Strings.bundle) }
        public static var riskVeryHigh: String { String(localized: "Very High Risk", bundle: Strings.bundle) }

        // Warning signals
        public static var warningBreathingRate: String { String(localized: "Resting respiratory rate >30 breaths/min", bundle: Strings.bundle) }
        public static var warningNightCoughing: String { String(localized: "Coughing at night", bundle: Strings.bundle) }
        public static var warningPaleGums: String { String(localized: "Blue or pale gums", bundle: Strings.bundle) }
        public static var warningCollapse: String { String(localized: "Collapse or fainting", bundle: Strings.bundle) }
        public static var warningSuddenLethargy: String { String(localized: "Sudden lethargy or weakness", bundle: Strings.bundle) }
        public static var warningVomiting: String { String(localized: "Vomiting", bundle: Strings.bundle) }
        public static var warningSweetBreath: String { String(localized: "Sweet or fruity breath", bundle: Strings.bundle) }
        public static var warningDisorientation: String { String(localized: "Disorientation", bundle: Strings.bundle) }
        public static var warningClusterSeizures: String { String(localized: "Cluster seizures (2+ in 24 hours)", bundle: Strings.bundle) }
        public static var warningLongSeizure: String { String(localized: "Seizure lasting >5 minutes", bundle: Strings.bundle) }
        public static var warningNoRecovery: String { String(localized: "Not recovering between seizures", bundle: Strings.bundle) }
        public static var warningNotEating: String { String(localized: "Not eating for 24+ hours", bundle: Strings.bundle) }
        public static var warningWeakness: String { String(localized: "Weakness or lethargy", bundle: Strings.bundle) }
        public static var warningBadBreath: String { String(localized: "Ammonia-like breath", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Health Conditions", bundle: Strings.bundle) }
        public static var addCondition: String { String(localized: "Add Condition", bundle: Strings.bundle) }
        public static var editCondition: String { String(localized: "Edit Condition", bundle: Strings.bundle) }
        public static var noConditions: String { String(localized: "No health conditions", bundle: Strings.bundle) }
        public static var noConditionsHint: String { String(localized: "Tap to add diagnosed conditions", bundle: Strings.bundle) }
        public static var diagnosedDate: String { String(localized: "Diagnosed", bundle: Strings.bundle) }
        public static var severity: String { String(localized: "Severity", bundle: Strings.bundle) }
        public static var status: String { String(localized: "Status", bundle: Strings.bundle) }
        public static var monitoringFrequency: String { String(localized: "Check-in frequency", bundle: Strings.bundle) }
        public static var vetRecommendations: String { String(localized: "Vet recommendations", bundle: Strings.bundle) }
        public static var linkedMedications: String { String(localized: "Linked medications", bundle: Strings.bundle) }
        public static var breedRelated: String { String(localized: "Breed-related", bundle: Strings.bundle) }
        public static var isGenetic: String { String(localized: "Genetic", bundle: Strings.bundle) }
        public static var needsReview: String { String(localized: "Needs review", bundle: Strings.bundle) }
        public static var lastReviewed: String { String(localized: "Last reviewed", bundle: Strings.bundle) }
        public static var markReviewed: String { String(localized: "Mark as reviewed", bundle: Strings.bundle) }
        public static var customName: String { String(localized: "Condition name", bundle: Strings.bundle) }
        public static var customNamePlaceholder: String { String(localized: "Enter condition name", bundle: Strings.bundle) }
    }

    // MARK: - Symptoms
    /// Strings for symptom tracking
    public enum Symptoms {
        // Categories
        public static var categoryMobility: String { String(localized: "Mobility", bundle: Strings.bundle) }
        public static var categoryNeurological: String { String(localized: "Neurological", bundle: Strings.bundle) }
        public static var categoryRespiratory: String { String(localized: "Respiratory", bundle: Strings.bundle) }
        public static var categoryDigestive: String { String(localized: "Digestive", bundle: Strings.bundle) }
        public static var categoryUrinary: String { String(localized: "Urinary", bundle: Strings.bundle) }
        public static var categorySkin: String { String(localized: "Skin & Coat", bundle: Strings.bundle) }
        public static var categoryEyes: String { String(localized: "Eyes", bundle: Strings.bundle) }
        public static var categoryEars: String { String(localized: "Ears", bundle: Strings.bundle) }
        public static var categoryGeneral: String { String(localized: "General", bundle: Strings.bundle) }
        public static var categoryBehavioral: String { String(localized: "Behavioral", bundle: Strings.bundle) }
        public static var categoryOther: String { String(localized: "Other", bundle: Strings.bundle) }

        // Urgency levels
        public static var urgencyEmergency: String { String(localized: "Emergency - Vet NOW", bundle: Strings.bundle) }
        public static var urgencySoon: String { String(localized: "See vet if persists", bundle: Strings.bundle) }
        public static var urgencyMonitor: String { String(localized: "Monitor and track", bundle: Strings.bundle) }

        // Mobility symptoms
        public static var limping: String { String(localized: "Limping", bundle: Strings.bundle) }
        public static var stiffness: String { String(localized: "Stiffness", bundle: Strings.bundle) }
        public static var difficultyRising: String { String(localized: "Difficulty rising", bundle: Strings.bundle) }
        public static var reluctanceToClimb: String { String(localized: "Reluctance to climb", bundle: Strings.bundle) }
        public static var bunnyHopping: String { String(localized: "Bunny hopping", bundle: Strings.bundle) }
        public static var lamenessRearLegs: String { String(localized: "Rear leg lameness", bundle: Strings.bundle) }
        public static var lamenessFrontLegs: String { String(localized: "Front leg lameness", bundle: Strings.bundle) }

        // Neurological symptoms
        public static var seizure: String { String(localized: "Seizure", bundle: Strings.bundle) }
        public static var trembling: String { String(localized: "Trembling", bundle: Strings.bundle) }
        public static var headTilt: String { String(localized: "Head tilt", bundle: Strings.bundle) }
        public static var circling: String { String(localized: "Circling", bundle: Strings.bundle) }
        public static var confusion: String { String(localized: "Confusion", bundle: Strings.bundle) }
        public static var disorientation: String { String(localized: "Disorientation", bundle: Strings.bundle) }
        public static var lossOfBalance: String { String(localized: "Loss of balance", bundle: Strings.bundle) }

        // Respiratory symptoms
        public static var coughing: String { String(localized: "Coughing", bundle: Strings.bundle) }
        public static var breathingDifficulty: String { String(localized: "Breathing difficulty", bundle: Strings.bundle) }
        public static var rapidBreathing: String { String(localized: "Rapid breathing", bundle: Strings.bundle) }
        public static var reverseSneezing: String { String(localized: "Reverse sneezing", bundle: Strings.bundle) }
        public static var wheezing: String { String(localized: "Wheezing", bundle: Strings.bundle) }

        // Digestive symptoms
        public static var vomiting: String { String(localized: "Vomiting", bundle: Strings.bundle) }
        public static var diarrhea: String { String(localized: "Diarrhea", bundle: Strings.bundle) }
        public static var constipation: String { String(localized: "Constipation", bundle: Strings.bundle) }
        public static var bloating: String { String(localized: "Bloating", bundle: Strings.bundle) }
        public static var appetiteLoss: String { String(localized: "Loss of appetite", bundle: Strings.bundle) }
        public static var excessiveGas: String { String(localized: "Excessive gas", bundle: Strings.bundle) }

        // Urinary symptoms
        public static var frequentUrination: String { String(localized: "Frequent urination", bundle: Strings.bundle) }
        public static var difficultyUrinating: String { String(localized: "Difficulty urinating", bundle: Strings.bundle) }
        public static var bloodInUrine: String { String(localized: "Blood in urine", bundle: Strings.bundle) }
        public static var accidents: String { String(localized: "Accidents in house", bundle: Strings.bundle) }

        // Skin symptoms
        public static var itching: String { String(localized: "Itching/Scratching", bundle: Strings.bundle) }
        public static var hotSpots: String { String(localized: "Hot spots", bundle: Strings.bundle) }
        public static var hairLoss: String { String(localized: "Hair loss", bundle: Strings.bundle) }
        public static var rash: String { String(localized: "Rash", bundle: Strings.bundle) }
        public static var dryCoat: String { String(localized: "Dry coat", bundle: Strings.bundle) }
        public static var excessiveShedding: String { String(localized: "Excessive shedding", bundle: Strings.bundle) }
        public static var pawLicking: String { String(localized: "Paw licking", bundle: Strings.bundle) }
        public static var faceRubbing: String { String(localized: "Face rubbing", bundle: Strings.bundle) }

        // Eye symptoms
        public static var eyeDischarge: String { String(localized: "Eye discharge", bundle: Strings.bundle) }
        public static var eyeRedness: String { String(localized: "Eye redness", bundle: Strings.bundle) }
        public static var cloudiness: String { String(localized: "Cloudiness in eye", bundle: Strings.bundle) }
        public static var squinting: String { String(localized: "Squinting", bundle: Strings.bundle) }
        public static var bumpingIntoThings: String { String(localized: "Bumping into things", bundle: Strings.bundle) }

        // Ear symptoms
        public static var earInfection: String { String(localized: "Ear infection signs", bundle: Strings.bundle) }
        public static var headShaking: String { String(localized: "Head shaking", bundle: Strings.bundle) }
        public static var earOdor: String { String(localized: "Ear odor", bundle: Strings.bundle) }
        public static var scratching: String { String(localized: "Ear scratching", bundle: Strings.bundle) }

        // General symptoms
        public static var lethargy: String { String(localized: "Lethargy", bundle: Strings.bundle) }
        public static var weakness: String { String(localized: "Weakness", bundle: Strings.bundle) }
        public static var weightLoss: String { String(localized: "Weight loss", bundle: Strings.bundle) }
        public static var weightGain: String { String(localized: "Weight gain", bundle: Strings.bundle) }
        public static var excessiveThirst: String { String(localized: "Excessive thirst", bundle: Strings.bundle) }
        public static var drooling: String { String(localized: "Drooling", bundle: Strings.bundle) }
        public static var badBreath: String { String(localized: "Bad breath", bundle: Strings.bundle) }
        public static var fainting: String { String(localized: "Fainting", bundle: Strings.bundle) }
        public static var exerciseIntolerance: String { String(localized: "Exercise intolerance", bundle: Strings.bundle) }
        public static var restlessness: String { String(localized: "Restlessness", bundle: Strings.bundle) }
        public static var panting: String { String(localized: "Excessive panting", bundle: Strings.bundle) }

        // Behavioral symptoms
        public static var anxiety: String { String(localized: "Anxiety", bundle: Strings.bundle) }
        public static var aggression: String { String(localized: "Aggression", bundle: Strings.bundle) }
        public static var hiding: String { String(localized: "Hiding", bundle: Strings.bundle) }
        public static var vocalization: String { String(localized: "Excessive vocalization", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Log Symptom", bundle: Strings.bundle) }
        public static var selectSymptom: String { String(localized: "Select symptom", bundle: Strings.bundle) }
        public static var symptomHistory: String { String(localized: "Symptom History", bundle: Strings.bundle) }
        public static var noSymptoms: String { String(localized: "No symptoms logged", bundle: Strings.bundle) }
    }

    // MARK: - Health Logging
    /// Strings for health logging features
    public enum HealthLogging {
        // Body Locations
        public static var bodyFrontLeftLeg: String { String(localized: "Front left leg", bundle: Strings.bundle) }
        public static var bodyFrontRightLeg: String { String(localized: "Front right leg", bundle: Strings.bundle) }
        public static var bodyRearLeftLeg: String { String(localized: "Rear left leg", bundle: Strings.bundle) }
        public static var bodyRearRightLeg: String { String(localized: "Rear right leg", bundle: Strings.bundle) }
        public static var bodyHead: String { String(localized: "Head", bundle: Strings.bundle) }
        public static var bodyNeck: String { String(localized: "Neck", bundle: Strings.bundle) }
        public static var bodyChest: String { String(localized: "Chest", bundle: Strings.bundle) }
        public static var bodyBack: String { String(localized: "Back", bundle: Strings.bundle) }
        public static var bodyAbdomen: String { String(localized: "Abdomen/Belly", bundle: Strings.bundle) }
        public static var bodyTail: String { String(localized: "Tail", bundle: Strings.bundle) }
        public static var bodyLeftEar: String { String(localized: "Left ear", bundle: Strings.bundle) }
        public static var bodyRightEar: String { String(localized: "Right ear", bundle: Strings.bundle) }
        public static var bodyLeftEye: String { String(localized: "Left eye", bundle: Strings.bundle) }
        public static var bodyRightEye: String { String(localized: "Right eye", bundle: Strings.bundle) }
        public static var bodyFrontLeftPaw: String { String(localized: "Front left paw", bundle: Strings.bundle) }
        public static var bodyFrontRightPaw: String { String(localized: "Front right paw", bundle: Strings.bundle) }
        public static var bodyRearLeftPaw: String { String(localized: "Rear left paw", bundle: Strings.bundle) }
        public static var bodyRearRightPaw: String { String(localized: "Rear right paw", bundle: Strings.bundle) }
        public static var bodyWholeBody: String { String(localized: "Whole body", bundle: Strings.bundle) }
        public static var bodyUnspecified: String { String(localized: "Not specified", bundle: Strings.bundle) }

        // Body location groups
        public static var groupLegs: String { String(localized: "Legs", bundle: Strings.bundle) }
        public static var groupPaws: String { String(localized: "Paws", bundle: Strings.bundle) }
        public static var groupEars: String { String(localized: "Ears", bundle: Strings.bundle) }
        public static var groupEyes: String { String(localized: "Eyes", bundle: Strings.bundle) }
        public static var groupBody: String { String(localized: "Body", bundle: Strings.bundle) }
        public static var groupGeneral: String { String(localized: "General", bundle: Strings.bundle) }

        // Duration
        public static var durationBrief: String { String(localized: "Brief (< 15 min)", bundle: Strings.bundle) }
        public static var durationShortTerm: String { String(localized: "15 min - 2 hours", bundle: Strings.bundle) }
        public static var durationHours: String { String(localized: "Several hours", bundle: Strings.bundle) }
        public static var durationDays: String { String(localized: "Multiple days", bundle: Strings.bundle) }
        public static var durationOngoing: String { String(localized: "Ongoing", bundle: Strings.bundle) }
        public static var durationResolved: String { String(localized: "Resolved", bundle: Strings.bundle) }

        // Status
        public static var statusActive: String { String(localized: "Active", bundle: Strings.bundle) }
        public static var statusResolved: String { String(localized: "Resolved", bundle: Strings.bundle) }
        public static var statusRecurring: String { String(localized: "Recurring", bundle: Strings.bundle) }

        // Start Time
        public static var startJustNow: String { String(localized: "Just now", bundle: Strings.bundle) }
        public static var startEarlierToday: String { String(localized: "Earlier today", bundle: Strings.bundle) }
        public static var startYesterday: String { String(localized: "Yesterday", bundle: Strings.bundle) }
        public static var startBeenOngoing: String { String(localized: "Been ongoing", bundle: Strings.bundle) }

        // Triggers
        public static var triggerAfterWalk: String { String(localized: "After walk", bundle: Strings.bundle) }
        public static var triggerAfterEating: String { String(localized: "After eating", bundle: Strings.bundle) }
        public static var triggerAfterWaking: String { String(localized: "After waking", bundle: Strings.bundle) }
        public static var triggerColdWeather: String { String(localized: "Cold weather", bundle: Strings.bundle) }
        public static var triggerHotWeather: String { String(localized: "Hot weather", bundle: Strings.bundle) }
        public static var triggerStress: String { String(localized: "Stress", bundle: Strings.bundle) }
        public static var triggerExercise: String { String(localized: "Exercise", bundle: Strings.bundle) }
        public static var triggerNewFood: String { String(localized: "New food", bundle: Strings.bundle) }
        public static var triggerMedication: String { String(localized: "Medication", bundle: Strings.bundle) }

        // Trend
        public static var trendImproving: String { String(localized: "Improving", bundle: Strings.bundle) }
        public static var trendStable: String { String(localized: "Stable", bundle: Strings.bundle) }
        public static var trendWorsening: String { String(localized: "Worsening", bundle: Strings.bundle) }

        // Severity
        public static var severityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var severityMildModerate: String { String(localized: "Mild-Moderate", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var severityModSevere: String { String(localized: "Moderate-Severe", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }

        // Health Check-In Categories
        public static var checkInMobility: String { String(localized: "Mobility", bundle: Strings.bundle) }
        public static var checkInEnergy: String { String(localized: "Energy Level", bundle: Strings.bundle) }
        public static var checkInAppetite: String { String(localized: "Appetite", bundle: Strings.bundle) }
        public static var checkInBreathing: String { String(localized: "Breathing", bundle: Strings.bundle) }
        public static var checkInComfort: String { String(localized: "Comfort", bundle: Strings.bundle) }
        public static var checkInCognition: String { String(localized: "Alertness", bundle: Strings.bundle) }
        public static var checkInSkin: String { String(localized: "Skin/Coat", bundle: Strings.bundle) }
        public static var checkInDigestion: String { String(localized: "Digestion", bundle: Strings.bundle) }
        public static var checkInVision: String { String(localized: "Vision", bundle: Strings.bundle) }
        public static var checkInHearing: String { String(localized: "Hearing", bundle: Strings.bundle) }
        public static var checkInOverall: String { String(localized: "Overall", bundle: Strings.bundle) }

        // Check-In Questions
        public static func questionMobility(name: String) -> String {
            String(localized: "How is \(name)'s mobility today?", bundle: Strings.bundle)
        }
        public static func questionEnergy(name: String) -> String {
            String(localized: "How is \(name)'s energy level?", bundle: Strings.bundle)
        }
        public static func questionAppetite(name: String) -> String {
            String(localized: "How is \(name)'s appetite?", bundle: Strings.bundle)
        }
        public static func questionBreathing(name: String) -> String {
            String(localized: "How is \(name)'s breathing?", bundle: Strings.bundle)
        }
        public static func questionComfort(name: String) -> String {
            String(localized: "How comfortable does \(name) seem?", bundle: Strings.bundle)
        }
        public static func questionCognition(name: String) -> String {
            String(localized: "How alert is \(name) today?", bundle: Strings.bundle)
        }
        public static func questionSkin(name: String) -> String {
            String(localized: "How is \(name)'s skin/itching?", bundle: Strings.bundle)
        }
        public static func questionDigestion(name: String) -> String {
            String(localized: "How is \(name)'s digestion?", bundle: Strings.bundle)
        }
        public static func questionVision(name: String) -> String {
            String(localized: "How is \(name)'s vision?", bundle: Strings.bundle)
        }
        public static func questionHearing(name: String) -> String {
            String(localized: "How does \(name) respond to sounds?", bundle: Strings.bundle)
        }
        public static func questionOverall(name: String) -> String {
            String(localized: "How is \(name) doing overall?", bundle: Strings.bundle)
        }

        // Rating Labels
        public static var ratingPoor: String { String(localized: "Poor", bundle: Strings.bundle) }
        public static var ratingNotGreat: String { String(localized: "Not great", bundle: Strings.bundle) }
        public static var ratingOkay: String { String(localized: "Okay", bundle: Strings.bundle) }
        public static var ratingGood: String { String(localized: "Good", bundle: Strings.bundle) }
        public static var ratingGreat: String { String(localized: "Great", bundle: Strings.bundle) }

        // UI Labels
        public static var logSymptom: String { String(localized: "Log Symptom", bundle: Strings.bundle) }
        public static var whatDidYouNotice: String { String(localized: "What did you notice?", bundle: Strings.bundle) }
        public static var severity: String { String(localized: "Severity", bundle: Strings.bundle) }
        public static var bodyLocation: String { String(localized: "Body location", bundle: Strings.bundle) }
        public static var whenDidItStart: String { String(localized: "When did it start?", bundle: Strings.bundle) }
        public static var duration: String { String(localized: "Duration", bundle: Strings.bundle) }
        public static var relatedTo: String { String(localized: "Related to", bundle: Strings.bundle) }
        public static var addPhoto: String { String(localized: "Add photo", bundle: Strings.bundle) }
        public static var notes: String { String(localized: "Notes", bundle: Strings.bundle) }
        public static var notesPlaceholder: String { String(localized: "Additional details...", bundle: Strings.bundle) }

        // Trend Card
        public static var thisWeek: String { String(localized: "This week", bundle: Strings.bundle) }
        public static var lastWeek: String { String(localized: "Last week", bundle: Strings.bundle) }
        public static func episodes(_ count: Int) -> String {
            if count == 1 {
                return String(localized: "1 episode", bundle: Strings.bundle)
            } else {
                return String(localized: "\(count) episodes", bundle: Strings.bundle)
            }
        }
        public static var commonTriggers: String { String(localized: "Common triggers", bundle: Strings.bundle) }
        public static var viewDetails: String { String(localized: "View Details", bundle: Strings.bundle) }
        public static var symptomTrends: String { String(localized: "Symptom Trends", bundle: Strings.bundle) }
        public static var noRecentSymptoms: String { String(localized: "No symptoms logged recently", bundle: Strings.bundle) }

        // Quick Log
        public static var quickLog: String { String(localized: "Quick Log", bundle: Strings.bundle) }
        public static var goodDay: String { String(localized: "Good Day", bundle: Strings.bundle) }
        public static var stiffMorning: String { String(localized: "Stiff Morning", bundle: Strings.bundle) }
        public static var flareUp: String { String(localized: "Flare-up", bundle: Strings.bundle) }

        // Check-In Card
        public static var healthCheckIn: String { String(localized: "Health Check-In", bundle: Strings.bundle) }
        public static var submit: String { String(localized: "Submit", bundle: Strings.bundle) }
    }

    // MARK: - Allergies
    /// Strings for allergy tracking
    public enum Allergies {
        // Types
        public static var typeFood: String { String(localized: "Food", bundle: Strings.bundle) }
        public static var typeEnvironmental: String { String(localized: "Environmental", bundle: Strings.bundle) }
        public static var typeMedication: String { String(localized: "Medication", bundle: Strings.bundle) }
        public static var typeContact: String { String(localized: "Contact", bundle: Strings.bundle) }

        // Severity
        public static var severityMild: String { String(localized: "Mild", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Severe", bundle: Strings.bundle) }
        public static var severityLifeThreatening: String { String(localized: "Life-threatening", bundle: Strings.bundle) }

        // Severity descriptions
        public static var severityMildDesc: String { String(localized: "Minor symptoms, easily managed", bundle: Strings.bundle) }
        public static var severityModerateDesc: String { String(localized: "Noticeable symptoms, may need treatment", bundle: Strings.bundle) }
        public static var severitySevereDesc: String { String(localized: "Significant reaction, requires vet care", bundle: Strings.bundle) }
        public static var severityLifeThreateningDesc: String { String(localized: "Anaphylactic risk, immediate vet care", bundle: Strings.bundle) }

        // Common allergens - Food
        public static var allergenChicken: String { String(localized: "Chicken", bundle: Strings.bundle) }
        public static var allergenBeef: String { String(localized: "Beef", bundle: Strings.bundle) }
        public static var allergenPork: String { String(localized: "Pork", bundle: Strings.bundle) }
        public static var allergenLamb: String { String(localized: "Lamb", bundle: Strings.bundle) }
        public static var allergenFish: String { String(localized: "Fish", bundle: Strings.bundle) }
        public static var allergenDairy: String { String(localized: "Dairy", bundle: Strings.bundle) }
        public static var allergenEggs: String { String(localized: "Eggs", bundle: Strings.bundle) }
        public static var allergenWheat: String { String(localized: "Wheat", bundle: Strings.bundle) }
        public static var allergenCorn: String { String(localized: "Corn", bundle: Strings.bundle) }
        public static var allergenSoy: String { String(localized: "Soy", bundle: Strings.bundle) }
        public static var allergenRice: String { String(localized: "Rice", bundle: Strings.bundle) }

        // Common allergens - Environmental
        public static var allergenGrass: String { String(localized: "Grass", bundle: Strings.bundle) }
        public static var allergenPollen: String { String(localized: "Pollen", bundle: Strings.bundle) }
        public static var allergenDustMites: String { String(localized: "Dust mites", bundle: Strings.bundle) }
        public static var allergenMold: String { String(localized: "Mold", bundle: Strings.bundle) }
        public static var allergenFleas: String { String(localized: "Fleas", bundle: Strings.bundle) }

        // Common allergens - Contact
        public static var allergenLatex: String { String(localized: "Latex", bundle: Strings.bundle) }
        public static var allergenPlastics: String { String(localized: "Certain plastics", bundle: Strings.bundle) }
        public static var allergenFabrics: String { String(localized: "Certain fabrics", bundle: Strings.bundle) }

        // UI Labels
        public static var title: String { String(localized: "Allergies", bundle: Strings.bundle) }
        public static var addAllergy: String { String(localized: "Add Allergy", bundle: Strings.bundle) }
        public static var editAllergy: String { String(localized: "Edit Allergy", bundle: Strings.bundle) }
        public static var noAllergies: String { String(localized: "No known allergies", bundle: Strings.bundle) }
        public static var noAllergiesHint: String { String(localized: "Tap to add known allergies", bundle: Strings.bundle) }
        public static var allergen: String { String(localized: "Allergen", bundle: Strings.bundle) }
        public static var allergenPlaceholder: String { String(localized: "What causes the reaction?", bundle: Strings.bundle) }
        public static var reaction: String { String(localized: "Reaction", bundle: Strings.bundle) }
        public static var reactionPlaceholder: String { String(localized: "What happens? (itching, swelling, etc.)", bundle: Strings.bundle) }
        public static var confirmedDate: String { String(localized: "Confirmed date", bundle: Strings.bundle) }
        public static var commonAllergens: String { String(localized: "Common allergens", bundle: Strings.bundle) }
        public static var selectType: String { String(localized: "Allergy type", bundle: Strings.bundle) }
        public static var selectSeverity: String { String(localized: "Severity", bundle: Strings.bundle) }
    }

    // MARK: - Senior Wellness
    /// Strings for senior dog wellness features
    public enum SeniorWellness {
        // General
        public static var title: String { String(localized: "Senior Wellness", bundle: Strings.bundle) }
        public static var dashboard: String { String(localized: "Wellness Dashboard", bundle: Strings.bundle) }

        // Trends
        public static var trendImproving: String { String(localized: "Improving", bundle: Strings.bundle) }
        public static var trendStable: String { String(localized: "Stable", bundle: Strings.bundle) }
        public static var trendDeclining: String { String(localized: "Declining", bundle: Strings.bundle) }

        // Mobility Observations
        public static var observationStiffAfterRest: String { String(localized: "Stiff after rest", bundle: Strings.bundle) }
        public static var observationDifficultyRising: String { String(localized: "Difficulty rising", bundle: Strings.bundle) }
        public static var observationReluctantStairs: String { String(localized: "Reluctant to climb stairs", bundle: Strings.bundle) }
        public static var observationBunnyHopping: String { String(localized: "Bunny hopping", bundle: Strings.bundle) }
        public static var observationLimping: String { String(localized: "Limping", bundle: Strings.bundle) }
        public static var observationSlowerWalks: String { String(localized: "Slower on walks", bundle: Strings.bundle) }
        public static var observationTroubleSlipperyFloors: String { String(localized: "Trouble with slippery floors", bundle: Strings.bundle) }
        public static var observationCollapsingRearLegs: String { String(localized: "Rear legs collapsing", bundle: Strings.bundle) }
        public static var observationDraggingPaws: String { String(localized: "Dragging paws", bundle: Strings.bundle) }

        // Mobility Levels (1-5)
        public static var mobilityLevel1: String { String(localized: "Cannot walk without help", bundle: Strings.bundle) }
        public static var mobilityLevel2: String { String(localized: "Struggles significantly", bundle: Strings.bundle) }
        public static var mobilityLevel3: String { String(localized: "Moderate difficulty", bundle: Strings.bundle) }
        public static var mobilityLevel4: String { String(localized: "Mild stiffness/slowness", bundle: Strings.bundle) }
        public static var mobilityLevel5: String { String(localized: "Moving well for age", bundle: Strings.bundle) }

        public static var mobilityLevelShort1: String { String(localized: "Needs help", bundle: Strings.bundle) }
        public static var mobilityLevelShort2: String { String(localized: "Struggling", bundle: Strings.bundle) }
        public static var mobilityLevelShort3: String { String(localized: "Moderate", bundle: Strings.bundle) }
        public static var mobilityLevelShort4: String { String(localized: "Mild issues", bundle: Strings.bundle) }
        public static var mobilityLevelShort5: String { String(localized: "Good", bundle: Strings.bundle) }

        // CCD Categories
        public static var ccdDisorientation: String { String(localized: "Disorientation", bundle: Strings.bundle) }
        public static var ccdInteractions: String { String(localized: "Interactions", bundle: Strings.bundle) }
        public static var ccdSleep: String { String(localized: "Sleep", bundle: Strings.bundle) }
        public static var ccdHouseSoiling: String { String(localized: "House Soiling", bundle: Strings.bundle) }
        public static var ccdActivity: String { String(localized: "Activity", bundle: Strings.bundle) }
        public static var ccdAnxiety: String { String(localized: "Anxiety", bundle: Strings.bundle) }

        // CCD Symptoms - Disorientation
        public static var symptomLostFamiliarPlaces: String { String(localized: "Gotten lost in familiar places", bundle: Strings.bundle) }
        public static var symptomStaresAtWalls: String { String(localized: "Stared at walls or into space", bundle: Strings.bundle) }
        public static var symptomWrongSideOfDoor: String { String(localized: "Gone to wrong side of door", bundle: Strings.bundle) }

        // CCD Symptoms - Interactions
        public static var symptomLessInterested: String { String(localized: "Seemed less interested in you", bundle: Strings.bundle) }
        public static var symptomNotGreeting: String { String(localized: "Not greeted you as usual", bundle: Strings.bundle) }
        public static var symptomAvoidsPetting: String { String(localized: "Avoided petting/interaction", bundle: Strings.bundle) }

        // CCD Symptoms - Sleep
        public static var symptomPacesAtNight: String { String(localized: "Paced at night", bundle: Strings.bundle) }
        public static var symptomSleepsMoreDay: String { String(localized: "Slept more during day", bundle: Strings.bundle) }
        public static var symptomWakesYouUp: String { String(localized: "Woken you up at night", bundle: Strings.bundle) }

        // CCD Symptoms - House Soiling
        public static var symptomAccidents: String { String(localized: "Had accidents (was housetrained)", bundle: Strings.bundle) }
        public static var symptomForgetsToSignal: String { String(localized: "Forgotten to signal to go out", bundle: Strings.bundle) }

        // CCD Symptoms - Activity
        public static var symptomLessPlayInterest: String { String(localized: "Less interested in play", bundle: Strings.bundle) }
        public static var symptomAimlessWandering: String { String(localized: "Aimless wandering", bundle: Strings.bundle) }
        public static var symptomRepetitiveBehaviors: String { String(localized: "Repetitive behaviors", bundle: Strings.bundle) }

        // CCD Symptoms - Anxiety
        public static var symptomMoreAnxious: String { String(localized: "Seemed more anxious", bundle: Strings.bundle) }
        public static var symptomNewFears: String { String(localized: "New fears or phobias", bundle: Strings.bundle) }
        public static var symptomIncreasedVocalization: String { String(localized: "Increased vocalization", bundle: Strings.bundle) }

        // CCD Severity
        public static var severityNone: String { String(localized: "No signs", bundle: Strings.bundle) }
        public static var severityMild: String { String(localized: "Mild signs", bundle: Strings.bundle) }
        public static var severityModerate: String { String(localized: "Moderate signs", bundle: Strings.bundle) }
        public static var severitySevere: String { String(localized: "Significant signs", bundle: Strings.bundle) }

        // CCD Guidance
        public static var guidanceNone: String { String(localized: "No signs of cognitive decline detected.", bundle: Strings.bundle) }
        public static var guidanceMild: String { String(localized: "Mild signs detected. Consider discussing with your vet at the next visit.", bundle: Strings.bundle) }
        public static var guidanceModerate: String { String(localized: "Moderate signs detected. We recommend scheduling a vet appointment to discuss cognitive support options.", bundle: Strings.bundle) }
        public static var guidanceSevere: String { String(localized: "Significant cognitive changes detected. Please consult your vet soon about management options.", bundle: Strings.bundle) }

        // Quality of Life Categories
        public static var qolHurt: String { String(localized: "Hurt (Pain)", bundle: Strings.bundle) }
        public static var qolHunger: String { String(localized: "Hunger", bundle: Strings.bundle) }
        public static var qolHydration: String { String(localized: "Hydration", bundle: Strings.bundle) }
        public static var qolHygiene: String { String(localized: "Hygiene", bundle: Strings.bundle) }
        public static var qolHappiness: String { String(localized: "Happiness", bundle: Strings.bundle) }
        public static var qolMobility: String { String(localized: "Mobility", bundle: Strings.bundle) }
        public static var qolMoreDays: String { String(localized: "More Good Days Than Bad?", bundle: Strings.bundle) }

        // QoL Questions
        public static var qolQuestionHurt: String { String(localized: "Is pain well managed?", bundle: Strings.bundle) }
        public static var qolQuestionHunger: String { String(localized: "Is eating enough?", bundle: Strings.bundle) }
        public static var qolQuestionHydration: String { String(localized: "Is drinking enough?", bundle: Strings.bundle) }
        public static var qolQuestionHygiene: String { String(localized: "Can be kept clean/groomed?", bundle: Strings.bundle) }
        public static var qolQuestionHappiness: String { String(localized: "Shows joy?", bundle: Strings.bundle) }
        public static var qolQuestionMobility: String { String(localized: "Can get around?", bundle: Strings.bundle) }
        public static var qolQuestionMoreDays: String { String(localized: "Overall quality of life", bundle: Strings.bundle) }

        // QoL Low/High Labels
        public static var qolHurtLow: String { String(localized: "Severe pain", bundle: Strings.bundle) }
        public static var qolHurtHigh: String { String(localized: "No pain", bundle: Strings.bundle) }
        public static var qolHungerLow: String { String(localized: "Not eating", bundle: Strings.bundle) }
        public static var qolHungerHigh: String { String(localized: "Eating well", bundle: Strings.bundle) }
        public static var qolHydrationLow: String { String(localized: "Not drinking", bundle: Strings.bundle) }
        public static var qolHydrationHigh: String { String(localized: "Drinking well", bundle: Strings.bundle) }
        public static var qolHygieneLow: String { String(localized: "Cannot maintain", bundle: Strings.bundle) }
        public static var qolHygieneHigh: String { String(localized: "Well maintained", bundle: Strings.bundle) }
        public static var qolHappinessLow: String { String(localized: "No joy", bundle: Strings.bundle) }
        public static var qolHappinessHigh: String { String(localized: "Full of joy", bundle: Strings.bundle) }
        public static var qolMobilityLow: String { String(localized: "Cannot move", bundle: Strings.bundle) }
        public static var qolMobilityHigh: String { String(localized: "Moving well", bundle: Strings.bundle) }
        public static var qolMoreDaysLow: String { String(localized: "Mostly bad days", bundle: Strings.bundle) }
        public static var qolMoreDaysHigh: String { String(localized: "Mostly good days", bundle: Strings.bundle) }

        // QoL Interpretation
        public static var qolInterpretationGood: String { String(localized: "Good", bundle: Strings.bundle) }
        public static var qolInterpretationAcceptable: String { String(localized: "Acceptable", bundle: Strings.bundle) }
        public static var qolInterpretationCompromised: String { String(localized: "Compromised", bundle: Strings.bundle) }
        public static var qolInterpretationPoor: String { String(localized: "Poor", bundle: Strings.bundle) }

        public static var qolMessageGood: String { String(localized: "Quality of life is good. Continue current care.", bundle: Strings.bundle) }
        public static var qolMessageAcceptable: String { String(localized: "Quality of life is acceptable. Monitor closely and discuss comfort measures with your vet.", bundle: Strings.bundle) }
        public static var qolMessageCompromised: String { String(localized: "Quality of life may be compromised. Please discuss with your vet about management options.", bundle: Strings.bundle) }
        public static var qolMessagePoor: String { String(localized: "Quality of life appears significantly impacted. We recommend an urgent conversation with your vet about your dog's comfort.", bundle: Strings.bundle) }

        // Respiratory Rate Status
        public static var rrrStatusNormal: String { String(localized: "Normal", bundle: Strings.bundle) }
        public static var rrrStatusElevated: String { String(localized: "Elevated", bundle: Strings.bundle) }
        public static var rrrStatusEmergency: String { String(localized: "Very High", bundle: Strings.bundle) }

        public static var rrrMessageNormal: String { String(localized: "Normal resting rate", bundle: Strings.bundle) }
        public static var rrrMessageElevated: String { String(localized: "Elevated - monitor closely", bundle: Strings.bundle) }
        public static var rrrMessageEmergency: String { String(localized: "Very high - contact vet immediately", bundle: Strings.bundle) }

        // Respiratory Rate Trend
        public static var rrrTrendDecreasing: String { String(localized: "Decreasing", bundle: Strings.bundle) }
        public static var rrrTrendStable: String { String(localized: "Stable", bundle: Strings.bundle) }
        public static var rrrTrendIncreasing: String { String(localized: "Increasing", bundle: Strings.bundle) }
    }
}
