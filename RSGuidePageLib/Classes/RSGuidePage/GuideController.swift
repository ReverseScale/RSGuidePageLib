//
//  GuideController.swift
//  RSGuideDemo
//
//  Created by WhatsXie on 2017/9/21.
//  Copyright © 2017年 StevenXie. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MediaPlayer

public enum GuideType {
    case video // 视频类型
    case picture // 图片类型
}

public class GuideController: UIViewController {
    
    fileprivate var type:GuideType?
    /// 视频地址
    fileprivate var videoPath:String?
    /// 图片数组
    fileprivate var pictures:[String]?
    fileprivate var playerLayer:AVPlayerLayer?
    fileprivate var player:AVPlayer?
    fileprivate var playeItem:AVPlayerItem?
    fileprivate var scrollView:UIScrollView?
    
    fileprivate var enterBtn:UIButton?
    fileprivate var pageCtr:UIPageControl?
    fileprivate var pushViewController:UIViewController?
    // 滑入动画
    fileprivate var presentAnimator:PresentAnimator?
    
    
    /// 初始化该引导页视图
    ///
    /// - Parameters:
    ///   - guide: 是视频还是图片
    ///   - pictures: 如果是图片，这里传入图片数组，如果是视频，这里传入nil
    ///   - videoPath: 如果是视频，这里传入视频地址，如果是图片，这里传入nil
    ///   - pushViewController: 点击进入按钮展示的页面
    public func createGuidePage(guide:GuideType, pictures:[String]?,videoPath:String?,pushViewController:UIViewController?) {
        type = guide
        self.pushViewController = pushViewController
        if pictures != nil {
            self.pictures = pictures
        }
        if videoPath != nil {
            self.videoPath = videoPath
        }
        pushViewController?.transitioningDelegate = self
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = true
        view.backgroundColor = UIColor.white
        switch self.type! {
        case .video:
            videoSetUI()
            break
        case .picture:
            pictureSetUI()
            break
        }
    }
}

extension GuideController{
    
    func setScrollViewUIViewStyle() {
        scrollView = UIScrollView.init(frame: view.bounds)
        scrollView?.contentSize = CGSize.init(width: view.frame.size.width * CGFloat(self.pictures!.count), height: view.bounds.height)
        scrollView?.isUserInteractionEnabled = true
        // scrollView?.bounces = false
        scrollView?.delegate = self
        scrollView?.showsHorizontalScrollIndicator = false
        scrollView?.showsVerticalScrollIndicator = false
        scrollView?.isPagingEnabled = true
    }
    
    /// 设置是图片的UI界面
    func pictureSetUI(){
        setScrollViewUIViewStyle()
        for (index,value) in self.pictures!.enumerated() {
            let imageView:UIImageView = UIImageView.init(frame: CGRect.init(x: CGFloat(index) * view.frame.size.width, y: 0, width: view.frame.size.width, height: view.frame.size.height))
            imageView.isUserInteractionEnabled = true
            if index == self.pictures!.count-1 {
                //左划
                let swipeLeftGesture = UISwipeGestureRecognizer.init(target: self, action: #selector(leftGesAction))
                swipeLeftGesture.direction = .left
                imageView.addGestureRecognizer(swipeLeftGesture)
            }
            imageView.image = UIImage.init(named: value)
            scrollView?.addSubview(imageView)
        }
        view.addSubview(scrollView!)
        view.addSubview(setupPageController())
        createEnterBtn()
    }
    
    func setupPageController() -> UIPageControl{
        pageCtr = UIPageControl.init(frame: CGRect.init(x: (view.frame.size.width - 100)/2, y: view.frame.size.height - 20 - 20 , width: 100, height: 20))
        pageCtr!.currentPage = 0
        pageCtr!.numberOfPages = pictures!.count
        //设置选中的颜色
        pageCtr!.currentPageIndicatorTintColor = UIColor.red
        //设置没有选中的颜色
        pageCtr!.pageIndicatorTintColor = UIColor.brown
        
        return pageCtr!
    }
    
    /// 设置是视屏的UI界面
    func videoSetUI(){
        let videoUrl:URL = URL.init(fileURLWithPath: videoPath!)
        playeItem = AVPlayerItem.init(url: videoUrl)
        player = AVPlayer.init(playerItem: playeItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer!.frame = view.bounds
        view.layer.addSublayer(playerLayer!)
        player!.play()
        //监听播放结束
        NotificationCenter.default.addObserver(self, selector: #selector(playItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playeItem)
        createEnterBtn()
        UIView.animate(withDuration: 1.0) {
            self.enterBtn?.alpha = 1
        }
    }
    
    func createEnterBtn(){
        enterBtn = UIButton.init(type: UIButtonType.custom)
        enterBtn?.setTitle("点击进入", for: .normal)
        enterBtn?.setTitleColor(UIColor.lightGray, for: .normal)
        enterBtn?.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        enterBtn?.frame = CGRect.init(x: (view.frame.size.width-100)/2, y: view.frame.size.height - 49 - 30, width: 100, height: 30)
        enterBtn?.alpha = 0
        enterBtn?.addTarget(self, action: #selector(enterBtnAciton), for: .touchUpInside)
        view.addSubview(self.enterBtn!)
        enterBtn?.layer.cornerRadius = 15
        enterBtn?.layer.borderWidth = 0.8
        enterBtn?.layer.borderColor = UIColor.red.cgColor
    }
    
    @objc func playItemDidReachEnd(){
        print("视频播放结束了")
        //进行循环播放
        player?.seek(to: CMTime.init(value: 0, timescale: 1))
        player?.play()
    }
    
    @objc func leftGesAction(){
        print("最后张左划了")
        enterBtnAciton()
    }
    
    /// enterBtn的事件
    @objc func enterBtnAciton(){
        print("点击enter")
        presentAnimator = PresentAnimator()
        presentAnimator!.originFrame = view.frame
        presentAnimator!.originVc = self
        if self.type == GuideType.picture {
            present(self.pushViewController!, animated: true, completion: nil)
        } else {
            present(self.pushViewController!, animated: true, completion: {
                //清理播放的内存资源
                self.playerLayer?.removeFromSuperlayer()
                self.playerLayer=nil;
                self.player=nil;
            })
        }
    }
}

extension GuideController:UIScrollViewDelegate{
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.pageCtr?.currentPage = Int(scrollView.contentOffset.x/view.frame.size.width)
        if scrollView.contentOffset.x == CGFloat(self.pictures!.count-1)*view.frame.size.width {
            UIView.animate(withDuration: 0.5, animations: {
                self.enterBtn?.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.5, animations: {
                self.enterBtn?.alpha = 0
            })
            if scrollView.contentOffset.x > CGFloat(self.pictures!.count-1)*view.frame.size.width+20 {
                enterBtnAciton()
            }
        }
    }
}

extension GuideController:UIViewControllerTransitioningDelegate{
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentAnimator
    }
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}

