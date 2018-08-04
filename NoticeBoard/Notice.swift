//
//  Notice.swift
//  NoticeBoard
//
//  Created by xaoxuu on 2018/6/20.
//  Copyright © 2018 Titan Studio. All rights reserved.
//

import UIKit

internal let margin = CGFloat(8)
internal let padding10 = CGFloat(8)
internal let padding4 = CGFloat(4)

internal let cornerRadius = CGFloat(12)
internal let titleHeight = CGFloat(36)
internal let dragButtonHeight = CGFloat(24)

internal let maxWidth = CGFloat(500)

internal let defaultInset = UIEdgeInsets.init(top: padding10, left: padding4, bottom: padding10, right: padding4)

internal func topSafeMargin() -> CGFloat {
    if UIScreen.main.bounds.size.equalTo(CGSize.init(width: 375, height: 812)) {
        return 30 + 10;
    } else {
        return margin;
    }
}


internal func visible(_ view: UIView?) -> UIView?{
    if let v = view {
        if v.superview != nil && !v.isHidden {
            return v
        } else {
            return nil
        }
    } else {
        return nil
    }
}

internal func visible(_ view: UITextView?) -> UITextView?{
    if let v = view {
        if v.superview != nil && !v.isHidden {
            return v
        } else {
            return nil
        }
    } else {
        return nil
    }
}



private enum Tag: Int {
    typealias RawValue = Int
    
    case iconView = 101
    case titleView = 102
    case actionButton = 103
    case bodyView = 201
    case dragButton = 301
    
}

// MARK: - frame
internal extension Notice {
    
    func updateSelfFrame(){
        var totalHeight = CGFloat(0)
        if let rootView = self.rootViewController?.view {
            for view in rootView.subviews {
                if view.isEqual(self.rootViewController?.view) == false && view.isEqual(visualEffectView) == false {
                    totalHeight = max(totalHeight, view.frame.maxY)
                }
            }
            rootView.frame = CGRect.init(x: 0, y: 0, width: frame.size.width, height: totalHeight)
            self.visualEffectView?.frame = rootView.bounds
            if let p = progressLayer {
                var f = p.frame
                f.size.height = totalHeight
                p.frame = f
            }
            if self.frame.height != totalHeight {
                var f = self.frame
                f.size.height = totalHeight
                self.frame = f
            }
        }
    }
    
    private func frame(for tag: Tag) -> CGRect {
        if tag == .actionButton {
            return CGRect.init(x: self.frame.size.width-38, y: 0, width: 38, height: titleHeight)
        } else if tag == .bodyView {
            return CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        } else if tag == .dragButton {
            return CGRect.init(x: 0, y: 0, width: self.frame.width, height: dragButtonHeight)
        } else {
            return .zero
        }
    }
    func updateContentFrame(){
        if let t1 = visible(titleLabel){
            var f = t1.frame
            if let t0 = visible(iconView) {
                if self.subviews.contains(t0) == false {
                    self.rootViewController?.view.addSubview(t0)
                }
                f.origin.x = t0.frame.maxX + padding4
            }
            f.size.width = self.frame.size.width - f.origin.x - padding10
            if let v = visible(actionButton) {
                f.size.width -= v.frame.size.width
            }
            t1.frame = f
        }
        if let t1 = visible(bodyView) {
            var f = t1.frame
            if let t0 = visible(titleLabel) {
                f.origin.y = t0.frame.maxY
                bodyView?.textContainerInset.top = 0
            } else {
                bodyView?.textContainerInset = defaultInset
            }
            f.size.height = max(bodyMaxHeight, 0)
            t1.frame = f
            f.size.height = min(t1.contentSize.height, max(bodyMaxHeight, 0))
            UIView.animate(withDuration: 0.38) {
                t1.frame = f
            }
            
            if t1.contentSize.height > f.size.height {
                self.rootViewController?.view.addSubview(loadDragButton())
                if let btn = visible(dragButton) {
                    var ff = btn.frame
                    ff.origin.y = t1.frame.maxY
                    btn.frame = ff
                    btn.alpha = 1
                }
            } else {
                if let btn = visible(dragButton) {
                    btn.alpha = 0
                    btn.removeFromSuperview()
                }
            }
        }
    }
    
}

@objcMembers
open class Notice: UIWindow {

    /// 当notice被移除时的通知
    public static let didRemoved = NSNotification.Name.init("noticeDidRemoved")
    
    
    /// 主题
    public enum Theme {
        public typealias RawValue = UIColor
        case success, note, warning, error, normal, white, darkGray, plain
        public var rawValue : RawValue {
            var color = UIColor.white
            switch self {
            case .success:
                color = UIColor.ax_green
            case .note:
                color = UIColor.ax_blue
            case .warning:
                color = UIColor.ax_yellow
            case .error:
                color = UIColor.ax_red
            case .white:
                color = UIColor.white
            case .darkGray:
                color = UIColor.darkGray
            case .plain:
                color = UIColor.clear
            default:
                color = UIColor.ax_blue
            }
            return color
        }
        init () {
            self = .normal
        }

    }
    public struct NoticeAlertOptions : OptionSet {
        public var rawValue: UInt
        
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        
        // MARK: 以什么样的速度
        /// 正常速度，默认
        public static var normally: NoticeAlertOptions {
            return self.init(rawValue: 1 << 10)
        }
        
        /// 缓慢地
        public static var slowly: NoticeAlertOptions {
            return self.init(rawValue: 1 << 11)
        }
        
        /// 快速地
        public static var fast: NoticeAlertOptions {
            return self.init(rawValue: 1 << 12)
        }
        
        // MARK: 做什么样的动作
        /// 颜色变深，默认
        public static var darken: NoticeAlertOptions {
            return self.init(rawValue: 1 << 20)
        }
        
        /// 颜色变浅
        public static var lighten: NoticeAlertOptions {
            return self.init(rawValue: 1 << 21)
        }
        
        /// 闪烁（alpha: 1 -> 0）
        public static var flash: NoticeAlertOptions {
            return self.init(rawValue: 1 << 22)
        }
        
        // MARK: 重复多少次
        /// 一次，默认
        public static var once: NoticeAlertOptions {
            return self.init(rawValue: 1 << 30)
        }
        
        /// 两次
        public static var twice: NoticeAlertOptions {
            return self.init(rawValue: 1 << 31)
        }
        
        /// 呼吸灯效果
        public static var breathing: NoticeAlertOptions {
            return self.init(rawValue: 1 << 32)
        }
        
    }
    // MARK: - public property
    public var bodyMaxHeight = CGFloat(180) {
        didSet {
            updateContentFrame()
        }
    }
    
    /// 可通过手势移除通知
    public var allowRemoveByGesture = true
    
    /// 背景颜色
    public var themeColor = UIColor.ax_blue {
        didSet {
            rootViewController?.view.backgroundColor = themeColor
            tintColor = themeColor.textColor()
        }
    }
    
    /// 主题（改变背景颜色）
    public var theme = Theme.normal {
        didSet {
            themeColor = theme.rawValue
        }
    }
    
    /// 模糊效果
    public var blurEffectStyle: UIBlurEffectStyle? {
        didSet {
            if let blur = blurEffectStyle {
                // FIXME: 在iOS11之前的系统上模糊效果变成半透明，暂时不知道为什么
                if #available(iOS 11.0, *) {
                    if self.visualEffectView == nil {
                        let vev = UIVisualEffectView.init(frame: self.bounds)
                        vev.effect = UIBlurEffect.init(style: blur)
                        if blur == UIBlurEffectStyle.dark {
                            tintColor = .white
                        } else {
                            tintColor = .black
                        }
                        vev.layer.masksToBounds = true
                        self.rootViewController?.view.insertSubview(vev, at: 0)
                        if let pro = progressLayer {
                            vev.layer.addSublayer(pro)
                        }
                        self.visualEffectView = vev
                    }
                } else {
                    if blur == .dark {
                        theme = .darkGray
                    } else {
                        theme = .white
                    }
                }
            }
        }
    }
    
    // MARK: subviews
    
    public var iconView : UIImageView?
    public var titleLabel: UILabel?
    
    public var bodyView: UITextView?
    public var visualEffectView: UIVisualEffectView?
    public var dragButton: UIButton?
    public var actionButton: UIButton?
    public var progressLayer: CALayer?
    
    
    // MARK: model
    public var title: String {
        get {
            if let t = titleLabel?.text {
                return t
            } else {
                return ""
            }
        }
        set {
            self.rootViewController?.view.addSubview(loadTitleLabel())
            
            var animated = false
            if let t = titleLabel?.text {
                if t.count > 0 {
                    animated = true
                }
            }
            titleLabel?.text = newValue
            titleLabel?.textColor = tintColor
            
            actionButton?.setTitleColor(tintColor, for: .normal)
            updateContentFrame()
            
            if animated {
                UIView.animate(withDuration: 0.38, animations: {
                    self.updateSelfFrame()
                })
            } else {
                self.updateSelfFrame()
            }
        }
    }
    public var body: String {
        get {
            if let t = bodyView?.text {
                return t
            } else {
                return ""
            }
        }
        set {
            self.rootViewController?.view.addSubview(loadTextView())
            var animated = false
            if let t = bodyView?.text {
                if t.count > 0 {
                    animated = true
                }
            }
            bodyView?.text = newValue
            bodyView?.textColor = tintColor
            updateContentFrame()
            
            
            if animated {
                UIView.animate(withDuration: 0.38, animations: {
                    self.updateSelfFrame()
                }) { (completed) in
                    if let btn = self.dragButton {
                        btn.alpha = 1
                    }
                }
            } else {
                self.updateSelfFrame()
            }
            loadProgressLayer()
        }
    }
    public var icon: UIImage? {
        get {
            return iconView?.image
        }
        set {
            if let i = newValue {
                let v = loadIconView()
                v.image = i
                v.tintColor = tintColor
                if let _ = titleLabel {
                    self.rootViewController?.view.addSubview(v)
                } else {
                    v.removeFromSuperview()
                }
                updateContentFrame()
            }
        }
    }
    public var progress = CGFloat(0) {
        didSet {
            loadProgressLayer()
            if let _ = progressLayer {
                if var f = self.rootViewController?.view.bounds {
                    f.size.width = progress * f.size.width
                    self.progressLayer?.frame = f
                }
            }
        }
    }
    
    public var level = NoticeBoard.Level.normal {
        didSet {
            windowLevel = level.rawValue
        }
    }
    
    public var tags = [String]()
    
    // MARK: - internal property
    // life cycle
    
    /// 持续的时间，0表示无穷大
    internal var duration = TimeInterval(0)
    
    /// 过期自动消失的函数
    internal var workItem : DispatchWorkItem?
    
    // action
    internal var block_action: ((Notice, UIButton)->Void)?
    
    internal weak var board = NoticeBoard.shared
    
    internal var lastFrame = CGRect.zero
    
    internal var originY = margin {
        didSet {
            var f = self.frame
            f.origin.y = originY
            self.frame = f
        }
    }
    
    // MARK: - override property
    open override var frame: CGRect {
        didSet {
            updateSelfFrame()
            if let b = board {
                if b.layoutStyle == .tile {
                    if frame.size.height != lastFrame.size.height {
                        debugPrint("update frame")
                        lastFrame = frame
                        if let index = b.notices.index(of: self) {
                            b.updateLayout(from: index)
                        }
                    }
                }
            }
        }
    }
    open override func setNeedsLayout() {
        var f = self.frame
        f.size.width = min(UIScreen.main.bounds.size.width - 2 * margin, maxWidth)
        f.origin.x = (UIScreen.main.bounds.size.width - f.size.width) / 2
        self.frame = f
        
        if let t = actionButton {
            t.frame = frame(for: .actionButton)
        }
        if let t = bodyView {
            t.frame = frame(for: .bodyView)
        }
        if let t = dragButton {
            t.frame = frame(for: .dragButton)
        }
        updateContentFrame()
        
    }
    // MARK: - public func
    
    /// 警示（如果一个notice已经post出来了，想要再次引起用户注意，可以使用此函数）
    ///
    /// - Parameter options: 操作
    public func alert(options: NoticeAlertOptions = []){
        let ani = CABasicAnimation.init(keyPath: "backgroundColor")
        ani.autoreverses = true
        ani.isRemovedOnCompletion = true
        ani.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseInEaseOut)
        if options.contains(.fast) {
            ani.duration = 0.38
        } else if options.contains(.slowly) {
            ani.duration = 2.4
        } else {
            // normally
            ani.duration = 0.8
        }
        if options.contains(.breathing) {
            ani.repeatCount = MAXFLOAT
        } else if options.contains(.twice) {
            ani.repeatCount = 2
        } else {
            // once
            ani.repeatCount = 1
        }
        if options.contains(.flash) {
            ani.toValue = UIColor.init(white: 1, alpha: 0).cgColor
        } else if options.contains(.lighten) {
            ani.toValue = self.rootViewController?.view.backgroundColor?.lighten(0.4).cgColor
        } else {
            // darken
            ani.toValue = self.rootViewController?.view.backgroundColor?.darken(0.4).cgColor
        }
        self.rootViewController?.view.layer.add(ani, forKey: "backgroundColor")
        
    }
    
    /// "→"按钮的事件
    ///
    /// - Parameter action: "→"按钮的事件
    open func actionButtonDidTapped(action: @escaping(Notice, UIButton) -> Void){
        self.rootViewController?.view.addSubview(loadActionButton())
        updateContentFrame()
        block_action = action
    }
    open func removeFromNoticeBoard(){
        if let b = board {
            b.remove(self, animate: .slide)
        }
    }
    // MARK: - private func
    
    
    // MARK: - life cycle
    public convenience init(title: String?, icon: UIImage?, body: String?) {
        self.init()
        
        func text(_ text: String?) -> String? {
            if let t = text {
                if t.count > 0 {
                    return t
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        
        if let text = text(title) {
            self.title = text
        }
        if let image = icon {
            self.icon = image
        }
        if let text = text(body) {
            self.body = text
        }
        
    }

    
    public override init(frame: CGRect) {
        
        super.init(frame: frame)
        windowLevel = level.rawValue
        
        layer.shadowRadius = 12
        layer.shadowOffset = .init(width: 0, height: 8)
        layer.shadowOpacity = 0.35
        
        let vc = UIViewController()
        self.rootViewController = vc
        vc.view.frame = self.bounds
        vc.view.layer.cornerRadius = cornerRadius
        vc.view.clipsToBounds = true
        
        loadActionButton()
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(self.pan(_:)))
        self.addGestureRecognizer(pan)
        
    }
    convenience init() {
        let width = min(UIScreen.main.bounds.size.width - 2 * margin, maxWidth)
        let marginX = (UIScreen.main.bounds.size.width - width) / 2
        let preferredFrame = CGRect.init(x: marginX, y: margin, width: width, height: titleHeight)
        self.init(frame: preferredFrame)
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    open override var tintColor: UIColor!{
        didSet {
            iconView?.tintColor = tintColor
            titleLabel?.textColor = tintColor
            bodyView?.textColor = tintColor
            actionButton?.setTitleColor(tintColor, for: .normal)
            dragButton?.setTitleColor(tintColor, for: .normal)
        }
    }
    deinit {
        debugPrint("👌🏼deinit")
    }
    
    // MARK: - action
    @objc private func touchDown(_ sender: UIButton) {
        debugPrint("touchDown: " + (sender.titleLabel?.text)!)
        if sender.tag == Tag.dragButton.rawValue {
            sender.backgroundColor = UIColor.init(white: 0, alpha: 0.3)
        } else if sender.tag == Tag.actionButton.rawValue {
            
        }
    }
    @objc private func touchUp(_ sender: UIButton) {
        debugPrint("touchUp: " + (sender.titleLabel?.text)!)
        if sender.tag == Tag.dragButton.rawValue {
            sender.backgroundColor = UIColor.init(white: 0, alpha: 0.1)
        } else if sender.tag == Tag.actionButton.rawValue {
            
        }
    }
    @objc private func touchUpInside(_ sender: UIButton) {
        touchUp(sender)
        debugPrint("touchUpInside: " + (sender.titleLabel?.text)!)
        if sender == actionButton {
            if let action = block_action {
                action(self, sender)
            }
        }
        
    }
    @objc private func pan(_ sender: UIPanGestureRecognizer) {
        DispatchWorkItem.cancel(self.workItem)
        let point = sender.translation(in: sender.view)
        var f = self.frame
        f.origin.y += point.y
        self.frame = f
        sender.setTranslation(.zero, in: sender.view)
        if sender.state == .recognized {
            let v = sender.velocity(in: sender.view)
            if allowRemoveByGesture == true && ((frame.origin.y + point.y < 0 && v.y < 0) || v.y < -1200) {
                if let b = self.board {
                    b.remove(self, animate: .slide)
                }
            } else {
                if let btn = self.dragButton {
                    self.touchUp(btn)
                }
                UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.7, options: [.allowUserInteraction, .curveEaseOut], animations: {
                    var f = self.frame
                    f.origin.y = self.originY
                    self.frame = f
                }) { (completed) in
                    if self.duration > 0 {
                        if let b = self.board {
                            b.post(self, duration: self.duration)
                        }
                    }
                    
                }
            }
        }
        
    }
    
    internal func translate(_ animateStyle: NoticeBoard.AnimationStyle, _ buildInOut: NoticeBoard.BuildInOut){
        switch animateStyle {
        case .slide:
            move(buildInOut)
        case .fade:
            fade(buildInOut)
        }
    }
    
    internal func move(_ animate: NoticeBoard.BuildInOut){
        switch animate {
        case .buildIn:
            transform = .identity
        case .buildOut:
            if transform == .identity {
                let offset = frame.size.height + frame.origin.y + layer.shadowRadius + layer.shadowOffset.height
                transform = .init(translationX: 0, y: -offset)
            }
        }
    }
    
    internal func fade(_ animate: NoticeBoard.BuildInOut){
        switch animate {
        case .buildIn:
            self.alpha = 1
        case .buildOut:
            self.alpha = 0
        }
    }
}


// MARK: - setup
private extension Notice {
    
    @discardableResult
    func loadTextView() -> UITextView {
        if let view = bodyView {
            return view
        } else {
            bodyView = UITextView.init(frame: frame(for: .bodyView))
            bodyView?.tag = Tag.bodyView.rawValue
            bodyView?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            bodyView?.showsHorizontalScrollIndicator = false
            bodyView?.textAlignment = .justified
            bodyView?.isEditable = false
            bodyView?.isSelectable = false
            bodyView?.backgroundColor = .clear
            bodyView?.textContainerInset = defaultInset
            return bodyView!
        }
    }
    
    @discardableResult
    func loadIconView() -> UIImageView {
        if let view = iconView {
            return view
        } else {
            iconView = UIImageView.init(frame: .init(x: padding10, y: 2*padding4, width: titleHeight-4*padding4, height: titleHeight-4*padding4))
            iconView?.tag = Tag.iconView.rawValue
            iconView?.contentMode = .scaleAspectFit
            if debugMode {
                iconView?.backgroundColor = UIColor.init(white: 0, alpha: 0.3)
            }
            return iconView!
        }
    }
    
    
    @discardableResult
    func loadActionButton() -> UIButton {
        if let btn = actionButton {
            return btn
        } else {
            actionButton = UIButton.init(frame: frame(for: .actionButton))
            actionButton?.tag = Tag.actionButton.rawValue
            actionButton?.setTitleColor(.black, for: .normal)
            actionButton?.setTitle("→", for: .normal)
            actionButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
            actionButton?.addTarget(self, action: #selector(self.touchUpInside(_:)), for: .touchUpInside)
            actionButton?.addTarget(self, action: #selector(self.touchDown(_:)), for: [.touchDown,])
            actionButton?.addTarget(self, action: #selector(self.touchUp(_:)), for: [.touchUpInside,.touchUpOutside])
            return actionButton!
        }
    }
    
    
    @discardableResult
    func loadTitleLabel() -> UILabel {
        if let lb = titleLabel {
            return lb
        } else {
            titleLabel = UILabel.init(frame: .init(x: padding10, y: 0, width: self.frame.size.width-2*padding10, height: titleHeight))
            titleLabel?.tag = Tag.titleView.rawValue
            titleLabel?.textAlignment = .justified
            titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize-1)
            if debugMode {
                titleLabel?.backgroundColor = UIColor.init(white: 0, alpha: 0.2)
                actionButton?.backgroundColor = UIColor.init(white: 1, alpha: 0.2)
            }
            return titleLabel!
        }
    }
    
    @discardableResult
    func loadProgressLayer() -> CALayer {
        if let l = progressLayer {
            return l
        } else {
            progressLayer = CALayer.init()
            if var f = self.rootViewController?.view.bounds {
                f.size.width = 0
                f.size.height = titleHeight + max(bodyMaxHeight, 0)
                progressLayer?.frame = f
            }
            progressLayer?.backgroundColor = UIColor.init(white: 0, alpha: 0.2).cgColor
            if let blur = visualEffectView {
                blur.layer.insertSublayer(progressLayer!, above: blur.layer)
            } else {
                self.rootViewController?.view.layer.insertSublayer(progressLayer!, at: 0)
            }
            return progressLayer!
        }
    }
    
    @discardableResult
    func loadDragButton() -> UIButton {
        if let btn = dragButton {
            return btn
        } else {
            dragButton = UIButton.init(frame: frame(for: .dragButton))
            dragButton?.tag = Tag.dragButton.rawValue
            dragButton?.backgroundColor = UIColor.init(white: 0, alpha: 0.1)
            dragButton?.setTitle("——", for: .normal)
            dragButton?.setTitleColor(tintColor, for: .normal)
            dragButton?.addTarget(self, action: #selector(self.touchDown(_:)), for: [.touchDown,])
            dragButton?.addTarget(self, action: #selector(self.touchUp(_:)), for: [.touchUpInside,.touchUpOutside])
            return dragButton!
        }
    }
    
    
}


