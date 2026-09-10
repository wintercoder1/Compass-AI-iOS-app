//
//  FinancialContributionsSyncManager.swift
//  Compass AI V2
//
//  Created by Steve on 11/4/25.
//

import Foundation
import CoreData

class CoreDataFinancialContributionsSyncManager {
    static let shared = CoreDataFinancialContributionsSyncManager()
    
    private var isSyncing = false
    private let syncQueue = DispatchQueue(label: "com.compassai.financialSync", qos: .utility)
    
    private init() {}
    
    /// Syncs missing financial contributions in the background after app launch
    func syncMissingFinancialContributions() {
        guard !isSyncing else {
            print("🔄 Sync already in progress, skipping...")
            return
        }
        
        isSyncing = true
        print("🔄 Starting background sync of missing financial contributions...")
        
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            let persistence = CoreDataPersistence()
            let context = persistence.container.newBackgroundContext()
            
            context.perform {
                do {
                    let missingFinancials = try self.fetchQueryAnswersWithMissingFinancials(context: context)
                    
                    if missingFinancials.isEmpty {
                        print("✅ No missing financial contributions found")
                        self.isSyncing = false
                        return
                    }
                    
                    print("📊 Found \(missingFinancials.count) query answers with missing financial data")
                    
                    // Process each missing financial contribution
                    self.processMissingFinancials(missingFinancials, context: context)
                    
                } catch {
                    print("❌ Error fetching query answers with missing financials: \(error)")
                    self.isSyncing = false
                }
            }
        }
    }
    
    private func fetchQueryAnswersWithMissingFinancials(context: NSManagedObjectContext) throws -> [QueryAnswerObject] {
        let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        
        // Fetch all query answers that have the financial contributions flag set to true
        request.predicate = NSPredicate(format: "created_with_financial_contributions_info == YES")
        request.relationshipKeyPathsForPrefetching = ["finanicial_contributions_overview"]
        
        let results = try context.fetch(request)
        
        // Filter to only those that don't have financial contributions already
        let missingFinancials = results.filter { qa in
            return qa.finanicial_contributions_overview == nil
        }
        
        return missingFinancials
    }
    
    private func processMissingFinancials(_ queryAnswers: [QueryAnswerObject], context: NSManagedObjectContext) {
        let group = DispatchGroup()
        var completedCount = 0
        var failedCount = 0
        
        for qa in queryAnswers {
            guard let topic = qa.topic,
                  let category = qa.category else {
                print("⚠️ Skipping query answer with nil topic")
                continue
            }
            
            group.enter()
            
            print("📥 Fetching financial contributions for: \(topic)")
            
            // Fetch financial contributions from the network
            NetworkManager.shared.getFinancialContributionsOverview(for: topic) { [weak self] result in
                defer { group.leave() }
                
                guard let self = self else { return }
                
                switch result {
                case .success(let financialData):
                    print("✅ Successfully fetched financial data for: \(topic)")
                    
                    // Save the financial contributions
                    self.saveFinancialContributions(
                        financialData: financialData,
                        for: topic,
                        category: category,
                        context: context
                    ) { success in
                        if success {
                            completedCount += 1
                            print("✅ Saved financial contributions for: \(topic) (\(completedCount)/\(queryAnswers.count))")
                        } else {
                            failedCount += 1
                            print("❌ Failed to save financial contributions for: \(topic)")
                        }
                    }
                    
                case .failure(let error):
                    failedCount += 1
                    print("❌ Failed to fetch financial contributions for \(topic): \(error)")
                }
            }
            
            // Add a small delay between requests to avoid overwhelming the server
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Wait for all requests to complete
        group.notify(queue: syncQueue) { [weak self] in
            print("🎉 Background sync complete!")
            print("   ✅ Completed: \(completedCount)")
            print("   ❌ Failed: \(failedCount)")
            self?.isSyncing = false
        }
    }
    
    private func saveFinancialContributions(
        financialData: FinancialContributionsResponse,
        for topic: String,
        category: String,
        context: NSManagedObjectContext,
        completion: @escaping (Bool) -> Void
    ) {
        context.perform {
            let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
            request.predicate = NSPredicate(format: "topic == %@ AND category == %@", topic, category)
            request.fetchLimit = 1
            
            do {
                guard let qa = try context.fetch(request).first else {
                    print("❌ No QueryAnswerObject found for topic: \(topic)")
                    completion(false)
                    return
                }
                
                // Create the FinancialContributionsOverview object
                let financialContributions = FinancialContributionsOverview(context: context)
                
                // Map all the fields from the response to Core Data
                financialContributions.topic = financialData.topic
                financialContributions.normalized_topic_name = financialData.normalizedTopicName
                financialContributions.timestamp = financialData.timestamp
                financialContributions.committee_id = financialData.committeeId
                financialContributions.committee_name = financialData.committeeName
                financialContributions.cycle_end_year = financialData.cycleEndYear
                financialContributions.fec_financial_contributions_summary_text = financialData.fecFinancialContributionsSummaryText
                financialContributions.query_type = financialData.queryType
                financialContributions.time_range_of_data = financialData.timeRangeOfData
                
                // Set vote counts if available
                if let upvoteCount = financialData.upvoteCount {
                    financialContributions.upvote_count = Int32(upvoteCount)
                }
                if let downvoteCount = financialData.downvoteCount {
                    financialContributions.downvote_count = Int32(downvoteCount)
                }
                
                // Percent contributions
                if let percentContributions = financialData.percentContributions {
                    let percentContributionsManagedObject = FinancialContribution_PercentContributions(context: context)
                    percentContributionsManagedObject.total_to_democrats = Int64(percentContributions.totalToDemocrats)
                    percentContributionsManagedObject.total_to_republicans = Int64(percentContributions.totalToRepublicans)
                    percentContributionsManagedObject.total_contributions = Int64(percentContributions.totalContributions)
                    percentContributionsManagedObject.percent_to_democrats = percentContributions.percentToDemocrats
                    percentContributionsManagedObject.percent_to_republicans = percentContributions.percentToRepublicans
                    financialContributions.percent_contributions = percentContributionsManagedObject
                }
                
                // Contribution to Politician Totals
                if let contributionTotals = financialData.contributionTotals {
                    let contributionTotalsListManagedObject = NSMutableSet()
                    for oneContributionTotal in contributionTotals {
                        let oneContributionTotalsManagedObject = FinancialContribution_ContributionTotals_ListItem(context: context)
                        oneContributionTotalsManagedObject.number_of_contributions = Int32(oneContributionTotal.numberOfContributions ?? 0)
                        oneContributionTotalsManagedObject.recipient_id = oneContributionTotal.recipientID
                        oneContributionTotalsManagedObject.recipient_name = oneContributionTotal.recipientName
                        oneContributionTotalsManagedObject.total_contribution_amount = Int32(oneContributionTotal.totalContributionAmount ?? 0)
                        contributionTotalsListManagedObject.add(oneContributionTotalsManagedObject)
                    }
                    financialContributions.contributions_totals_list = contributionTotalsListManagedObject
                }
                
                // Contributions from Leadership to Committee
                if let leadershipContributionsToCommittee = financialData.leadershipContributionsToCommittee {
                    let leadershipContributionsToCommitteeListManagedObject = NSMutableSet()
                    for oneLeadershipContribution in leadershipContributionsToCommittee {
                        let oneLeadershipContributionManagedObject = FinancialContribution_LeadershipContributorsToCommittee_ListItem(context: context)
                        oneLeadershipContributionManagedObject.employer = oneLeadershipContribution.employer
                        oneLeadershipContributionManagedObject.name = oneLeadershipContribution.name
                        oneLeadershipContributionManagedObject.occupation = oneLeadershipContribution.occupation
                        oneLeadershipContributionManagedObject.transaction_amount = oneLeadershipContribution.transactionAmount
                        leadershipContributionsToCommitteeListManagedObject.add(oneLeadershipContributionManagedObject)
                    }
                    financialContributions.leadership_contributions_list = leadershipContributionsToCommitteeListManagedObject
                }
                
                // Attach the financial contributions to the QueryAnswerObject
                qa.finanicial_contributions_overview = financialContributions
                
                try context.save()
                print("✅ Saved financial contributions for: \(topic)")
                completion(true)
                
            } catch {
                print("❌ Failed to save financial contributions for \(topic): \(error)")
                completion(false)
            }
        }
    }
}
