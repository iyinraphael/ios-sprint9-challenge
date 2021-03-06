//
//  CalorieTableViewController.swift
//  Calorie Tracker
//  Created by Iyin Raphael on 10/26/18.
//  Copyright © 2018 Iyin Raphael. All rights reserved.
//

import UIKit
import CoreData
import SwiftChart

extension NSNotification.Name{
    static let entryWasAdded = NSNotification.Name("CalorieWasAdded")
}

class CalorieTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        notificationCentre.addObserver(self, selector: #selector(calorieWasAdded), name: .entryWasAdded, object: nil)
        entryController.fetchEntriesFromServer { (_) in
            DispatchQueue.main.async {
                self.createChart()
                self.tableView.reloadData()
            }
        }
        view.backgroundColor = .cyan
    }
    // MARK: - Notification
    @objc func calorieWasAdded(_ notification: Notification){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

   
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let entry = fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = "\(entry.calories) calories"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        cell.detailTextLabel?.text = formatter.string(from: entry.date!)
        
        return cell
    }

    func createChart(){
        guard let entries = fetchedResultsController.sections?.first?.objects else {
            NSLog("No entries to show")
            return
        }
        for entry in entries{
            if let entry = entry as? Entry{
                data.append((data.count, Double(entry.calories)))
            }
        }
        chart.add(ChartSeries(data: data))
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        case .move:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    @IBAction func addCalorie(_ sender: Any) {
        let alert = UIAlertController(title: "Add Calorie Intake", message: "Enter the amount of calories intake today", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            guard let input = alert.textFields?[0].text,
                let calories = Int(input) else {return}
            let entry = self.entryController.createCalorie(calories: calories)
            self.entryController.put(entry: entry)
            self.data.append((x: self.data.count, y: Double(calories)))
            self.chart.add(ChartSeries(data: self.data))
            self.notificationCentre.post(name: .entryWasAdded, object: self)
            
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter Calories"
        }
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert,animated:true, completion:nil)
    }
    
    @IBOutlet weak var chart: Chart!
    private let entryController = EntryController()
    private let notificationCentre = NotificationCenter.default
    private var data:[(Int, Double)] = []
    
    lazy var fetchedResultsController:NSFetchedResultsController<Entry> = {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: moc,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
}
