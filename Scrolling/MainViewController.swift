import UIKit

private let headerViewExpandedHeight: CGFloat = 180.0
private let headerViewCompressedHeight: CGFloat = 44.0

class MainViewController: UIViewController, ContentViewControllerDelegate {

    private lazy var contentViewControllers: [ContentViewController] = [
        ContentViewController(itemCount: 200, delegate: self),
        ContentViewController(itemCount: 5, delegate: self),
        ContentViewController(itemCount: 60, delegate: self),
    ]

    private lazy var pageViewController: UIPageViewController = {
        let viewController = UIPageViewController(transitionStyle: .scroll,
                                                  navigationOrientation: .horizontal,
                                                  options: nil)
        viewController.delegate = self
        viewController.dataSource = self
        viewController.setViewControllers([self.contentViewControllers[1]],
                                          direction: .forward,
                                          animated: false,
                                          completion: nil)
        return viewController
    }()

    private lazy var headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .cyan
        view.autoresizingMask = [.flexibleWidth]
        view.frame = CGRect(x: CGFloat(),
                            y: self.view.safeAreaInsets.top,
                            width: self.view.bounds.width,
                            height: headerViewExpandedHeight)
        return view
    }()

    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var observers = [NSKeyValueObservation]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        // Add the UIPageViewController as a child view controller.
        addChildViewController(pageViewController)
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.view.frame = view.bounds
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParentViewController: self)

        // The header view is then positioned on top of any content.
        view.addSubview(headerView)

        headerView.addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            debugLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        // Make sure the gestures are set up initially
        updateGestureRecognizers()
    }

    func contentViewControllerDidLoad(viewController: ContentViewController) {

        // Once the UIPageViewController loads and adds a ContentViewController
        //  we get notified by this callback so we can then become the delegate
        //  and perform any additional setup that we need to.
        viewController.scrollView.delegate = self
        viewController.scrollView.contentInset.top = headerViewExpandedHeight + view.safeAreaInsets.top
        viewController.scrollView.scrollIndicatorInsets.top = headerViewExpandedHeight + view.safeAreaInsets.top
        viewController.scrollView.contentOffset.y = -(headerViewExpandedHeight + view.safeAreaInsets.top)
        viewController.scrollView.isDirectionalLockEnabled = true

        // Add an observer to the contentSize of each scroll view.
        //  If it's less than the screen height then we need to extend it so that
        //  we can still scroll the header to it's collapsed height.
        let observation = viewController.scrollView.observe(\.contentSize) { [weak self] object, _ in
            self?.updateContentBottomInsets(scrollViews: [object])
        }
        observers.append(observation)
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        contentViewControllers
            .filter { $0.isViewLoaded }
            .map { $0.scrollView }
            .forEach { scrollView in

                // Check if we're at the top so that we know to scroll back to the top after if we need to
                let isAtTop = scrollView.contentOffset.y == -scrollView.contentInset.top

                // Update the content inset to account for the change in safe area
                scrollView.contentInset.top = headerViewExpandedHeight + view.safeAreaInsets.top
                scrollView.scrollIndicatorInsets.top = headerViewExpandedHeight + view.safeAreaInsets.top

                // Only change contentOffset if we were at the top before
                if isAtTop {
                    scrollView.contentOffset.y = -(headerViewExpandedHeight + view.safeAreaInsets.top)
                }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // If the view's bounds change, we need to check the bottom inset height
        // again to make sure that everythign is is still fitting nicely.
        updateContentBottomInsets()
    }

    deinit {

        // Remove any KVO observers that we had attached to the child view
        //  controllers from when we listened for contentSize changes.
        observers.forEach { $0.invalidate() }
        observers.removeAll()
    }

    private func getContentViewController(_ viewControllers: [UIViewController]?) -> ContentViewController? {
        return viewControllers?.first as? ContentViewController
    }

    private func updateContentBottomInsets(scrollViews: [UIScrollView]? = nil) {

        // The top inset that the header will take in it's compressed state
        let headerInset = headerViewCompressedHeight + view.safeAreaInsets.top

        // Use the specified scroll view's or get all of the
        //  loaded scroll view's from each ContnetViewController
        //  if nil is passed.
        let scrollViews = scrollViews ?? contentViewControllers
            .filter { $0.isViewLoaded }
            .map { $0.scrollView }

        // For each loaded scroll view, update it's bottom contentInset
        //  so that the scrollView can collapse the header even if there
        //  is not enough internal content to scroll that much.
        scrollViews.forEach { $0.contentInset.bottom = max(0, ($0.frame.height - headerInset) - $0.contentSize.height) }
    }

    private func updateGestureRecognizers() {

        // Get the current scroll view for comparison
        let currentScrollView = getContentViewController(pageViewController.viewControllers)?.scrollView

        // Loop all loaded view controllers and update gestures
        contentViewControllers
            .filter { $0.isViewLoaded }
            .map { $0.scrollView }
            .forEach { scrollView in

                // Install if it's the current or remove otherwise
                if scrollView === currentScrollView {
                    self.view.addGestureRecognizer(scrollView.panGestureRecognizer)
                } else {
                    self.view.removeGestureRecognizer(scrollView.panGestureRecognizer)
                }
        }
    }
}

extension MainViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // Make sure that it's the visible scrollView being scrolled (and not a contentOffset adjustment)
        guard scrollView === getContentViewController(pageViewController.viewControllers)?.scrollView else {
            return
        }

        // Calculate the height that the header view should take
        let base = (-1 * scrollView.contentOffset.y) - view.safeAreaInsets.top
        let height = max(headerViewCompressedHeight, min(headerViewExpandedHeight, base))

        // Update the header view with the correct height
        debugLabel.text = "\(height)"
        headerView.frame = CGRect(x: 0.0,
                                  y: view.safeAreaInsets.top,
                                  width: view.frame.width,
                                  height: height)
    }
}

extension MainViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = getContentViewController(pendingViewControllers) else { return }

        // Make sure that the contentOffset is moved up to match where the header if incase
        //  it has changed on a previous view and we don't have the content to fill it.
        if viewController.scrollView.contentOffset.y < -headerView.frame.maxY {
            viewController.scrollView.contentOffset.y = -headerView.frame.maxY
        }

        // If this view controller had previouslly compressed the header by scrolling but
        //  the previous view controllers had expanded the header again, we need to move
        //  the contentOffset back so that the top sits below the header perfectly.
        if viewController.scrollView.contentOffset.y > headerView.frame.maxY {
            viewController.scrollView.contentOffset.y = -headerView.frame.maxY
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {

        // Update the gesture recognizers because we need the current scrollview's
        //  pan gesture to be added to self.view so that we can scroll the header.
        updateGestureRecognizers()
    }
}

extension MainViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewController = getContentViewController([viewController]) else { return nil }

        if let index = contentViewControllers.index(of: viewController), (index - 1) >= 0 {
            return contentViewControllers[index - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewController = getContentViewController([viewController]) else { return nil }

        if let index = contentViewControllers.index(of: viewController), (index + 1) < contentViewControllers.count {
            return contentViewControllers[index + 1]
        }
        return nil
    }
}
