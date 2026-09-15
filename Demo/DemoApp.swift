//
//  DemoApp.swift
//  GroundingContract Demo
//
//  A runnable demonstration of the grounding contract: pick an answer a model
//  might have produced, pick the contract you want to enforce, and watch the
//  verdict change.
//
//  The app owns the corpus and the candidate answers; `GroundingContract` owns
//  every decision about them. That split is deliberate — it is the same split
//  a real app has, where retrieval and generation live in the app and the
//  contract is a library you can test without either.
//

import SwiftUI
import GroundingContract
import GroundingContractUI

// MARK: - The app's own content

/// The compiled-in evidence set. In a shipping app these come back from
/// `SpotlightSearchTool` / `CSSearchQuery`; here they are literals so the demo
/// is deterministic and needs no index, no network and no model.
enum DemoCorpus {

    static let units: [EvidenceUnit] = [
        EvidenceUnit(
            id: "cache",
            text: """
            The image cache evicts entries under a 48 MB byte budget using \
            least-recently-used ordering, and refreshes recency on read.
            """,
            provenance: Provenance(
                sourceID: "spotlight.local",
                displayName: "Caching notes",
                ageSeconds: 120
            )
        ),
        EvidenceUnit(
            id: "latency",
            text: """
            Checkout p95 latency measured 420 ms in the September release, and \
            the staged rollout covered 30 percent of devices.
            """,
            provenance: Provenance(
                sourceID: "wiki.remote",
                displayName: "Release notes",
                ageSeconds: 3_600
            )
        ),
        EvidenceUnit(
            id: "incident",
            text: """
            Incident INC-9114 was resolved in 37 minutes after the retry storm \
            was rate limited at the client.
            """,
            provenance: Provenance(
                sourceID: "spotlight.local",
                displayName: "Incident log",
                ageSeconds: 86_400
            )
        )
    ]

    static var evidence: EvidenceSet { EvidenceSet(units: units) }
}

/// Answers a model plausibly produces against `DemoCorpus`, each chosen to
/// exercise a different branch of the contract.
struct DemoAnswer: Identifiable, Hashable {
    let id: String
    let label: String
    let detail: String
    let text: String

    static let all: [DemoAnswer] = [
        DemoAnswer(
            id: "mixed",
            label: "Mixed",
            detail: "One grounded claim, one invented one",
            text: """
            The image cache evicts entries using least-recently-used ordering. \
            Kubernetes autoscaling was disabled for the nightly worker pool.
            """
        ),
        DemoAnswer(
            id: "fabricated-figure",
            label: "Wrong number",
            detail: "Every word right, one digit wrong",
            text: "The image cache evicts entries under a 64 MB byte budget."
        ),
        DemoAnswer(
            id: "fabricated-id",
            label: "Wrong identifier",
            detail: "INC-9115 does not exist",
            text: "Incident INC-9115 was resolved in 37 minutes after a retry storm."
        ),
        DemoAnswer(
            id: "grounded",
            label: "Fully grounded",
            detail: "Two claims, both cited",
            text: """
            The image cache evicts entries under a 48 MB byte budget. \
            Checkout p95 latency measured 420 ms in the September release.
            """
        ),
        DemoAnswer(
            id: "partial",
            label: "Half invented",
            detail: "Real subject, invented mechanism",
            text: "The image cache evicts entries using a segmented admission filter."
        ),
        DemoAnswer(
            id: "ungrounded",
            label: "Nothing grounded",
            detail: "Redaction has nothing left to keep",
            text: """
            Kubernetes autoscaling was disabled for the nightly worker pool. \
            Terraform drift was reconciled by the nightly planner job.
            """
        )
    ]
}

// MARK: - Root view

struct ContentView: View {
    @State private var selection: DemoAnswer = DemoAnswer.all[0]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                answerPicker
                Divider()
                GroundingReportView(
                    model: GroundingReportModel(
                        question: "What do we know about the image cache?",
                        answer: selection.text,
                        evidence: DemoCorpus.evidence,
                        policy: GroundingPolicy()
                    )
                )
                // A new answer is a new verification, so it gets a new model.
                .id(selection.id)
            }
            .navigationTitle("Grounding Contract")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var answerPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DemoAnswer.all) { answer in
                    Button {
                        selection = answer
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(answer.label).font(.subheadline.weight(.semibold))
                            Text(answer.detail).font(.caption2)
                        }
                        .frame(maxWidth: 180, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(answer == selection
                                      ? Color.accentColor.opacity(0.18)
                                      : Color.secondary.opacity(0.10))
                        )
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(answer == selection ? Color.accentColor : Color.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - Entry point

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
