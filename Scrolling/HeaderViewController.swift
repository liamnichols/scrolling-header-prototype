import UIKit

final class HeaderViewController: UIViewController {

    static let expandedHeight: CGFloat = 180.0
    static let collapsedHeight: CGFloat = 44.0

    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.frame = view.frame
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .orange
        view.addSubview(debugLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        debugLabel.text = "\(view.frame.height)"
    }
}
