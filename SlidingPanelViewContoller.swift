import UIKit



class SlidingPanelViewController : UIViewController {
    enum SideDisplayed : Int {
        case none  = 0
        case left  = 1
    }
    let autoSizingMaskWH : UIViewAutoresizing = [.flexibleWidth,.flexibleHeight]
    let alphaMinimumValue : CGFloat = 0.0
    let alphaMaximumValue : CGFloat = 0.6
    var centerView : UIView!
    var shadingView : UIView!
    var centerViewController : UIViewController!
    var leftPanelViewController : UIViewController!
    var sideDisplayed : SideDisplayed = .none
    var leftPanelMaximumWidth : CGFloat = 280
    var animationVelocity : CGFloat = 640
    var tapGestureRecognizer : UITapGestureRecognizer!
    var panGestureRecognizer : UIScreenEdgePanGestureRecognizer!
    var panTranslation : CGPoint = CGPoint.zero
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonSetting()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(centerViewController:UIViewController, leftPanelViewController : UIViewController) {
        self.init(nibName: nil,bundle: nil)
        setCenterVC(centerViewController)
        setLeftPanelVC(leftPanelViewController)
    }
    
    override func loadView() {
        super.loadView()
        let windowSize = UIScreen.main.bounds.size
        
        centerView = UIView(frame: CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height))
        centerViewController.view.frame = self.centerView.frame
        centerViewController.view.autoresizingMask = autoSizingMaskWH
        centerView.addSubview(self.centerViewController.view)
        centerView.autoresizingMask = autoSizingMaskWH
        
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height))
        self.view.addSubview(self.centerView)
        self.view.autoresizingMask = autoSizingMaskWH
        
        setGestureRecognizers()
    }
    
    override var shouldAutorotate : Bool { return true }        
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask { return self.orientationToLandscapeForRegularOrDefaultToPortrait() }
    
    func setCenterVC(_ centerVC : UIViewController) {
        centerViewController = centerVC
        self.addChildViewController(centerViewController)
        centerViewController.didMove(toParentViewController: self)
        if isViewLoaded {
            centerViewController.view.frame = centerVC.view.frame
            centerViewController.view.autoresizingMask = autoSizingMaskWH
            self.centerView.addSubview(self.centerViewController.view)
        }
        shadingView = UIView(frame: centerViewController.view.frame)
        shadingView.backgroundColor = UIColor.black
        shadingView.alpha = alphaMinimumValue
        shadingView.autoresizingMask = autoSizingMaskWH
        centerViewController.view.addSubview(shadingView)

    }
    
    func setLeftPanelVC(_ leftPanelVC : UIViewController) {
        var reloadPanel : Bool = false
        func setController() {
            leftPanelViewController = leftPanelVC
            self.addChildViewController(leftPanelViewController)
            leftPanelViewController.didMove(toParentViewController: self)
            if reloadPanel {
                loadLeftPanel()
            }
        }
        if isViewLoaded && self.sideDisplayed == .left {
            unloadLeftPanel()
            reloadPanel = true
        }
        setController();

    }
    
    func commonSetting() {
        let screenWidth = UIScreen.main.bounds.size.width
        leftPanelMaximumWidth = (UIDevice.current.userInterfaceIdiom == .phone) ?  screenWidth * 0.85 : screenWidth * 0.3
        animationVelocity = screenWidth * 2.5
    }
    
    func loadLeftPanel() {
        if sideDisplayed != .none {
            unloadLeftPanel()
        }
        
        leftPanelViewController.view.frame = CGRect(x: 0, y: 0, width: leftPanelMaximumWidth, height: self.view.bounds.size.height)
        leftPanelViewController.view.autoresizingMask = autoSizingMaskWH
        
        self.view.addSubview(leftPanelViewController.view)
        self.view.sendSubview(toBack: leftPanelViewController.view)
        sideDisplayed = .left
    }
    
    func unloadLeftPanel() {
        leftPanelViewController.view.removeFromSuperview()
        sideDisplayed = .none
    }
    
    
}

// Drawing and Transition

extension SlidingPanelViewController {
    func adjustShadingViewVisible() {
        if (sideDisplayed == .left) {
            shadingView.alpha = alphaMaximumValue*percentageVisibleOfDisplayedPanel()
        } else {
            shadingView.alpha = alphaMinimumValue
        }
    }
    
    func percentageVisibleOfDisplayedPanel() -> CGFloat {
        if (sideDisplayed == .left) {
            return centerView.frame.origin.x / leftPanelMaximumWidth
        }
        
        return 0.0;
    }
    
    func openPanel() {
        UserTrackingService.sharedInstance().trackAction(ofTypeMetricNamed: "action.profile", forStatus: "mybooking")
        
        let centerViewSize : CGSize = self.centerView.frame.size
        
        func animationBlock() -> Void {
            var frame : CGRect
            var x : CGFloat
            shadingView.alpha = alphaMaximumValue
            
            if leftPanelViewController.view.frame.size.width != leftPanelMaximumWidth {
                frame = leftPanelViewController.view.frame
                frame.size.width = leftPanelMaximumWidth
                leftPanelViewController.view.frame = frame
            }
            x = leftPanelMaximumWidth
            centerView.frame = CGRect(x: x, y: 0, width: centerViewSize.width, height: centerViewSize.height)
        }
        
        func completionBlock(_ finished:Bool) -> Void {
            if finished {
                self.panGestureRecognizer.edges = UIRectEdge.right
            }
        }
        
        func openPanelBlock() {
            let animationLength : CGFloat = leftPanelMaximumWidth - centerView.frame.origin.x
            loadLeftPanel()
            adjustShadingViewVisible()
            UIView.animate(withDuration: animationDurationForLength(animationLength), animations: animationBlock, completion: completionBlock)
            
        }
        openPanelBlock()
    }
    
    func animationDurationForLength(_ length:CGFloat) -> TimeInterval {
        return Double(abs(length) / self.animationVelocity)
    }
    
    func closePanel() {
        closePanel { (finished) in
            self.shadingView.alpha = self.alphaMinimumValue
        }
    }
    
    func closePanel(_ completeHandler : @escaping () -> Void) {
        let centerViewSize : CGSize = self.centerView.frame.size
        var animationLength : CGFloat = self.centerView.frame.origin.x
        
        func animationBlock() -> Void {
            shadingView.alpha = alphaMinimumValue
            centerView.frame = CGRect(x: 0, y: 0, width: centerViewSize.width, height: centerViewSize.height)
        }
        
        func completionBlock(_ finished:Bool) -> Void {
            if finished {
                unloadLeftPanel()
                adjustShadingViewVisible()
                completeHandler()
                self.panGestureRecognizer.edges = UIRectEdge.left
                NotificationCenter.default.post(name: NSNotification.Name("OnAskToRefresh"), object: nil)
            }
        }
        
        UIView.animate(withDuration: animationDurationForLength(animationLength), animations: animationBlock, completion: completionBlock)
    }
}

// Gesture

extension SlidingPanelViewController : UIGestureRecognizerDelegate {
    func setGestureRecognizers() {
        if self.panGestureRecognizer == nil {
            self.panGestureRecognizer = UIScreenEdgePanGestureRecognizer.init(target: self, action: #selector(self.panGestureRecognized(_:)))
            self.panGestureRecognizer.edges = UIRectEdge.left
            self.panGestureRecognizer.delegate = self
            self.panGestureRecognizer.minimumNumberOfTouches = 1
            self.panGestureRecognizer.maximumNumberOfTouches = 1
        }
        
        if self.tapGestureRecognizer == nil {
            self.tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.tapGestureRecognized(_:)))
            self.tapGestureRecognizer.delegate = self
            self.tapGestureRecognizer.numberOfTapsRequired = 1
            self.tapGestureRecognizer.numberOfTouchesRequired = 1
        }
        
        self.view.addGestureRecognizer(self.panGestureRecognizer)
        self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if checkCenterViewTouched(touch) {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func tapGestureRecognized(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if sideDisplayed == .left {
            closePanel()
        }
    }
    
    func panGestureRecognized(_ panGestureRecognizer: UIPanGestureRecognizer) {
        
        if panGestureRecognizer.state == .began {
            panTranslation = CGPoint.zero
        }
        
        let translationX : CGFloat = panGestureRecognizer.translation(in: self.view).x - panTranslation.x
        panTranslation = panGestureRecognizer.translation(in: self.view)
        var currentCenterViewFrame : CGRect = self.centerView.frame
        currentCenterViewFrame.origin.x += translationX
        
        let newCenterViewFrame : CGRect = panGestureVerifyAuthorizationForNewCenterViewFrame(currentCenterViewFrame)
        adjustShadingViewVisible()
        self.centerView.frame = newCenterViewFrame
        
        if panGestureRecognizer.state == .ended {
            if sideDisplayed == .left {
                if self.centerView.frame.origin.x <= leftPanelMaximumWidth / 2 {
                    closePanel()
                } else {
                    openPanel()
                }
            } else {
                closePanel()
            }
        }
        
    }
    
    func panGestureVerifyAuthorizationForNewCenterViewFrame(_ centerViewFrame: CGRect) -> CGRect{
        var newCenterViewFrame : CGRect = centerViewFrame
        
        if centerViewFrame.origin.x > leftPanelMaximumWidth {
            newCenterViewFrame.origin.x = leftPanelMaximumWidth
        } else if centerViewFrame.origin.x < 0{
            newCenterViewFrame.origin.x = 0
        }
        
        if centerView.frame.origin.x <= 0 && centerViewFrame.origin.x > 0 {
            loadLeftPanel()
        } else if centerView.frame.origin.x >= 0 && centerViewFrame.origin.x < 0 {
            newCenterViewFrame.origin.x = 0
        }
        
        return newCenterViewFrame
    }
    
    func checkCenterViewTouched(_ touch : UITouch) -> Bool {
        let centerViewFrame : CGRect = centerView.frame
        let touchPoint : CGPoint = touch.location(in: self.view)
        return centerViewFrame.contains(touchPoint)
    }
}
