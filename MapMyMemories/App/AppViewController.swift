//
//  AppViewController.swift
//  MapMyMemories
//
//  Created by 문정호 on 2023/09/30.
//

import UIKit

class AppViewController: UITabBarController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewController()
    }
    
    func configureViewController(){
        let homeVC = UINavigationController(rootViewController: HomeViewController())
        homeVC.tabBarItem.title = "홈"
        homeVC.tabBarItem.image = UIImage(systemName: "house.fill")
        
        let writeVC = UINavigationController(rootViewController: WriteViewController())
        writeVC.tabBarItem.title = "기록"
        writeVC.tabBarItem.image = UIImage(systemName: "pencil.line")
        
        setViewControllers([writeVC], animated: true)
    }
    
}
