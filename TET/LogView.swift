//
//  LogTable.swift
//  TET
//
//  Created by Raymond Li on 12/23/16.
//  Copyright © 2016 Raymond Li. All rights reserved.
//

import UIKit
class LogView: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var curTrip: Trip!
    var expenses = [SingleExpense]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var drop: DropMenuButton!
    
    var displayPastTrip: String!
    var pastTrips: [Trip] = [Trip]()
    var whichPastTrip: Int!
    var selectedRow: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.separatorColor = UIColor.darkGray
        
        let nib = UINib(nibName: "ExpenseCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ExpenseCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        
        let tabcont: TabVC = self.tabBarController as! TabVC
        displayPastTrip = tabcont.displayPastTrip
        selectedRow = 0
        
        if displayPastTrip == "Yes" {
            if let decoded = UserDefaults.standard.object(forKey: "pastTrips") as? Data {
                pastTrips = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Trip]
            }
            whichPastTrip = UserDefaults.standard.integer(forKey: "whichPastTrip")
            curTrip = pastTrips[whichPastTrip]
        }
        else {
            if let decoded = UserDefaults.standard.object(forKey: "currentTrip") as? Data {
                curTrip = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? Trip
            }
        }
        
        expenses = curTrip.expensesLog
        
        drop.initMenu(["Date: Oldest First", "Date: Newest First", "Category", "Amount: Highest to Lowest", "Amount: Lowest to Highest"], actions: [({ () -> (Void) in
            self.curTrip.orderBy = "Date: Oldest First"
            self.sortExpensesBy(order: "Date: Oldest First")
            self.tableView.reloadData()
        }), ({ () -> (Void) in
            self.curTrip.orderBy = "Date: Newest First"
            self.sortExpensesBy(order: "Date: Newest First")
            self.tableView.reloadData()
        }), ({ () -> (Void) in
            self.curTrip.orderBy = "Category"
            self.sortExpensesBy(order: "Category")
            self.tableView.reloadData()
        }), ({ () -> (Void) in
            self.curTrip.orderBy = "Amount: Highest to Lowest"
            self.sortExpensesBy(order: "Amount: Highest to Lowest")
            self.tableView.reloadData()
        }), ({ () -> (Void) in
            self.curTrip.orderBy = "Amount: Lowest to Highest"
            self.sortExpensesBy(order: "Amount: Lowest to Highest")
            self.tableView.reloadData()
        })])
        
        if curTrip.orderBy == "Category" {
            sortExpensesBy(order: "Category")
        } else if curTrip.orderBy == "Amount: Highest to Lowest" {
            sortExpensesBy(order: "Amount: Highest to Lowest")
        } else if curTrip.orderBy == "Amount: Lowest to Highest" {
            sortExpensesBy(order: "Amount: Lowest to Highest")
        } else if curTrip.orderBy == "Date: Newest First" {
            sortExpensesBy(order: "Date: Newest First")
        } else {
            sortExpensesBy(order: "Date: Oldest First")
        }
        
        drop.setTitle(curTrip.orderBy, for: .normal)
        
        tableView.reloadData()
    }
    
    func sortExpensesBy(order: String) {
        var sortedExpenses = [SingleExpense]()
        if expenses.count > 1 {
            sortedExpenses.append(expenses[0])
        } else {
            let userDefaults = UserDefaults.standard
            if displayPastTrip == "Yes" {
                pastTrips.remove(at: whichPastTrip)
                pastTrips.insert(curTrip, at: whichPastTrip)
                let encodedPT: Data = NSKeyedArchiver.archivedData(withRootObject: pastTrips)
                userDefaults.set(encodedPT, forKey: "pastTrips")
            } else {
                let encoded: Data = NSKeyedArchiver.archivedData(withRootObject: curTrip)
                userDefaults.set(encoded, forKey: "currentTrip")
            }
            userDefaults.synchronize()
            return
        }
        if order == "Date: Newest First" {
            for i in 1..<expenses.count {
                for j in 0..<sortedExpenses.count {
                    let check: Int! = whichDateOlder(date1: expenses[i].date, date2: sortedExpenses[j].date)
                    //Insert if expenses date is newer than sortedDate
                    if check == -1 {
                        sortedExpenses.insert(expenses[i], at: j)
                        break;
                    } else if check == 0 {
                        //Subsort by type
                        let check1: Int! = checkTypeOrder(t1: expenses[i].type, t2: sortedExpenses[j].type)
                        if check1 == 1 {
                            sortedExpenses.insert(expenses[i], at: j)
                            break;
                        }
                    }
                    if j == sortedExpenses.count - 1 {
                        sortedExpenses.append(expenses[i])
                    }
                }
            }
        } else if order == "Date: Oldest First" {
            for i in 1..<expenses.count {
                for j in 0..<sortedExpenses.count {
                    let check: Int! = whichDateOlder(date1: expenses[i].date, date2: sortedExpenses[j].date)
                    //Insert if expenses date is older than sortedDate
                    if check == 1 {
                        sortedExpenses.insert(expenses[i], at: j)
                        break;
                    } else if check == 0 {
                        //Subsort by type
                        let check1: Int! = checkTypeOrder(t1: expenses[i].type, t2: sortedExpenses[j].type)
                        if check1 == 1 {
                            sortedExpenses.insert(expenses[i], at: j)
                            break;
                        }
                    }
                    if j == sortedExpenses.count - 1 {
                        sortedExpenses.append(expenses[i])
                    }
                }
            }
        } else if order == "Category" {
            for i in 1..<expenses.count {
                for j in 0..<sortedExpenses.count {
                    let check: Int! = checkTypeOrder(t1: expenses[i].type, t2: sortedExpenses[j].type)
                    if check == 1 {
                        sortedExpenses.insert(expenses[i], at: j)
                        break;
                    } else if check == 0 {
                        //Subsort by date
                        let dateCheck: Int! = whichDateOlder(date1: expenses[i].date, date2: sortedExpenses[j].date)
                        if dateCheck == 1 {
                            sortedExpenses.insert(expenses[i], at: j)
                            break;
                        }
                    }
                    if j == sortedExpenses.count - 1 {
                            sortedExpenses.append(expenses[i])
                    }
                }
            }
        } else if order == "Amount: Highest to Lowest" {
            for i in 1..<expenses.count {
                for j in 0..<sortedExpenses.count {
                    let ae: String! = truncateAmount(amount: expenses[i].amount)
                    let ase: String! = truncateAmount(amount: sortedExpenses[j].amount)
                    if Double(ae)! > Double(ase)! {
                        sortedExpenses.insert(expenses[i], at: j)
                        break;
                    } else if Double(ae)! == Double(ase)! {
                        //Subsort by type
                        let check: Int! = checkTypeOrder(t1: expenses[i].type, t2: sortedExpenses[j].type)
                        if check == 1 {
                            sortedExpenses.insert(expenses[i], at: j)
                            break;
                        }
                    }
                    if j == sortedExpenses.count - 1 {
                        sortedExpenses.append(expenses[i])
                    }
                }
            }
        } else if order == "Amount: Lowest to Highest" {
            for i in 1..<expenses.count {
                for j in 0..<sortedExpenses.count {
                    let ae: String! = truncateAmount(amount: expenses[i].amount)
                    let ase: String! = truncateAmount(amount: sortedExpenses[j].amount)
                    if Double(ae)! < Double(ase)! {
                        sortedExpenses.insert(expenses[i], at: j)
                        break;
                    } else if Double(ae)! == Double(ase)! {
                        //Subsort by type
                        let check: Int! = checkTypeOrder(t1: expenses[i].type, t2: sortedExpenses[j].type)
                        if check == 1 {
                            sortedExpenses.insert(expenses[i], at: j)
                            break;
                        }
                    }
                    if j == sortedExpenses.count - 1 {
                        sortedExpenses.append(expenses[i])
                    }
                }
            }
        }
        expenses = sortedExpenses
        curTrip.expensesLog = expenses
        let userDefaults = UserDefaults.standard
        if displayPastTrip == "Yes" {
            pastTrips.remove(at: whichPastTrip)
            pastTrips.insert(curTrip, at: whichPastTrip)
            let encodedPT: Data = NSKeyedArchiver.archivedData(withRootObject: pastTrips)
            userDefaults.set(encodedPT, forKey: "pastTrips")
        } else {
            let encoded: Data = NSKeyedArchiver.archivedData(withRootObject: curTrip)
            userDefaults.set(encoded, forKey: "currentTrip")
        }
        userDefaults.synchronize()
    }
    
    //returns 1 if date1 is older than date2, -1 is newer, 0 is same
    func whichDateOlder(date1: String, date2: String) -> Int {
        let date1Array = parseDate(date: date1)
        let date2Array = parseDate(date: date2)
        
        let oMon: Int = date1Array[1]
        let oDay: Int = date1Array[0]
        let oYear: Int = date1Array[2]
        let nMon: Int = date2Array[1]
        let nDay: Int = date2Array[0]
        let nYear: Int = date2Array[2]
        
        if nYear > oYear {
            return 1
        } else if nYear == oYear {
            if nMon > oMon {
                return 1
            } else if nMon == oMon {
                if nDay > oDay {
                    return 1
                } else if nDay == oDay {
                    return 0
                }
            }
        }
        return -1
    }
    
    //Take in Feb 1, 2018 and return [1, 2, 2018]
    func parseDate(date: String) -> [Int] {
        let dateArray = date.components(separatedBy: ",")
        let yearInt = Int(dateArray[1].suffix(4))!
        let monthInt = monthToInt(mon: String(dateArray[0].prefix(3)))
        let dayInt = Int(dateArray[0].suffix(from: dateArray[0].index(dateArray[0].startIndex, offsetBy: 4)))!
        
        return [dayInt, monthInt, yearInt]
    }
    
    func monthToInt(mon: String) -> Int {
        switch mon {
        case "Jan":
            return 1
        case "Feb":
            return 2
        case "Mar":
            return 3
        case "Apr":
            return 4
        case "May":
            return 5
        case "Jun":
            return 6
        case "Jul":
            return 7
        case "Aug":
            return 8
        case "Sep":
            return 9
        case "Oct":
            return 10
        case "Nov":
            return 11
        case "Dec":
            return 12
        default:
            return 0
        }
    }
    
    /* Return 1 is t1 comes before t2, 0 if same type, and -1 is t1 comes after t2
    *  Ordering is Transportation, Living, Eating, Entertainment, Souvenir, Other
    */
    func checkTypeOrder(t1: String, t2: String) -> Int {
        let ordering = ["Transportation", "Living", "Eating", "Entertainment", "Souvenir", "Other"]
        var t1Int = 0
        var t2Int = 0
        
        for i in 0..<ordering.count {
            if t1 == ordering[i] {
                t1Int = i
            }
            if t2 == ordering[i] {
                t2Int = i
            }
        }
        
        if t1Int < t2Int {
            return 1
        } else if t1Int > t2Int {
            return -1
        }
        return 0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        drop.showItems()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell") as? ExpenseCell {
            let dateL = expenses[indexPath.row].date
            let titleL = expenses[indexPath.row].expenseTitle
            let typeL = expenses[indexPath.row].type
            let amountL = expenses[indexPath.row].amount
            
            var labelColor: UIColor = .black
            
            switch typeL {
            case "Transportation":
                labelColor = .blue
            case "Living":
                labelColor = UIColor(red: 153/255, green: 0, blue: 51/255, alpha: 1)
            case "Eating":
                labelColor = .orange
            case "Entertainment":
                labelColor = UIColor(red: 0, green: 102/255, blue: 0, alpha: 1)
            case "Souvenir":
                labelColor = .darkGray
            case "Other":
                //labelColor = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
                labelColor = .purple
            default:
                labelColor = .black
            }
            
            cell.titleLabel.text = titleL
            cell.dateLabel.text = dateL
            cell.amountLabel.text = amountL
            cell.typeLabel.text = typeL
            
            cell.titleLabel.textColor = labelColor
            cell.dateLabel.textColor = labelColor
            cell.amountLabel.textColor = labelColor
            cell.typeLabel.textColor = labelColor
            
            cell.titleLabel.adjustsFontSizeToFitWidth = true
            cell.dateLabel.adjustsFontSizeToFitWidth = true
            cell.amountLabel.adjustsFontSizeToFitWidth = true
            cell.typeLabel.adjustsFontSizeToFitWidth = true
            
            cell.backgroundColor = UIColor(red: 184/255, green: 252/255, blue: 205/255, alpha: 1)
            
            return cell
        } else {
            return ExpenseCell()
        }
    }
    
    //Delete and Edit swipe
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let editExpense = UITableViewRowAction(style: .normal, title: "Edit") { action, index in
            self.selectedRow = editActionsForRowAt.row
            self.performSegue(withIdentifier: "toEditExpense", sender: self)
        }
        editExpense.backgroundColor = .lightGray
        
        let deleteExpense = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            let prevExp: SingleExpense = self.expenses[editActionsForRowAt.row]
            self.expenses.remove(at: editActionsForRowAt.row)
            self.curTrip.expensesLog = self.expenses
            let pA: String = prevExp.amount
            let prevAmount: String! = String(pA.suffix(from: pA.index(pA.startIndex, offsetBy: 1)))
            self.subtractFromCurrentTrip(type: prevExp.type, amount: Double(prevAmount)!)
            
            let userDefaults = UserDefaults.standard
            if self.displayPastTrip == "Yes" {
                self.pastTrips.remove(at: self.whichPastTrip)
                self.pastTrips.insert(self.curTrip, at: self.whichPastTrip)
                let encodedPT: Data = NSKeyedArchiver.archivedData(withRootObject: self.pastTrips)
                userDefaults.set(encodedPT, forKey: "pastTrips")
            } else {
                let encoded: Data = NSKeyedArchiver.archivedData(withRootObject: self.curTrip)
                userDefaults.set(encoded, forKey: "currentTrip")
            }
            userDefaults.synchronize()
            
            self.tableView.reloadData()
        }
        deleteExpense.backgroundColor = .red
        
        return [deleteExpense, editExpense]
    }
    
    func subtractFromCurrentTrip(type: String, amount: Double) {
        if type == "Transportation" {
            curTrip.transportationCost! -= Double(amount)
        } else if type == "Living" {
            curTrip.livingCost! -= Double(amount)
        } else if type == "Eating" {
            curTrip.eatingCost! -= Double(amount)
        } else if type == "Entertainment" {
            curTrip.entertainmentCost! -= Double(amount)
        } else if type == "Souvenir" {
            curTrip.souvenirCost! -= Double(amount)
        } else if type == "Other" {
            curTrip.otherCost! -= Double(amount)
        }
        curTrip.totalCost! -= Double(amount)
    }
    
    //Called when user taps on a cell. Performs segue to detailed comment.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "toDetailedExpense", sender: self)
    }
    
    //Called before the segue is executed. Sets the comment of the detailed expense.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toEditExpense" {
            let upcoming: EditExpense = segue.destination as! EditExpense
            
            let oldDateArray: [Int] = parseDate(date: expenses[selectedRow].date)
            
            upcoming.oldMon = oldDateArray[1]
            upcoming.oldDay = oldDateArray[0]
            upcoming.oldYear = oldDateArray[2]
            upcoming.oldType = expenses[selectedRow].type
            upcoming.oldTypeInt = getNumberFromType(type: expenses[selectedRow].type)
            upcoming.oldAmount = expenses[selectedRow].amount
            upcoming.oldExpenseTitle = expenses[selectedRow].expenseTitle
            upcoming.oldComment = expenses[selectedRow].expenseComment
            upcoming.currentExpenseRow = selectedRow
            upcoming.displayPastTrip = displayPastTrip
        } else if segue.identifier == "toDetailedExpense" {
            let upcoming: DetailedExpense = segue.destination as! DetailedExpense
            let indexPath = self.tableView.indexPathForSelectedRow!
            
            upcoming.titleT = expenses[indexPath.row].expenseTitle
            upcoming.comment = expenses[indexPath.row].expenseComment
            upcoming.dateT = expenses[indexPath.row].date
            upcoming.typeT = expenses[indexPath.row].type
            upcoming.amountT = expenses[indexPath.row].amount
            upcoming.displayPastTrip = displayPastTrip
            upcoming.currentExpenseRow = indexPath.row
        }
    }
    
    //Gets rid of dollar sign at the beginning
    func truncateAmount(amount: String) -> String {
        return String(amount.suffix(from: amount.index(amount.startIndex, offsetBy: 1)))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if expenses.count == 0 {
            self.tableView.setEmptyMessage("No expenses to show")
        } else {
            self.tableView.restore()
        }
        return expenses.count
    }
    
    func getNumberFromType(type: String) -> Int {
        if type == "Transportation" {
            return 0
        } else if type == "Living" {
            return 1
        } else if type == "Eating" {
            return 2
        } else if type == "Entertainment" {
            return 3
        } else if type == "Souvenir" {
            return 4
        } else if type == "Other" {
            return 5
        }
        return 0
    }
}


