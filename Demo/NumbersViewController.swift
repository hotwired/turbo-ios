import UIKit

/// A simple native table view controller to demonstrate loading non-Turbo screens
/// for a visit proposal
final class NumbersViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Numbers"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        100
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let number = indexPath.row + 1
        cell.textLabel?.text = "Row \(number)"

        return cell
    }
}
