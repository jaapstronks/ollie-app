# Health Tracking Expansion Analysis

## Executive Summary

This document analyzes how to expand Ollie's health tracking capabilities beyond puppy-specific features to support dogs throughout their entire lifespan. The app already has a solid foundation with weight tracking, medications, vaccinations, appointments, documents, and contacts. This analysis identifies gaps and opportunities for comprehensive health management.

---

## Part 1: Current State Assessment

### What Already Exists

| Feature | Implementation | Notes |
|---------|---------------|-------|
| **Weight tracking** | Full | Charts, growth curves, trending, unit conversion |
| **Medications** | Full | Schedules, dosages, completions, reminders |
| **Vaccinations** | Via milestones | Built-in vaccine milestones with vet tracking |
| **Appointments** | Full | 11 types including vet, surgery, emergency |
| **Documents** | Full | 9 types including medical records, insurance |
| **Contacts** | Full | Vet, emergency vet, specialists |
| **Health milestones** | Full | Age-based, recurring (annual vaccines) |

### What's Missing for Older Dogs

The current system is optimized for the puppy phase (0-18 months). For adult and senior dogs, we need:

1. **Measurements beyond weight** — vital signs, body condition, mobility
2. **Chronic condition management** — ongoing health issues
3. **Medical history timeline** — surgeries, diagnoses, treatments
4. **Lab results tracking** — blood work, urinalysis, imaging
5. **Senior-specific milestones** — age-related health markers
6. **Symptom/observation logging** — changes in behavior or health

---

## Part 2: Measurements Dog Owners Track

### Tier 1: Common Measurements (Most Dog Owners)

| Measurement | Frequency | Unit | Notes |
|-------------|-----------|------|-------|
| **Weight** | Weekly-Monthly | kg/lbs | ✅ Already implemented |
| **Body Condition Score (BCS)** | Monthly | 1-9 scale | Visual assessment of fat/muscle |
| **Food intake** | Daily | cups/grams | ✅ Partially via meal events |
| **Water intake** | Daily | ml/estimate | ✅ Partially via drink events |
| **Stool quality** | Per event | 1-7 scale | Fecal scoring chart |
| **Energy level** | Daily | Low/Med/High | Subjective assessment |

### Tier 2: Health-Conscious Owners

| Measurement | Frequency | Unit | Notes |
|-------------|-----------|------|-------|
| **Resting heart rate** | Periodic | BPM | 60-140 normal depending on size |
| **Respiratory rate** | Periodic | breaths/min | 10-35 normal |
| **Temperature** | When ill | °C/°F | 38.3-39.2°C normal |
| **Mobility score** | Weekly | 1-5 scale | Especially for seniors/arthritis |
| **Pain assessment** | When needed | 1-10 scale | Standardized pain scales exist |
| **Dental health** | Monthly | 1-5 scale | Tartar, gum health |

### Tier 3: Medical/Chronic Conditions

| Measurement | Condition | Unit | Notes |
|-------------|-----------|------|-------|
| **Blood glucose** | Diabetes | mg/dL | Multiple daily readings |
| **Seizure log** | Epilepsy | Duration/type | Time, length, severity |
| **Skin condition** | Allergies | Photo + score | Track flare-ups |
| **Joint measurements** | Arthritis | Range of motion | Track progression |
| **Tumor size** | Cancer | cm/mm | Track growth |
| **Thyroid levels** | Hypothyroid | Lab values | From blood work |

### Tier 4: Wearable/Smart Device Data (Future)

| Measurement | Source | Notes |
|-------------|--------|-------|
| **Activity level** | Fi, Whistle, etc. | Steps, distance, active minutes |
| **Sleep quality** | Smart collars | Sleep duration, restlessness |
| **Location history** | GPS collars | Could integrate with walks |
| **Heart rate variability** | Advanced wearables | Stress/health indicator |

---

## Part 3: Medical Records to Track

### 3.1 Surgical History

**Data to capture:**
- Surgery type (spay/neuter, tumor removal, orthopedic, dental extraction, etc.)
- Date performed
- Veterinary clinic/hospital
- Surgeon name (link to contact)
- Anesthesia type/notes
- Pre-op weight
- Complications (if any)
- Recovery notes
- Follow-up appointments
- Related documents (surgery report, pathology, discharge instructions)
- Photos (incision site, healing progress)

**Common surgical procedures:**
- Spay/neuter (castration/sterilization)
- Mass/tumor removal
- Foreign body removal
- Orthopedic (cruciate repair, hip replacement, fracture repair)
- Dental extractions
- Eye surgery (cherry eye, entropion)
- Ear surgery (hematoma, TECA)
- Gastropexy
- Cesarean section
- Biopsy

### 3.2 Diagnostic Imaging

**Types to support:**
- X-rays (radiographs)
- Ultrasound
- CT scan
- MRI
- Endoscopy photos/video
- Dental radiographs

**Data to capture:**
- Date taken
- Body area
- Reason/indication
- Findings summary
- Clinic/radiologist
- Image files (JPEG, PDF, DICOM viewer link)
- Follow-up comparison dates

### 3.3 Laboratory Results

**Blood Work Types:**
- Complete Blood Count (CBC)
  - RBC, WBC, platelets, hemoglobin, hematocrit
- Chemistry Panel
  - Liver enzymes (ALT, AST, ALP)
  - Kidney values (BUN, creatinine)
  - Glucose
  - Proteins (albumin, globulin)
  - Electrolytes
- Thyroid panel (T4, TSH)
- Heartworm test
- Tick-borne disease panel
- Pancreatic enzymes (lipase, amylase)
- Coagulation panel

**Other Lab Tests:**
- Urinalysis
- Fecal examination (parasites)
- Skin scraping/cytology
- Allergy panel results
- Genetic testing results (Embark, Wisdom Panel)
- Pathology/biopsy results

**Data structure for lab results:**
- Test date
- Lab/clinic name
- Test type
- Individual values with reference ranges
- Trend over time (crucial for chronic conditions)
- PDF of full report
- Vet notes/interpretation

### 3.4 Examination Records

**Regular checkup data:**
- Date
- Veterinarian (link to contact)
- Weight at visit
- Temperature, heart rate, respiratory rate
- Body condition score
- Dental assessment
- Eye/ear examination notes
- Skin/coat notes
- Musculoskeletal assessment
- Lymph node check
- Abdominal palpation notes
- Overall assessment
- Recommendations
- Next visit scheduled

### 3.5 Diagnoses & Conditions

**Chronic conditions to track:**
- Allergies (food, environmental)
- Arthritis/joint disease
- Heart disease
- Kidney disease
- Diabetes
- Hypothyroidism/Hyperthyroidism
- Epilepsy
- Cancer (type, stage, treatment protocol)
- Cushing's disease
- Addison's disease
- IBD/GI issues
- Skin conditions
- Eye conditions (cataracts, glaucoma)
- Dental disease

**Data per condition:**
- Diagnosis date
- Diagnosing vet
- Severity/stage
- Treatment protocol
- Related medications
- Monitoring schedule
- Progression notes over time

### 3.6 Preventive Care Timeline

**What to track:**
- Vaccinations (already have this via milestones)
- Deworming schedule
- Flea/tick prevention applications
- Heartworm prevention doses
- Dental cleanings
- Annual blood work
- Senior wellness panels (7+ years)

---

## Part 4: Other Health-Adjacent Data

### 4.1 Dietary Information

**Currently stored:** Meal schedule (times, portions)

**Should add:**
- **Current food brand/type** — brand, product line, formulation
- **Dietary restrictions** — allergies, intolerances, sensitivities
- **Food transition history** — what foods have been tried
- **Prescription diets** — if on therapeutic food
- **Supplements** — glucosamine, fish oil, probiotics, etc.
- **Treat types** — for training, dental, etc.
- **Feeding method** — kibble, wet, raw, homemade, combination

### 4.2 Insurance Information

**Currently:** Document type exists for insurance

**Should add:**
- Policy number
- Provider name
- Coverage type (accident, illness, wellness)
- Deductible amount
- Annual limit
- Reimbursement percentage
- Waiting periods
- Pre-existing condition exclusions
- Renewal date
- Claim history tracking

### 4.3 Emergency Information

**Quick-access emergency card:**
- Dog's name, photo, age
- Microchip number
- Emergency contact
- Regular vet contact
- Emergency vet contact
- Blood type (if known)
- Known allergies
- Current medications
- Chronic conditions
- Insurance info

---

## Part 5: UI/UX Architecture Considerations

### Current Navigation Structure

```
Today View          → Daily events (potty, meals, walks, sleep, etc.)
Calendar View       → Appointments, milestones, historical events
Health View         → Weight tracking, health milestones
Settings            → Profile, medications, preferences
Contacts            → Vets, sitters, etc.
Documents           → Medical records, insurance, etc.
```

### The Problem

Health-related features are scattered:
- Weight → Health View
- Medications → Settings
- Appointments (incl. vet) → Calendar
- Documents (incl. medical) → Documents section
- Vet contacts → Contacts section
- Vaccinations → Milestones (in Health View and Calendar)

**User story confusion:**
> "I want to see everything about my dog's medical history in one place"

Currently requires navigating to 4-5 different sections.

### Proposed: Medical Hub View

A dedicated **Medical** tab or section that aggregates:

```
Medical Hub
├── Overview Dashboard
│   ├── Current medications (quick view)
│   ├── Upcoming appointments
│   ├── Due vaccinations/preventives
│   ├── Active conditions status
│   └── Last checkup summary
│
├── Health Timeline
│   ├── All medical events chronologically
│   ├── Filter by type (surgery, lab, checkup, etc.)
│   └── Includes documents, appointments, results
│
├── Conditions
│   ├── Active diagnoses
│   ├── Allergies & dietary restrictions
│   └── Condition-specific tracking
│
├── Records
│   ├── Lab results (with trends)
│   ├── Imaging
│   ├── Surgery history
│   └── Examination notes
│
├── Preventive Care
│   ├── Vaccination record
│   ├── Parasite prevention log
│   └── Dental care history
│
└── Quick Actions
    ├── Log symptom/observation
    ├── Schedule vet appointment
    └── Upload document
```

### Cross-Reference Architecture

The key insight: **Data lives in one place, but surfaces in multiple views.**

| Data Type | Primary Location | Also Shows In |
|-----------|-----------------|---------------|
| Medications | Settings (edit) | Medical Hub (view), Today (reminders) |
| Appointments | Calendar (edit) | Medical Hub (medical ones only) |
| Documents | Documents (edit) | Medical Hub (medical ones only) |
| Contacts | Contacts (edit) | Medical Hub (vets only) |
| Weight | Health View (edit) | Medical Hub (summary) |
| Lab results | Medical Hub (edit) | Documents (PDF storage) |

### Questions to Resolve

1. **Should Medical Hub be a new tab or a subsection?**
   - New tab: More prominent, easier access
   - Subsection: Keeps navigation simpler
   - Compromise: Prominent link from Settings or Health View

2. **How to handle the Today View?**
   - Keep it focused on daily routines (potty, meals, walks)
   - Medical stuff is periodic, not daily
   - Exception: Daily medication reminders should appear in Today

3. **Should we separate "Puppy Health" from "Ongoing Health"?**
   - Puppy phase: Growth curves, developmental milestones, first vaccines
   - Adult phase: Maintenance, chronic condition management
   - Senior phase: More frequent monitoring, age-related issues
   - Or: One unified view with age-appropriate emphasis

4. **How granular should lab result tracking be?**
   - Simple: Just attach PDF, add summary note
   - Medium: Key values manually entered, basic trending
   - Complex: Full lab panel data entry, automatic flagging of abnormals
   - Recommendation: Start simple, add complexity based on user demand

---

## Part 6: Implementation Priorities

### Phase 1: Foundation (Build on Existing)

**Low effort, high value:**
- [ ] Add Body Condition Score to weight logging
- [ ] Add stool quality scoring to potty events
- [ ] Add dietary restrictions to profile/settings
- [ ] Add current food brand to profile
- [ ] Add supplements tracking (similar to medications)
- [ ] Add "Conditions" section to profile (active diagnoses)

### Phase 2: Medical Records

**Medium effort:**
- [ ] Surgery record model and entry form
- [ ] Examination/checkup record model
- [ ] Lab results model (basic: date, type, PDF, notes)
- [ ] Medical timeline view aggregating all records
- [ ] Link appointments to records (post-appointment → add record)

### Phase 3: Enhanced Lab Tracking

**Higher effort:**
- [ ] Detailed lab value entry (individual values, reference ranges)
- [ ] Lab value trending charts
- [ ] Abnormal value highlighting
- [ ] Comparison to previous results

### Phase 4: Senior Dog Features

**Age-specific:**
- [ ] Senior milestones (7+, 10+, 12+ year checkups)
- [ ] Mobility/pain scoring
- [ ] Cognitive assessment tracking (CCD)
- [ ] Quality of life assessment tools
- [ ] End-of-life planning resources (sensitive topic)

### Phase 5: Advanced Features

**Future considerations:**
- [ ] Smart device integration (Fi, Whistle)
- [ ] Vet portal integration (if APIs exist)
- [ ] Insurance claim helper
- [ ] Medication interaction warnings
- [ ] Symptom checker (careful: not medical advice)
- [ ] Export for vet visits (PDF summary)

---

## Part 7: Data Model Considerations

### New Models Needed

```swift
// Condition/Diagnosis
struct Condition: Identifiable, Codable {
    var id: UUID
    var name: String
    var type: ConditionType  // chronic, acute, resolved
    var diagnosisDate: Date
    var diagnosingVet: UUID?  // link to Contact
    var severity: Severity?
    var notes: String?
    var relatedMedications: [UUID]
    var status: ConditionStatus  // active, managed, resolved
}

// Surgery Record
struct SurgeryRecord: Identifiable, Codable {
    var id: UUID
    var type: SurgeryType
    var customType: String?  // if type is .other
    var date: Date
    var clinic: String?
    var surgeon: UUID?  // link to Contact
    var preOpWeight: Double?
    var anesthesiaNotes: String?
    var complications: String?
    var recoveryNotes: String?
    var relatedDocuments: [UUID]
    var relatedAppointments: [UUID]
    var photos: [URL]
}

// Lab Result
struct LabResult: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: LabType  // CBC, chemistry, thyroid, urinalysis, etc.
    var clinic: UUID?
    var documentId: UUID?  // link to uploaded PDF
    var summary: String?
    var values: [LabValue]?  // optional detailed values
    var flaggedAbnormal: Bool
}

struct LabValue: Codable {
    var name: String  // "ALT", "BUN", "RBC", etc.
    var value: Double
    var unit: String
    var referenceMin: Double?
    var referenceMax: Double?
    var isAbnormal: Bool
}

// Imaging Record
struct ImagingRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: ImagingType  // xray, ultrasound, CT, MRI
    var bodyArea: String
    var indication: String?
    var findings: String?
    var clinic: UUID?
    var radiologist: String?
    var images: [URL]  // or document IDs
}

// Examination Record
struct ExaminationRecord: Identifiable, Codable {
    var id: UUID
    var date: Date
    var type: ExamType  // wellness, sick, followUp, emergency
    var vet: UUID?
    var clinic: String?
    var vitals: Vitals?
    var findings: String?
    var recommendations: String?
    var relatedAppointment: UUID?
    var relatedDocuments: [UUID]
}

struct Vitals: Codable {
    var weight: Double?
    var temperature: Double?
    var heartRate: Int?
    var respiratoryRate: Int?
    var bodyConditionScore: Int?  // 1-9
}

// Dietary Profile
struct DietaryProfile: Codable {
    var currentFood: FoodInfo?
    var restrictions: [DietaryRestriction]
    var allergies: [String]
    var supplements: [Supplement]
    var feedingMethod: FeedingMethod
    var foodHistory: [FoodTransition]
}
```

### Extending Existing Models

```swift
// Add to PuppyProfile
extension PuppyProfile {
    var conditions: [Condition]
    var dietaryProfile: DietaryProfile
    var insuranceInfo: InsuranceInfo?
    var bloodType: BloodType?  // DEA 1.1+, DEA 1.1-, unknown
}

// Add to PuppyEvent (for enhanced logging)
extension PuppyEvent {
    var stoolScore: Int?  // 1-7 fecal scoring
    var energyLevel: EnergyLevel?
    var painScore: Int?  // 1-10
}
```

---

## Part 8: Open Questions

### Product Questions

1. **Target audience expansion:** Are we targeting:
   - All dog owners (puppy through senior)?
   - Health-conscious owners specifically?
   - Owners of dogs with chronic conditions?

2. **Vet integration:** Should we pursue:
   - Manual entry only (simpler, more private)?
   - PDF/image OCR for lab results?
   - Direct vet system integration (complex, HIPAA-like concerns)?

3. **Medical advice boundary:** How do we handle:
   - Symptom tracking without implying diagnosis?
   - Reference ranges without medical interpretation?
   - Emergency guidance without liability?

4. **Data portability:** Should users be able to:
   - Export full medical history as PDF?
   - Share records with vets electronically?
   - Import from other pet health apps?

### Technical Questions

1. **Storage:** Medical records (especially images) can get large:
   - Local storage limits on device?
   - Cloud storage (iCloud, our own backend)?
   - Compression/optimization for images?

2. **Sync:** Medical data is sensitive:
   - CloudKit sufficient for privacy?
   - Need for encryption at rest?
   - Multi-device sync for family sharing?

3. **Backward compatibility:**
   - How to migrate existing data?
   - Profile versioning for new fields?

### UX Questions

1. **Complexity vs. simplicity:** The app's strength is simplicity:
   - How to add medical features without overwhelming?
   - Progressive disclosure (simple by default, detailed when needed)?
   - Different "modes" for casual vs. medical-focused use?

2. **Data entry burden:** Medical tracking requires more input:
   - Photo-based entry (take pic of lab report)?
   - Voice notes for observations?
   - Templates for common scenarios?

---

## Part 9: Competitive Analysis (Brief)

| App | Strengths | Weaknesses |
|-----|-----------|------------|
| **Pet Desk** | Vet integration, reminders | Focused on vet relationship, less personal tracking |
| **11Pets** | Comprehensive medical tracking | Complex UI, overwhelming |
| **DogLog** | Simple logging | Limited medical features |
| **Pawtrack** | Activity tracking | Hardware dependent |
| **PetDesk** | Appointment booking | Less personal health tracking |

**Opportunity:** No app does both simple daily logging AND comprehensive medical tracking well. Ollie could bridge this gap.

---

## Part 10: Recommendations Summary

### Do Now
1. Add Body Condition Score (1-9) to weight entries
2. Add stool quality score (1-7) option to potty events
3. Add "Conditions/Allergies" section to profile settings
4. Add dietary restrictions/current food to profile

### Do Soon
1. Create Surgery Record model and basic entry UI
2. Create "Medical Timeline" view aggregating appointments, documents, milestones
3. Add examination record entry (post-vet-visit logging)
4. Consider Medical Hub as dedicated section

### Do Later
1. Detailed lab result tracking with trending
2. Senior-specific features and milestones
3. Enhanced imaging record management
4. Export/sharing capabilities

### Don't Do (Yet)
1. Vet portal integration (complex, limited APIs)
2. AI symptom analysis (liability concerns)
3. Smart collar integration (fragment market)
4. Prescription management (regulatory issues)

---

## Appendix: Reference Scales

### Body Condition Score (1-9 Scale)
- 1-3: Underweight (ribs, spine, hip bones visible)
- 4-5: Ideal (ribs palpable, waist visible from above)
- 6-7: Overweight (ribs hard to feel, waist disappearing)
- 8-9: Obese (ribs not palpable, no waist, abdominal distension)

### Fecal Score (1-7 Scale)
- 1: Hard, dry pellets (constipation)
- 2: Firm, segmented
- 3: Log-shaped, moist
- 4: Ideal - log-shaped, leaves minimal residue
- 5: Soft, loses shape
- 6: Texture but no shape
- 7: Watery, no texture (diarrhea)

### Pain Scale (1-10)
- 0: No pain
- 1-3: Mild (slightly reduced activity)
- 4-6: Moderate (reluctance to move, vocalization)
- 7-9: Severe (aggression when touched, won't move)
- 10: Extreme (constant vocalization, shock signs)

### Mobility Score (1-5)
- 5: Normal mobility
- 4: Slight stiffness, especially after rest
- 3: Obvious lameness, hesitates on stairs
- 2: Significant difficulty, needs assistance
- 1: Unable to walk without support
