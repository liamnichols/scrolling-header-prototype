import UIKit

protocol ContentViewControllerDelegate: class {

    func contentViewControllerDidLoad(viewController: ContentViewController)
}

class ContentViewController: UIViewController {

    weak var delegate: ContentViewControllerDelegate?

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
        return tableView
    }()

    var scrollView: UIScrollView {
        return tableView
    }

    let itemCount: Int

    init(itemCount: Int,
         delegate: ContentViewControllerDelegate? = nil) {

        self.itemCount = itemCount
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        view.addSubview(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])

        delegate?.contentViewControllerDidLoad(viewController: self)
    }

    @objc private func refresh(_ sender: UIRefreshControl) {

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            sender.endRefreshing()
        }
    }
}

extension ContentViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let dequeued = tableView.dequeueReusableCell(withIdentifier: "Cell") {
            cell = dequeued
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        }

        cell.textLabel?.text = "Item \(indexPath.row + 1)"

        return cell
    }
}
