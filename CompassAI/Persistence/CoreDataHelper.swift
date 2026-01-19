//
//  CoreDataHelper.swift
//  Compass AI
//
//  Created by Steve on 11/2/25.
//
import CoreData

class CoreDataHelper {
    
    class func addPersistedQueryAnswer(context: NSManagedObjectContext, analysis: OrganizationAnalysis, organizationName: String?, overviewPageCompletion: @escaping ((Bool) -> Void) ) {
        
        context.perform {
            
            let qa = QueryAnswerObject(context: context)
            qa.date_persisted = Date()
            qa.topic = organizationName ?? analysis.topic
            qa.category = analysis.category.rawValue // Important.
            qa.lean = analysis.lean
            qa.rating = Int16(analysis.rating)
            qa.context = analysis.description
            qa.created_with_financial_contributions_info = analysis.hasFinancialContributions
            
            do {
                try context.save()
                DispatchQueue.main.async {

                    let isSaved = true
                    overviewPageCompletion(isSaved)

                    // Fetch financial contributions in the background if needed
                    if qa.created_with_financial_contributions_info {
                        let topic = qa.topic ?? ""
                        
                        // Dispatch to background queue to avoid blocking
                        DispatchQueue.global(qos: .utility).async {
                            NetworkManager.shared.getFinancialContributionsOverview(for: topic) { result in
                                switch result {
                                case .success(let financialData):
                                    // Save financial contributions on a background context
                                    print("Will now fetch financial contributions")
                                    self.saveFinancialContributions(financialData: financialData, for: topic, parentContext: context)
                                    
                                case .failure(let error):
                                    print("Failed to fetch financial contributions: \(error)")
                                }
                            }
                        }
                    }
                    else {
                        print("No financial contributions to fetch")
                    }
                    
                }
            } catch {
                print("Query answer save error:", error)
                DispatchQueue.main.async {
                    overviewPageCompletion(false)
                }
            }
        }
    }
    
    private class func saveFinancialContributions(financialData: FinancialContributionsResponse, for topic: String, parentContext: NSManagedObjectContext) {
        // Create a background context for saving financial data
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = parentContext
        
        backgroundContext.perform {
            // Fetch the QueryAnswerObject to attach financial data
            let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
            request.predicate = NSPredicate(format: "topic == %@", topic)
            request.fetchLimit = 1
            
            do {
                print("Now fetching financial contributions for \(topic)")
                if let qa = try backgroundContext.fetch(request).first {
                    // Create and populate FinancialContributionsObject (adjust based on your Core Data model)
                    // You'll need to create this entity in your Core Data model if it doesn't exist
                    // Example:
                    // let financialContributions = FinancialContributionsObject(context: backgroundContext)
                    // financialContributions.topic = financialData.topic
                    // financialContributions.summaryText = financialData.fecFinancialContributionsSummaryText
                    // financialContributions.timestamp = financialData.timestamp
                    // ... set other properties ...
                    // qa.financialContributions = financialContributions
                    
                    // For now, you might store the summary text directly on QueryAnswerObject
                    // Adjust this based on your actual Core Data schema
                    
                    
                    // Create the FinancialContributionsOverview object
                    let financialContributions = FinancialContributionsOverview(context: backgroundContext)
                    
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
                    
                    // Handle leadership contributions if present
                    if let leadershipContributions = financialData.leadershipContributionsToCommittee {
                        // Convert to string for storage (you might want to use JSON encoding)
                        if let jsonData = try? JSONEncoder().encode(leadershipContributions),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
//                            financialContributions.leadership_contributors = jsonString
                        }
                    }
                    
                    
                    // Percent contributions
                    if let percent_contributions = financialData.percentContributions {
                        let percentContributionsManagedObject = FinancialContribution_PercentContributions(context: backgroundContext)
                        percentContributionsManagedObject.total_to_democrats = Int64(percent_contributions.totalToDemocrats)
                        percentContributionsManagedObject.total_to_republicans = Int64(percent_contributions.percentToRepublicans)
                        percentContributionsManagedObject.total_contributions = Int64(percent_contributions.totalContributions)
                        percentContributionsManagedObject.percent_to_democrats = percent_contributions.percentToDemocrats
                        percentContributionsManagedObject.percent_to_republicans = percent_contributions.percentToRepublicans
                        // Include all sub relations
                        financialContributions.percent_contributions = percentContributionsManagedObject

                    }
                    
                    // Contribution to Politician Totals
                    if let contribution_totals = financialData.contributionTotals {
                        let contributionTotalsListManagedObject = NSMutableSet()
                        for one_contribution_total in contribution_totals {
                            let oneContributionTotalsManagedObject = FinancialContribution_ContributionTotals_ListItem(context: backgroundContext)
                            oneContributionTotalsManagedObject.number_of_contributions = Int32(one_contribution_total.numberOfContributions ?? 0)
                            oneContributionTotalsManagedObject.recipient_id = one_contribution_total.recipientID
                            oneContributionTotalsManagedObject.recipient_name = one_contribution_total.recipientName
                            oneContributionTotalsManagedObject.total_contribution_amount = Int32(one_contribution_total.totalContributionAmount ?? 0)
                            contributionTotalsListManagedObject.add(oneContributionTotalsManagedObject)
                        }
                        // Include all sub relations
                        financialContributions.contributions_totals_list = contributionTotalsListManagedObject
                    }
                    
                    
                    // Contributions from Leadership to Committee
                    if let leadership_contributions_to_committee = financialData.leadershipContributionsToCommittee {
                        let leadershipContributionsToCommitteeListManagedObject = NSMutableSet()
                        for one_leadership_contributions_to_committee in leadership_contributions_to_committee {
                            let oneLeadershipContributionsToCommitteeManagedObject = FinancialContribution_LeadershipContributorsToCommittee_ListItem(context: backgroundContext)
                            oneLeadershipContributionsToCommitteeManagedObject.employer = one_leadership_contributions_to_committee.employer
                            oneLeadershipContributionsToCommitteeManagedObject.name = one_leadership_contributions_to_committee.name
                            oneLeadershipContributionsToCommitteeManagedObject.occupation = one_leadership_contributions_to_committee.occupation
                            oneLeadershipContributionsToCommitteeManagedObject.transaction_amount = one_leadership_contributions_to_committee.transactionAmount
                            leadershipContributionsToCommitteeListManagedObject.add(oneLeadershipContributionsToCommitteeManagedObject)
                        }
                        // Include all sub relations
                        financialContributions.leadership_contributions_list = leadershipContributionsToCommitteeListManagedObject
                    }
                    
                    
                    // Attach the financial contributions to the QueryAnswerObject
//                    qa.relationship = financialContributions
                    qa.finanicial_contributions_overview = financialContributions
                    
                    print("|FinancialContributions: ")
                    print(financialContributions)
                    
//                    print("qa")
//                    print(qa)
                    
                    
                    try backgroundContext.save()
                    
                    // Save the parent context
                    parentContext.perform {
                        do {
                            try parentContext.save()
                            print("Financial contributions saved successfully for topic: \(topic)")
                        } catch {
                            print("Failed to save parent context: \(error)")
                        }
                    }
                     
                } else {
                    print("No QueryAnswerObject found for topic: \(topic)")
                }
            } catch {
                print("Failed to save financial contributions: \(error)")
            }
        }
    }
        
    class func removePersistedQueryAnswer(context: NSManagedObjectContext, organizationName: String, completion: ((Bool) -> Void)) {
        let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@", organizationName)
        
        do {
            let results = try context.fetch(request)
            for result in results {
                context.delete(result)
            }
            try context.save()
            completion(true)
        } catch {
            print("Error removing saved analysis: \(error)")
            completion(false)
        }
    }
    
//    class func removePersistedQueryAnswer(context: NSManagedObjectContext, organizationName: String, completion: ((Bool) -> Void)) {
//        let request: NSFetchRequest<QueryAnswerObject> = QueryAnswerObject.fetchRequest()
//        request.predicate = NSPredicate(format: "topic == %@", organizationName)
//        
//        do {
//            let results = try context.fetch(request)
//            for result in results {
//                context.delete(result)
//            }
//            try context.save()
//            completion(true)
//        } catch {
//            print("Error removing saved analysis: \(error)")
//            completion(false)
//        }
//    }
    
}
